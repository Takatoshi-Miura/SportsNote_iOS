//
//  UserDefaultsManagerTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2026/07/26.
//

import Foundation
import Testing

@testable import SportsNote_iOS

@Suite("UserDefaultsManager Tests", .serialized)
struct UserDefaultsManagerTests {

    init() {
        // 前のテストの残留状態（cachedUserID含む）を必ずリセットする
        UserDefaultsManager.clearAll()
    }

    // MARK: - 基本的なset/get（型ごと）

    @Test("set/get - String型を保存・取得できる")
    func setGet_string() {
        UserDefaultsManager.set(key: UserDefaultsManager.Keys.address, value: "test@example.com")
        let value = UserDefaultsManager.get(key: UserDefaultsManager.Keys.address, defaultValue: "")
        #expect(value == "test@example.com")

        UserDefaultsManager.clearAll()
    }

    @Test("set/get - Int型を保存・取得できる")
    func setGet_int() {
        let key = "testIntKey"
        UserDefaultsManager.set(key: key, value: 42)
        let value = UserDefaultsManager.get(key: key, defaultValue: 0)
        #expect(value == 42)

        UserDefaultsManager.clearAll()
    }

    @Test("set/get - Bool型を保存・取得できる")
    func setGet_bool() {
        UserDefaultsManager.set(key: UserDefaultsManager.Keys.isLogin, value: true)
        let value = UserDefaultsManager.get(key: UserDefaultsManager.Keys.isLogin, defaultValue: false)
        #expect(value == true)

        UserDefaultsManager.clearAll()
    }

    @Test("set/get - Double型を保存・取得できる")
    func setGet_double() {
        let key = "testDoubleKey"
        UserDefaultsManager.set(key: key, value: 3.14)
        let value = UserDefaultsManager.get(key: key, defaultValue: 0.0)
        #expect(value == 3.14)

        UserDefaultsManager.clearAll()
    }

    @Test("get - 未保存キーはdefaultValueを返す")
    func get_returnsDefaultValueWhenKeyNotSaved() {
        let value = UserDefaultsManager.get(key: UserDefaultsManager.Keys.firstLaunch, defaultValue: true)
        #expect(value == true)

        UserDefaultsManager.clearAll()
    }

    @Test("set - 同一キーへの再設定で値が上書きされる")
    func set_overwritesExistingValue() {
        let key = "testOverwriteKey"
        UserDefaultsManager.set(key: key, value: "first")
        UserDefaultsManager.set(key: key, value: "second")
        let value = UserDefaultsManager.get(key: key, defaultValue: "")
        #expect(value == "second")

        UserDefaultsManager.clearAll()
    }

    // MARK: - Keys.userIDの特殊処理

    @Test("userID - 未保存時は自動生成されたUUIDが返り、UserDefaultsにも保存される")
    func userID_autoGeneratesUUIDWhenNotSaved() {
        let id = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        #expect(UUIDGenerator.isValidUUID(id))

        // set が実際に永続化されていることの検証（UserDefaults側を直接確認）
        let savedValue = UserDefaults.standard.string(forKey: UserDefaultsManager.Keys.userID)
        #expect(savedValue == id)

        UserDefaultsManager.clearAll()
    }

    @Test("userID - 保存済みの場合はその値がそのまま返る")
    func userID_returnsExistingValueWhenAlreadySaved() {
        // キャッシュを経由せず、UserDefaultsに直接値を仕込む
        UserDefaults.standard.set("existing-id", forKey: UserDefaultsManager.Keys.userID)

        let value = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        #expect(value == "existing-id")

        UserDefaultsManager.clearAll()
    }

    @Test("userID - cachedUserIDが優先される（UserDefaultsの値と異なっていても優先）")
    func userID_prefersCachedValueOverUserDefaults() {
        UserDefaultsManager.set(key: UserDefaultsManager.Keys.userID, value: "cached-id")
        // UserDefaults側だけを直接書き換える（cachedUserIDは変わらない）
        UserDefaults.standard.set("direct-id", forKey: UserDefaultsManager.Keys.userID)

        let value = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        #expect(value == "cached-id")

        UserDefaultsManager.clearAll()
    }

    @Test("userID - 2回連続でgetしても同じ値が返る（都度UUIDが再生成されない）")
    func userID_returnsSameValueOnConsecutiveGets() {
        let first = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        let second = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        #expect(first == second)

        UserDefaultsManager.clearAll()
    }

