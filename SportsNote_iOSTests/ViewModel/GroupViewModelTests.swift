//
//  GroupViewModelTests.swift
//  SportsNote_iOSTests
//
//  Created by Claude on 2025/11/21.
//

import Foundation
import Testing
import RealmSwift

@testable import SportsNote_iOS

@Suite("GroupViewModel Tests")
@MainActor
struct GroupViewModelTests {

    // MARK: - Test Lifecycle

    init() async throws {
        // テスト開始前にRealmをクリーンアップ
        await cleanupRealm()
        // UserDefaultsの初期化
        UserDefaults.standard.set("test-user-id", forKey: "userID")
        UserDefaults.standard.set(false, forKey: UserDefaultsManager.Keys.isLogin)
    }

    /// Realmのクリーンアップ
    private func cleanupRealm() async {
        do {
            let realm = try await Realm()
            try await realm.asyncWrite {
                realm.deleteAll()
            }
        } catch {
            print("Realm cleanup failed: \(error)")
        }
    }

    /// テスト用のGroupViewModelを作成
    private func createViewModel() -> GroupViewModel {
        return GroupViewModel()
    }

    /// テスト用のGroupを作成
    private func createTestGroup(
        groupID: String = UUIDGenerator.generateID(),
        title: String = "テストグループ",
        color: GroupColor = .red,
        order: Int = 0
    ) -> Group {
        return Group(
            groupID: groupID,
            title: title,
            color: color.rawValue,
            order: order,
            created_at: Date()
        )
    }

    // MARK: - 初期化テスト

    @Test("初期化 - ViewModelが正常に初期化される")
    func initialization_success() {
        let viewModel = createViewModel()

        #expect(viewModel.groups.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.currentError == nil)
        #expect(viewModel.showingErrorAlert == false)
    }

    // MARK: - fetchData() 正常系テスト

    @Test("fetchData - データが空の場合")
    func fetchData_emptyData() async {
        await cleanupRealm()
        let viewModel = createViewModel()

        let result = await viewModel.fetchData()

        #expect(viewModel.groups.isEmpty)
        #expect(viewModel.isLoading == false)
        if case .success = result {
            // 成功
        } else {
            Issue.record("Expected success result")
        }
    }

    @Test("fetchData - 単一グループを取得")
    func fetchData_singleGroup() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        // テストデータを追加
        let testGroup = createTestGroup(title: "グループ1")
        try RealmManager.shared.saveItem(testGroup)

        let result = await viewModel.fetchData()

