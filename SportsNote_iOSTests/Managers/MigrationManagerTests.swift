//
//  MigrationManagerTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2026/08/05.
//

import Foundation
import Testing

@testable import SportsNote_iOS

/// `MigrationManager`はFirebaseFirestoreに直接依存し、Firebase未設定のテスト環境では
/// インスタンス化するとクラッシュするため、`MigrationManager.shared`には一切触れず
/// `resolveUncategorizedGroupID(groups:)`という外部依存を持たない静的な純粋関数のみを検証する
/// （issue #35で確立、issue #73・#56で踏襲されている制約回避パターン）。
@Suite("MigrationManager Tests")
@MainActor
struct MigrationManagerTests {

    private func makeGroup(title: String, order: Int) -> Group {
        Group(
            groupID: UUIDGenerator.generateID(),
            title: title,
            color: GroupColor.red.rawValue,
            order: order,
            created_at: Date()
        )
    }

    @Test("並び替え後に未分類グループがorder最小でなくなっていても、タイトル一致で正しく未分類グループを判定できる（issue #56の再現手順そのもの）")
    func resolveUncategorizedGroupID_uncategorizedNotFirstByOrder_returnsUncategorizedGroupID() {
        // 「Aチーム」がorder 0（先頭）、「未分類」がorder 1（並び替え後の状態）
        let teamA = makeGroup(title: "Aチーム", order: 0)
        let uncategorized = makeGroup(title: LocalizedStrings.uncategorized, order: 1)

        // groups.firstロジック（旧バグ）ならteamAのgroupIDを返してしまい、このテストは失敗する
        let result = MigrationManager.resolveUncategorizedGroupID(groups: [teamA, uncategorized])

        #expect(result == uncategorized.groupID)
    }

    @Test("未分類グループが先頭にある通常状態でも、タイトル一致で正しく判定できる（回帰確認）")
    func resolveUncategorizedGroupID_uncategorizedFirst_returnsUncategorizedGroupID() {
        let uncategorized = makeGroup(title: LocalizedStrings.uncategorized, order: 0)
        let teamA = makeGroup(title: "Aチーム", order: 1)

        let result = MigrationManager.resolveUncategorizedGroupID(groups: [uncategorized, teamA])

        #expect(result == uncategorized.groupID)
    }

    @Test("グループが1件も存在しない場合、空文字列を返す（フォールバック確認）")
    func resolveUncategorizedGroupID_noGroups_returnsEmptyString() {
        let result = MigrationManager.resolveUncategorizedGroupID(groups: [])

        #expect(result == "")
    }

    @Test("未分類グループが存在しない場合（別タイトルのグループのみ）、誤って別グループのIDを返さず空文字列を返す")
    func resolveUncategorizedGroupID_noUncategorizedGroup_returnsEmptyString() {
        // groups.firstロジック（旧バグ）ならteamAのgroupIDを返してしまい、このテストは失敗する
        let teamA = makeGroup(title: "Aチーム", order: 0)
        let teamB = makeGroup(title: "Bチーム", order: 1)

        let result = MigrationManager.resolveUncategorizedGroupID(groups: [teamA, teamB])

        #expect(result == "")
    }
}
