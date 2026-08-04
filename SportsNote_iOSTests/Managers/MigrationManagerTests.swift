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
/// 検証する（issue #35のMigrationStepRunnerと同じ回避パターン、issue #73）。
@Suite("MigrationManager resolveUncategorizedGroupID Tests", .serialized)
@MainActor
struct MigrationManagerTests {

    init() async throws {
        RealmManager.shared.setupInMemoryRealm()
        RealmManager.shared.clearAll()
    }

    @Test("Groupが0件の場合、未分類グループを新規作成してそのIDを返す")
    func resolveUncategorizedGroupID_noGroups_createsUncategorizedGroup() async throws {
        let groupID = try MigrationManager.resolveUncategorizedGroupID(userID: "user-1")

        #expect(!groupID.isEmpty)

        let groups = try RealmManager.shared.getDataList(clazz: Group.self)
        #expect(groups.count == 1)
        #expect(groups.first?.groupID == groupID)
        #expect(groups.first?.title == LocalizedStrings.uncategorized)
        #expect(groups.first?.color == GroupColor.gray.rawValue)
        #expect(groups.first?.userID == "user-1")
    }

    @Test("Groupが既に存在する場合、新規作成せず既存グループの先頭のIDを返す")
    func resolveUncategorizedGroupID_groupsExist_reusesExistingGroup() async throws {
        let existing = Group(
            groupID: "existing-group",
            title: "既存",
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
    func resolveUncategorizedGroupID_calledMultipleTimesFromZero_reusesCreatedGroup() async throws {
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
