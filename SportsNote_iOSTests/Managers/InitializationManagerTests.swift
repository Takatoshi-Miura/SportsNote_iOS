//
//  InitializationManagerTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2026/07/26.
//

import Foundation
import Testing

@testable import SportsNote_iOS

@Suite("InitializationManager Tests", .serialized)
@MainActor
struct InitializationManagerTests {

    /// テスト対象に関わるUserDefaultsキー一覧（退避・復元対象）
    private static let relevantKeys: [String] = [
        UserDefaultsManager.Keys.firstLaunch,
        UserDefaultsManager.Keys.address,
        UserDefaultsManager.Keys.password,
        UserDefaultsManager.Keys.isLogin,
        UserDefaultsManager.Keys.userID,
    ]

    init() async throws {
        // initializeApp()はRealmManager.shared経由でフリーノート/未分類グループを作成するため、
        // 実DBを汚さないようインメモリRealmに切り替える（GroupViewModelTests等と同じパターン）
        RealmManager.shared.setupInMemoryRealm()
    }

    /// 指定キーの現在値を退避し、実行後に復元するヘルパー
    private func withPreservedUserDefaults<T>(_ body: () throws -> T) rethrows -> T {
        let snapshot = Self.relevantKeys.reduce(into: [String: Any]()) { result, key in
            if let value = UserDefaults.standard.object(forKey: key) {
                result[key] = value
            }
        }
        defer {
            for key in Self.relevantKeys {
                if let value = snapshot[key] {
                    UserDefaults.standard.set(value, forKey: key)
                } else {
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }
        }
        return try body()
    }

    // MARK: - migrateLoginStateIfNeeded単体テスト

    @Test(
        "migrateLoginStateIfNeeded - 旧アプリのaddress/passwordが存在する場合isLoginがtrueに補完される",
        arguments: [
            ("user@example.com", "password123"),
            ("a", "b"),
        ]
    )
    func migrateLoginStateIfNeeded_setsLoginTrueWhenLegacyCredentialsExist(
        address: String,
        password: String
    ) {
        withPreservedUserDefaults {
            // isFirstLaunch=true時にclearAll()が実行された直後の状態を再現（isLoginは未設定=false）
            UserDefaultsManager.set(key: UserDefaultsManager.Keys.isLogin, value: false)

            // clearAll()実行前に退避しておいた旧address/passwordを渡す（実装上の再現手順）
            InitializationManager.shared.migrateLoginStateIfNeeded(address: address, password: password)

            let isLogin = UserDefaultsManager.get(key: UserDefaultsManager.Keys.isLogin, defaultValue: false)
            #expect(isLogin == true)
        }
    }

    @Test(
        "migrateLoginStateIfNeeded - address/passwordのいずれかが存在しない場合isLoginは補完されない",
        arguments: [
            (nil as String?, "password123"),
            ("user@example.com", nil as String?),
            (nil as String?, nil as String?),
            ("", "password123"),
            ("user@example.com", ""),
        ]
    )
    func migrateLoginStateIfNeeded_doesNotSetLoginWhenCredentialsMissing(
        address: String?,
        password: String?
    ) {
        withPreservedUserDefaults {
            UserDefaultsManager.set(key: UserDefaultsManager.Keys.isLogin, value: false)

            InitializationManager.shared.migrateLoginStateIfNeeded(address: address, password: password)

            let isLogin = UserDefaultsManager.get(key: UserDefaultsManager.Keys.isLogin, defaultValue: false)
            #expect(isLogin == false)
        }
    }

    @Test("migrateLoginStateIfNeeded - 既にisLoginがtrueの場合は既存の状態を上書きしない")
    func migrateLoginStateIfNeeded_doesNotOverrideWhenAlreadyLoggedIn() {
        withPreservedUserDefaults {
            UserDefaultsManager.set(key: UserDefaultsManager.Keys.isLogin, value: true)

            InitializationManager.shared.migrateLoginStateIfNeeded(address: nil, password: nil)

            let isLogin = UserDefaultsManager.get(key: UserDefaultsManager.Keys.isLogin, defaultValue: false)
            #expect(isLogin == true)
        }
    }

    // MARK: - 再現手順の回帰確認（完了条件5: エンドツーエンド検証）
    // firstLaunch未設定（旧アプリからの更新直後）+ 旧address/passwordが設定済みの状態で
    // initializeApp()を実行し、clearAll()実行後もisLoginが正しく復元されることを検証する。

    @Test("initializeApp - firstLaunch未設定+旧address/password設定済みでisLoginがtrueに復元される（回帰テスト）")
    func initializeApp_restoresLoginStateOnFirstLaunchFromLegacyApp() async {
        await withPreservedUserDefaultsAsync {
            // 再現手順: firstLaunchキー未設定（旧アプリからの更新直後） + 旧address/password設定済み
            UserDefaults.standard.removeObject(forKey: UserDefaultsManager.Keys.firstLaunch)
            UserDefaults.standard.removeObject(forKey: UserDefaultsManager.Keys.isLogin)
            UserDefaults.standard.set("legacy-user@example.com", forKey: UserDefaultsManager.Keys.address)
            UserDefaults.standard.set("legacy-password", forKey: UserDefaultsManager.Keys.password)

            await InitializationManager.shared.initializeApp()

            // clearAll()実行後もaddress/passwordがinitializeApp()内で退避され、
            // isLoginの補完に使われることでtrueに復元されていることを確認する
            let isLogin = UserDefaultsManager.get(key: UserDefaultsManager.Keys.isLogin, defaultValue: false)
            #expect(isLogin == true)
        }
    }

    /// async版のUserDefaults退避・復元ヘルパー
    private func withPreservedUserDefaultsAsync(_ body: () async -> Void) async {
        let snapshot = Self.relevantKeys.reduce(into: [String: Any]()) { result, key in
            if let value = UserDefaults.standard.object(forKey: key) {
                result[key] = value
            }
        }
        await body()
        for key in Self.relevantKeys {
            if let value = snapshot[key] {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}
