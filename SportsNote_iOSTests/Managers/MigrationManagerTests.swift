//
//  MigrationManagerTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2026/08/04.
//

import Foundation
import RealmSwift
import Testing

@testable import SportsNote_iOS

/// `MigrationManager`はFirebaseFirestoreに直接依存し、Firebase未設定のテスト環境では
/// インスタンス化するとクラッシュするため、`MigrationManager.shared`や`MigrationManager()`には
/// 一切触れず、Firebaseに依存しない`resolveUncategorizedGroupID(userID:)`（static func）のみを
/// 検証する（issue #35のMigrationStepRunnerと同じ回避パターン、issue #73・#56）。
@Suite("MigrationManager resolveUncategorizedGroupID Tests", .serialized)
@MainActor
struct MigrationManagerTests {

    init() async throws {
        RealmManager.shared.setupInMemoryRealm()
        RealmManager.shared.clearAll()
    }

    private func makeGroup(title: String, order: Int) -> Group {
        Group(
            groupID: UUIDGenerator.generateID(),
            title: title,
            color: GroupColor.red.rawValue,
            order: order,
            created_at: Date()
        )
    }

    @Test("Groupが0件の場合、未分類グループを新規作成してそのIDを返す")
    func resolveUncategorizedGroupID_noGroups_createsUncategorizedGroup() throws {
        let groupID = try MigrationManager.resolveUncategorizedGroupID(userID: "user-1")

        #expect(!groupID.isEmpty)

        let groups = try RealmManager.shared.getDataList(clazz: Group.self)
        #expect(groups.count == 1)
        #expect(groups.first?.groupID == groupID)
        #expect(groups.first?.title == LocalizedStrings.uncategorized)
        #expect(groups.first?.color == GroupColor.gray.rawValue)
        #expect(groups.first?.userID == "user-1")
    }

    @Test(
        "並び替え後に未分類グループがorder最小でなくなっていても、タイトル一致で正しく未分類グループを判定できる（issue #56の再現手順そのもの）"
    )
    func resolveUncategorizedGroupID_uncategorizedNotFirstByOrder_returnsUncategorizedGroupID() throws {
        // 「Aチーム」がorder 0（先頭）、「未分類」がorder 1（並び替え後の状態）
        let teamA = makeGroup(title: "Aチーム", order: 0)
        let uncategorized = makeGroup(title: LocalizedStrings.uncategorized, order: 1)
        try RealmManager.shared.saveItem(teamA)
        try RealmManager.shared.saveItem(uncategorized)

        // groups.firstロジック（旧バグ）ならteamAのgroupIDを返してしまい、このテストは失敗する
        let result = try MigrationManager.resolveUncategorizedGroupID(userID: "user-1")

        #expect(result == uncategorized.groupID)

        // 新規作成されていないこと（既存2件のまま）
        let groups = try RealmManager.shared.getDataList(clazz: Group.self)
        #expect(groups.count == 2)
    }

    @Test("未分類グループが先頭にある通常状態でも、タイトル一致で正しく判定できる（回帰確認）")
    func resolveUncategorizedGroupID_uncategorizedFirst_returnsUncategorizedGroupID() throws {
        let uncategorized = makeGroup(title: LocalizedStrings.uncategorized, order: 0)
        let teamA = makeGroup(title: "Aチーム", order: 1)
        try RealmManager.shared.saveItem(uncategorized)
        try RealmManager.shared.saveItem(teamA)

        let result = try MigrationManager.resolveUncategorizedGroupID(userID: "user-1")

        #expect(result == uncategorized.groupID)

        let groups = try RealmManager.shared.getDataList(clazz: Group.self)
        #expect(groups.count == 2)
    }

    @Test("未分類グループが存在しない場合（別タイトルのグループのみ）、誤って別グループを返さず新規に未分類グループを作成する")
    func resolveUncategorizedGroupID_noUncategorizedGroup_createsNewUncategorizedGroup() throws {
        // groups.firstロジック（旧バグ）ならteamAのgroupIDを返してしまう
        let teamA = makeGroup(title: "Aチーム", order: 0)
        let teamB = makeGroup(title: "Bチーム", order: 1)
        try RealmManager.shared.saveItem(teamA)
        try RealmManager.shared.saveItem(teamB)

        let result = try MigrationManager.resolveUncategorizedGroupID(userID: "user-1")

        let groups = try RealmManager.shared.getDataList(clazz: Group.self)
        #expect(groups.count == 3)
        #expect(
            groups.contains(where: { $0.groupID == result && $0.title == LocalizedStrings.uncategorized })
        )
    }

    @Test("未分類グループが既に存在する場合、新規作成せず既存の未分類グループのIDを返す")
    func resolveUncategorizedGroupID_uncategorizedGroupExists_reusesExistingGroup() throws {
        let existing = Group(
            groupID: "existing-group",
            title: LocalizedStrings.uncategorized,
            color: GroupColor.blue.rawValue,
            order: 0,
            created_at: Date()
        )
        try RealmManager.shared.saveItem(existing)

        let groupID = try MigrationManager.resolveUncategorizedGroupID(userID: "user-1")

        #expect(groupID == "existing-group")

        let groups = try RealmManager.shared.getDataList(clazz: Group.self)
        // 新規作成されていないこと
        #expect(groups.count == 1)
    }

    @Test(
        "Groupが0件の状態から複数タスクを移行しても、未分類グループは1件だけ作成され全タスクが同じグループIDを共有する"
    )
    func resolveUncategorizedGroupID_calledMultipleTimesFromZero_reusesCreatedGroup() throws {
        // migrateAll() が oldTaskDocs をループしながら本メソッドを都度呼び出す状況を再現
        // （ログイン直後・Group0件の状態でのマイグレーション実行という再現手順の核心部分）
        let firstGroupID = try MigrationManager.resolveUncategorizedGroupID(userID: "user-1")
        let secondGroupID = try MigrationManager.resolveUncategorizedGroupID(userID: "user-1")
        let thirdGroupID = try MigrationManager.resolveUncategorizedGroupID(userID: "user-1")

        #expect(!firstGroupID.isEmpty)
        #expect(firstGroupID == secondGroupID)
        #expect(secondGroupID == thirdGroupID)

        let groups = try RealmManager.shared.getDataList(clazz: Group.self)
        #expect(groups.count == 1)
    }
}