    @Test("userID - Optional型(String?)呼び出し時もcachedUserIDがnilなら新規UUIDが返る（#37回帰防止）")
    func userID_optionalCall_returnsGeneratedUUIDWhenCacheIsNil() {
        // cachedUserIDはinit()のclearAll()でnilになっている（コールドスタート相当）
        let value = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: nil) as String?
        #expect(value != nil)
        #expect(UUIDGenerator.isValidUUID(value ?? ""))

        UserDefaultsManager.clearAll()
    }

    @Test("userID - Optional型(String?)呼び出し時、永続化済みIDがcachedUserID未設定でも返る（#37回帰防止）")
    func userID_optionalCall_returnsPersistedValueWhenCacheIsNil() {
        // キャッシュを経由せず、UserDefaultsに直接値を仕込む（コールドスタート相当）
        UserDefaults.standard.set("persisted-id", forKey: UserDefaultsManager.Keys.userID)

        let value = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: nil) as String?
        #expect(value == "persisted-id")

        UserDefaultsManager.clearAll()
    }

    @Test("userID - Optional型(String?)呼び出しと非Optional呼び出しで同一の永続化済みIDが返る")
    func userID_optionalAndNonOptionalCallsReturnSameValue() {
        UserDefaults.standard.set("shared-id", forKey: UserDefaultsManager.Keys.userID)

        let optionalValue = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: nil) as String?
        UserDefaultsManager.clearAll()
        UserDefaults.standard.set("shared-id", forKey: UserDefaultsManager.Keys.userID)
        let nonOptionalValue = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")

        #expect(optionalValue == "shared-id")
        #expect(nonOptionalValue == "shared-id")
        #expect(optionalValue == nonOptionalValue)

        UserDefaultsManager.clearAll()
    }

    // MARK: - remove

    @Test("remove - 指定キーの値が削除されデフォルト値に戻る")
    func remove_deletesValueAndReturnsToDefault() {
        UserDefaultsManager.set(key: UserDefaultsManager.Keys.firstLaunch, value: false)
        UserDefaultsManager.remove(key: UserDefaultsManager.Keys.firstLaunch)

        let value = UserDefaultsManager.get(key: UserDefaultsManager.Keys.firstLaunch, defaultValue: true)
        #expect(value == true)

        UserDefaultsManager.clearAll()
    }

    @Test("remove - userIDキー削除後はcachedUserIDもクリアされ、次回getで新しいUUIDが生成される")
    func remove_userIDClearsCacheAndRegeneratesOnNextGet() {
        let originalID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        UserDefaultsManager.remove(key: UserDefaultsManager.Keys.userID)

        let newID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        #expect(newID != originalID)
        #expect(UUIDGenerator.isValidUUID(newID))

        UserDefaultsManager.clearAll()
    }

    // MARK: - clearAll

    @Test("clearAll - 複数キーをすべて削除する")
    func clearAll_deletesAllKeys() {
        UserDefaultsManager.set(key: UserDefaultsManager.Keys.firstLaunch, value: false)
        UserDefaultsManager.set(key: UserDefaultsManager.Keys.address, value: "test@example.com")
        UserDefaultsManager.set(key: UserDefaultsManager.Keys.password, value: "password123")
        UserDefaultsManager.set(key: UserDefaultsManager.Keys.isLogin, value: true)

        UserDefaultsManager.clearAll()

        #expect(UserDefaults.standard.object(forKey: UserDefaultsManager.Keys.firstLaunch) == nil)
        #expect(UserDefaults.standard.object(forKey: UserDefaultsManager.Keys.address) == nil)
        #expect(UserDefaults.standard.object(forKey: UserDefaultsManager.Keys.password) == nil)
        #expect(UserDefaults.standard.object(forKey: UserDefaultsManager.Keys.isLogin) == nil)
    }

    @Test("clearAll - userIDのcachedUserIDもクリアされる")
    func clearAll_clearsCachedUserID() {
        let originalID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        UserDefaultsManager.clearAll()

        let newID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        #expect(newID != originalID)

        UserDefaultsManager.clearAll()
    }

    // MARK: - resetUserInfo

    @Test("resetUserInfo - 指定したuserIDが保存される")
    func resetUserInfo_savesSpecifiedUserID() {
        UserDefaultsManager.resetUserInfo(userID: "specified-id")

        let value = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        #expect(value == "specified-id")

        UserDefaultsManager.clearAll()
    }

    @Test("resetUserInfo - 引数省略時は自動生成されたUUIDが保存される")
    func resetUserInfo_generatesUUIDWhenArgumentOmitted() {
        UserDefaultsManager.resetUserInfo()

        let value = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        #expect(UUIDGenerator.isValidUUID(value))

        UserDefaultsManager.clearAll()
    }
}