        #expect(viewModel.groups.count == 1)
        #expect(viewModel.groups[0].title == "グループ1")
        #expect(viewModel.isLoading == false)
        if case .success = result {
            // 成功
        } else {
            Issue.record("Expected success result")
        }
    }

    @Test("fetchData - 複数グループを取得")
    func fetchData_multipleGroups() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        // 複数のテストデータを追加
        for i in 0..<5 {
            let group = createTestGroup(title: "グループ\(i)", order: i)
            try RealmManager.shared.saveItem(group)
        }

        let result = await viewModel.fetchData()

        #expect(viewModel.groups.count == 5)
        #expect(viewModel.isLoading == false)
        if case .success = result {
            // 成功
        } else {
            Issue.record("Expected success result")
        }
    }

    @Test("fetchData - 削除されたグループは取得しない")
    func fetchData_excludesDeletedGroups() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        // 通常のグループと削除済みグループを追加
        let normalGroup = createTestGroup(title: "通常グループ")
        try RealmManager.shared.saveItem(normalGroup)

        let deletedGroupId = UUIDGenerator.generateID()
        let deletedGroup = createTestGroup(groupID: deletedGroupId, title: "削除グループ")
        try RealmManager.shared.saveItem(deletedGroup)
        try RealmManager.shared.logicalDelete(id: deletedGroupId, type: Group.self)

        let result = await viewModel.fetchData()

        #expect(viewModel.groups.count == 1)
        #expect(viewModel.groups[0].title == "通常グループ")
        if case .success = result {
            // 成功
        } else {
            Issue.record("Expected success result")
        }
    }

    // MARK: - saveGroup() 正常系テスト

    @Test("saveGroup - 新規グループを保存")
    func saveGroup_newGroup() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        let result = await viewModel.saveGroup(
            title: "新しいグループ",
            color: .blue,
            order: 0
        )

        if case .success = result {
            #expect(viewModel.groups.count == 1)
            #expect(viewModel.groups[0].title == "新しいグループ")
            #expect(viewModel.groups[0].color == GroupColor.blue.rawValue)
        } else {
            Issue.record("Expected success result")
        }
    }

    @Test("saveGroup - グループを更新", arguments: [
        ("元のタイトル", "更新されたタイトル"),
        ("Group A", "Group B"),
        ("テスト", "テスト更新")
    ])
    func saveGroup_updateExisting(originalTitle: String, updatedTitle: String) async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        // 既存のグループを作成
        let groupID = UUIDGenerator.generateID()
        let result1 = await viewModel.saveGroup(
            groupID: groupID,
            title: originalTitle,
            color: .red,
            order: 0
        )

        if case .failure = result1 {
            Issue.record("Initial save failed")
            return
        }

        // グループを更新
        let result2 = await viewModel.saveGroup(
            groupID: groupID,
            title: updatedTitle,
            color: .green,
            order: 0
        )

        if case .success = result2 {
            await viewModel.fetchData()
            #expect(viewModel.groups.count == 1)
            #expect(viewModel.groups[0].title == updatedTitle)
            #expect(viewModel.groups[0].color == GroupColor.green.rawValue)
        } else {
            Issue.record("Expected success result for update")
        }
    }

    @Test("saveGroup - すべての色をテスト", arguments: GroupColor.allCases)
    func saveGroup_allColors(color: GroupColor) async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        let result = await viewModel.saveGroup(
            title: "カラーテスト",
            color: color,
            order: 0
        )

        if case .success = result {
            #expect(viewModel.groups.count == 1)
            #expect(viewModel.groups[0].color == color.rawValue)
        } else {
            Issue.record("Expected success result for color \(color)")
        }
    }

    @Test("saveGroup - デフォルトの並び順")
    func saveGroup_defaultOrder() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        // 既に2つのグループが存在する状態
        try RealmManager.shared.saveItem(createTestGroup(title: "グループ1", order: 0))
        try RealmManager.shared.saveItem(createTestGroup(title: "グループ2", order: 1))

        // orderを指定せずに保存
        let result = await viewModel.saveGroup(
            title: "グループ3",
            color: .red
        )

        if case .success = result {
            let savedGroup = viewModel.groups.first { $0.title == "グループ3" }
            #expect(savedGroup != nil)
            #expect(savedGroup?.order == 2) // 既存の2つ分のカウント
        } else {
            Issue.record("Expected success result")
        }
    }

    // MARK: - saveGroup() 境界値テスト

    @Test("saveGroup - 空のタイトル")
    func saveGroup_emptyTitle() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        let result = await viewModel.saveGroup(
            title: "",
            color: .gray,
            order: 0
        )

        if case .success = result {
            #expect(viewModel.groups.count == 1)
            #expect(viewModel.groups[0].title == "")
        } else {
            Issue.record("Expected success result")
        }
    }

    @Test("saveGroup - 非常に長いタイトル")
    func saveGroup_veryLongTitle() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        let longTitle = String(repeating: "あ", count: 1000)
        let result = await viewModel.saveGroup(
            title: longTitle,
            color: .purple,
            order: 0
        )

        if case .success = result {
            #expect(viewModel.groups.count == 1)
            #expect(viewModel.groups[0].title == longTitle)
        } else {
            Issue.record("Expected success result")
        }
    }

    @Test("saveGroup - 特殊文字を含むタイトル")
    func saveGroup_specialCharactersTitle() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        let specialTitle = "テスト!@#$%^&*()_+-=[]{}|;':\",./<>?~`"
        let result = await viewModel.saveGroup(
            title: specialTitle,
            color: .orange,
            order: 0
        )

        if case .success = result {
            #expect(viewModel.groups.count == 1)
            #expect(viewModel.groups[0].title == specialTitle)
        } else {
            Issue.record("Expected success result")
        }
    }

    @Test("saveGroup - 負の並び順")
    func saveGroup_negativeOrder() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        let result = await viewModel.saveGroup(
            title: "負の順序",
            color: .blue,
            order: -1
        )

        if case .success = result {
            #expect(viewModel.groups.count == 1)
            #expect(viewModel.groups[0].order == -1)
        } else {
            Issue.record("Expected success result")
        }
    }

    @Test("saveGroup - 非常に大きな並び順")
    func saveGroup_largeOrder() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        let result = await viewModel.saveGroup(
            title: "大きな順序",
            color: .green,
            order: Int.max
        )

        if case .success = result {
            #expect(viewModel.groups.count == 1)
            #expect(viewModel.groups[0].order == Int.max)
        } else {
            Issue.record("Expected success result")
        }
    }

    // MARK: - delete() 正常系テスト

    @Test("delete - 既存のグループを削除")
    func delete_existingGroup() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        // グループを作成
        let groupID = UUIDGenerator.generateID()
        try RealmManager.shared.saveItem(createTestGroup(groupID: groupID, title: "削除テスト"))
        await viewModel.fetchData()
        #expect(viewModel.groups.count == 1)

        // グループを削除
        let result = await viewModel.delete(id: groupID)

        if case .success = result {
            #expect(viewModel.groups.isEmpty)
        } else {
            Issue.record("Expected success result")
        }
    }

    @Test("delete - 複数グループから1つを削除")
    func delete_oneOfMultiple() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        // 複数のグループを作成
        let groupID1 = UUIDGenerator.generateID()
        let groupID2 = UUIDGenerator.generateID()
        try RealmManager.shared.saveItem(createTestGroup(groupID: groupID1, title: "グループ1"))
        try RealmManager.shared.saveItem(createTestGroup(groupID: groupID2, title: "グループ2"))

        await viewModel.fetchData()
        #expect(viewModel.groups.count == 2)

        // 1つ目を削除
        let result = await viewModel.delete(id: groupID1)

        if case .success = result {
            #expect(viewModel.groups.count == 1)
            #expect(viewModel.groups[0].groupID == groupID2)
            #expect(viewModel.groups[0].title == "グループ2")
        } else {
            Issue.record("Expected success result")
        }
    }

    // MARK: - delete() 異常系テスト

    @Test("delete - 存在しないIDで削除")
    func delete_nonExistentID() async {
        await cleanupRealm()
        let viewModel = createViewModel()

        let result = await viewModel.delete(id: "non-existent-id")

        if case .failure(let error) = result {
            // エラーが返されることを確認
            #expect(error != nil)
        } else {
            Issue.record("Expected failure result")
        }
    }

    @Test("delete - 空のIDで削除")
    func delete_emptyID() async {
        await cleanupRealm()
        let viewModel = createViewModel()

        let result = await viewModel.delete(id: "")

        if case .failure = result {
            // エラーが返されることを確認
        } else {
            Issue.record("Expected failure result for empty ID")
        }
    }

    @Test("delete - 既に削除済みのグループ")
    func delete_alreadyDeleted() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        // グループを作成して削除
        let groupID = UUIDGenerator.generateID()
        try RealmManager.shared.saveItem(createTestGroup(groupID: groupID, title: "削除テスト"))
        try RealmManager.shared.logicalDelete(id: groupID, type: Group.self)

        // 既に削除済みのグループを削除
        let result = await viewModel.delete(id: groupID)

        if case .failure = result {
            // エラーが返されることを確認
        } else {
            Issue.record("Expected failure result for already deleted group")
        }
    }

    // MARK: - fetchById() 正常系テスト

    @Test("fetchById - 既存のグループを取得")
    func fetchById_existingGroup() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        // グループを作成
        let groupID = UUIDGenerator.generateID()
        try RealmManager.shared.saveItem(createTestGroup(groupID: groupID, title: "検索テスト", color: .pink))

        let result = await viewModel.fetchById(id: groupID)

        if case .success(let group) = result {
            #expect(group != nil)
            #expect(group?.groupID == groupID)
            #expect(group?.title == "検索テスト")
            #expect(group?.color == GroupColor.pink.rawValue)
        } else {
            Issue.record("Expected success result")
        }
    }

    // MARK: - fetchById() 異常系テスト

    @Test("fetchById - 存在しないID")
    func fetchById_nonExistentID() async {
        await cleanupRealm()
        let viewModel = createViewModel()

        let result = await viewModel.fetchById(id: "non-existent-id")

        if case .success(let group) = result {
            #expect(group == nil)
        } else {
            Issue.record("Expected success result with nil group")
        }
    }

    @Test("fetchById - 空のID")
    func fetchById_emptyID() async {
        await cleanupRealm()
        let viewModel = createViewModel()

        let result = await viewModel.fetchById(id: "")

        if case .success(let group) = result {
            #expect(group == nil)
        } else {
            Issue.record("Expected success result with nil group")
        }
    }

    @Test("fetchById - 削除済みグループ")
    func fetchById_deletedGroup() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        // グループを作成して削除
        let groupID = UUIDGenerator.generateID()
        try RealmManager.shared.saveItem(createTestGroup(groupID: groupID, title: "削除済み"))
        try RealmManager.shared.logicalDelete(id: groupID, type: Group.self)

        let result = await viewModel.fetchById(id: groupID)

        if case .success(let group) = result {
            // 削除済みグループは取得できない
            #expect(group == nil)
        } else {
            Issue.record("Expected success result with nil group")
        }
    }

    // MARK: - canDelete 境界値テスト

    @Test("canDelete - グループが0個の場合")
    func canDelete_noGroups() async {
        await cleanupRealm()
        let viewModel = createViewModel()
        await viewModel.fetchData()

        #expect(viewModel.canDelete == false)
    }

    @Test("canDelete - グループが1個の場合")
    func canDelete_oneGroup() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        try RealmManager.shared.saveItem(createTestGroup(title: "グループ1"))
        await viewModel.fetchData()

        #expect(viewModel.canDelete == false)
    }

    @Test("canDelete - グループが2個の場合")
    func canDelete_twoGroups() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        try RealmManager.shared.saveItem(createTestGroup(title: "グループ1"))
        try RealmManager.shared.saveItem(createTestGroup(title: "グループ2"))
        await viewModel.fetchData()

        #expect(viewModel.canDelete == true)
    }

    @Test("canDelete - グループが多数の場合")
    func canDelete_manyGroups() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        for i in 0..<10 {
            try RealmManager.shared.saveItem(createTestGroup(title: "グループ\(i)"))
        }
        await viewModel.fetchData()

        #expect(viewModel.canDelete == true)
    }

    // MARK: - getGroupColor() 正常系テスト

    @Test("getGroupColor - 既存のグループの色を取得", arguments: GroupColor.allCases)
    func getGroupColor_existingGroup(color: GroupColor) async throws {
        await cleanupRealm()

        let groupID = UUIDGenerator.generateID()
        try RealmManager.shared.saveItem(createTestGroup(groupID: groupID, title: "カラーテスト", color: color))

        let result = GroupViewModel.getGroupColor(groupID: groupID)

        #expect(result == color)
    }

    @Test("getGroupColor - 存在しないグループ")
    func getGroupColor_nonExistentGroup() {
        let result = GroupViewModel.getGroupColor(groupID: "non-existent-id")

        #expect(result == GroupColor.gray)
    }

    @Test("getGroupColor - 空のID")
    func getGroupColor_emptyID() {
        let result = GroupViewModel.getGroupColor(groupID: "")

        #expect(result == GroupColor.gray)
    }

    // MARK: - getColorForGroupAtIndex() 正常系テスト

    @Test("getColorForGroupAtIndex - 有効なインデックス")
    func getColorForGroupAtIndex_validIndex() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        try RealmManager.shared.saveItem(createTestGroup(title: "グループ1", color: .red, order: 0))
        try RealmManager.shared.saveItem(createTestGroup(title: "グループ2", color: .blue, order: 1))
        try RealmManager.shared.saveItem(createTestGroup(title: "グループ3", color: .green, order: 2))
        await viewModel.fetchData()

        #expect(viewModel.groups.count == 3)

        let color0 = viewModel.getColorForGroupAtIndex(0)
        let color1 = viewModel.getColorForGroupAtIndex(1)
        let color2 = viewModel.getColorForGroupAtIndex(2)

        #expect(GroupColor.allCases.contains(color0))
        #expect(GroupColor.allCases.contains(color1))
        #expect(GroupColor.allCases.contains(color2))
    }

    // MARK: - getColorForGroupAtIndex() 境界値テスト

    @Test("getColorForGroupAtIndex - 負のインデックス")
    func getColorForGroupAtIndex_negativeIndex() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        try RealmManager.shared.saveItem(createTestGroup(title: "グループ1", color: .red))
        await viewModel.fetchData()

        let color = viewModel.getColorForGroupAtIndex(-1)

        #expect(color == GroupColor.gray)
    }

    @Test("getColorForGroupAtIndex - 範囲外のインデックス")
    func getColorForGroupAtIndex_outOfBounds() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        try RealmManager.shared.saveItem(createTestGroup(title: "グループ1", color: .red))
        await viewModel.fetchData()

        let color = viewModel.getColorForGroupAtIndex(10)

        #expect(color == GroupColor.gray)
    }

    @Test("getColorForGroupAtIndex - 空の配列")
    func getColorForGroupAtIndex_emptyArray() async {
        await cleanupRealm()
        let viewModel = createViewModel()
        await viewModel.fetchData()

        let color = viewModel.getColorForGroupAtIndex(0)

        #expect(color == GroupColor.gray)
    }

    // MARK: - getTitleForGroupAtIndex() 正常系テスト

    @Test("getTitleForGroupAtIndex - 有効なインデックス")
    func getTitleForGroupAtIndex_validIndex() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        try RealmManager.shared.saveItem(createTestGroup(title: "タイトル1", order: 0))
        try RealmManager.shared.saveItem(createTestGroup(title: "タイトル2", order: 1))
        await viewModel.fetchData()

        let title0 = viewModel.getTitleForGroupAtIndex(0)
        let title1 = viewModel.getTitleForGroupAtIndex(1)

        #expect(!title0.isEmpty)
        #expect(!title1.isEmpty)
    }

    // MARK: - getTitleForGroupAtIndex() 境界値テスト

    @Test("getTitleForGroupAtIndex - 負のインデックス")
    func getTitleForGroupAtIndex_negativeIndex() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        try RealmManager.shared.saveItem(createTestGroup(title: "タイトル1"))
        await viewModel.fetchData()

        let title = viewModel.getTitleForGroupAtIndex(-1)

        #expect(title == "")
    }

    @Test("getTitleForGroupAtIndex - 範囲外のインデックス")
    func getTitleForGroupAtIndex_outOfBounds() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        try RealmManager.shared.saveItem(createTestGroup(title: "タイトル1"))
        await viewModel.fetchData()

        let title = viewModel.getTitleForGroupAtIndex(10)

        #expect(title == "")
    }

    @Test("getTitleForGroupAtIndex - 空の配列")
    func getTitleForGroupAtIndex_emptyArray() async {
        await cleanupRealm()
        let viewModel = createViewModel()
        await viewModel.fetchData()

        let title = viewModel.getTitleForGroupAtIndex(0)

        #expect(title == "")
    }

    // MARK: - エラーハンドリングテスト

    @Test("エラーアラート - showErrorAlert")
    func errorAlert_show() {
        let viewModel = createViewModel()
        let error = SportsNoteError.realmReadFailed("テストエラー")

        viewModel.showErrorAlert(error)

        #expect(viewModel.showingErrorAlert == true)
        #expect(viewModel.currentError != nil)
    }

    @Test("エラーアラート - hideErrorAlert")
    func errorAlert_hide() {
        let viewModel = createViewModel()
        let error = SportsNoteError.realmReadFailed("テストエラー")

        viewModel.showErrorAlert(error)
        viewModel.hideErrorAlert()

        #expect(viewModel.showingErrorAlert == false)
        #expect(viewModel.currentError == nil)
    }

    @Test("エラーアラート - refresh成功時にエラーをクリア")
    func errorAlert_refreshSuccess() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()
        let error = SportsNoteError.realmReadFailed("テストエラー")

        // エラー状態にする
        viewModel.showErrorAlert(error)
        #expect(viewModel.showingErrorAlert == true)

        // リフレッシュ
        await viewModel.refresh()

        #expect(viewModel.showingErrorAlert == false)
        #expect(viewModel.currentError == nil)
    }

    // MARK: - 統合テスト

    @Test("統合テスト - グループのCRUDライフサイクル")
    func integration_crudLifecycle() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        // 1. 初期状態を確認
        await viewModel.fetchData()
        #expect(viewModel.groups.isEmpty)

        // 2. グループを作成
        let groupID = UUIDGenerator.generateID()
        let createResult = await viewModel.saveGroup(
            groupID: groupID,
            title: "統合テストグループ",
            color: .purple,
            order: 0
        )
        #expect(createResult.isSuccess)
        #expect(viewModel.groups.count == 1)

        // 3. グループを取得
        let fetchResult = await viewModel.fetchById(id: groupID)
        if case .success(let group) = fetchResult {
            #expect(group != nil)
            #expect(group?.title == "統合テストグループ")
        } else {
            Issue.record("Failed to fetch group")
        }

        // 4. グループを更新
        let updateResult = await viewModel.saveGroup(
            groupID: groupID,
            title: "更新されたグループ",
            color: .orange,
            order: 0
        )
        #expect(updateResult.isSuccess)
        #expect(viewModel.groups[0].title == "更新されたグループ")

        // 5. グループを削除
        let deleteResult = await viewModel.delete(id: groupID)
        #expect(deleteResult.isSuccess)
        #expect(viewModel.groups.isEmpty)
    }

    @Test("統合テスト - 複数グループの並び順")
    func integration_multipleGroupsOrdering() async throws {
        await cleanupRealm()
        let viewModel = createViewModel()

        // 複数のグループを異なる順序で作成
        for i in 0..<5 {
            let result = await viewModel.saveGroup(
                title: "グループ\(i)",
                color: GroupColor.allCases[i % GroupColor.allCases.count],
                order: i
            )
            #expect(result.isSuccess)
        }

        await viewModel.fetchData()
        #expect(viewModel.groups.count == 5)

        // 各グループの色とタイトルを確認
        for i in 0..<5 {
            let color = viewModel.getColorForGroupAtIndex(i)
            let title = viewModel.getTitleForGroupAtIndex(i)

            #expect(GroupColor.allCases.contains(color))
            #expect(!title.isEmpty)
        }
    }
}

// MARK: - Result Extension for Testing

extension Result {
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    var isFailure: Bool {
        if case .failure = self {
            return true
        }
        return false
    }
}
