//
//  GroupTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2026/07/29.
//

import Foundation
import Testing

@testable import SportsNote_iOS

// Group()のデフォルトinit()がUserDefaultsManager経由でuserIDを取得するようになった
// （issue #23）ため、UserDefaultsの共有可変状態(cachedUserID)に触れる他のスイートとの
// 並列実行によるフレーキー化・汚染を防ぐため直列実行にする
@Suite("Group Model Tests", .serialized)
struct GroupTests {

    // MARK: - groupColor テスト（issue #43: 範囲外colorでのクラッシュ防止）

    @Test(
        "groupColor - 正常範囲(0-7)では対応するGroupColorを返す",
        arguments: GroupColor.allCases)
    func groupColor_returnsCorrectColorForValidRange(color: GroupColor) {
        let group = Group(
            groupID: "g1", title: "Test", color: color.rawValue, order: 0, created_at: Date())

        #expect(group.groupColor == color)
    }

    @Test(
        "groupColor - 範囲外の値ではクラッシュせずgrayを返す",
        arguments: [-1, 8, 99, Int.max, Int.min])
    func groupColor_returnsGrayForOutOfRangeValue(invalidColor: Int) {
        let group = Group(
            groupID: "g1", title: "Test", color: invalidColor, order: 0, created_at: Date())

        #expect(group.groupColor == .gray)
    }

    // MARK: - userID テスト（issue #23: UserDefaultsManager経由でのuserID取得）

    @Test("init - userIDがUserDefaultsManager経由で設定される")
    func init_setsUserIDFromUserDefaultsManager() {
        let testUserID = "test-user-\(UUID().uuidString)"
        UserDefaultsManager.set(key: UserDefaultsManager.Keys.userID, value: testUserID)
        defer { UserDefaultsManager.remove(key: UserDefaultsManager.Keys.userID) }

        let group = Group()

        #expect(group.userID == testUserID)
    }
}
