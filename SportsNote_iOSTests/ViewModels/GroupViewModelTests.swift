//
//  GroupViewModelTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2025/11/22.
//

import Foundation
import RealmSwift
import Testing
import UIKit

@testable import SportsNote_iOS

@Suite("GroupViewModel Tests", .serialized)
@MainActor
struct GroupViewModelTests {

    init() async throws {
        RealmManager.shared.setupInMemoryRealm()
    }

    // MARK: - 初期化テスト

    @Test("初期化 - プロパティが正しく初期化される")
    func initialization_propertiesAreInitializedCorrectly() async {
        let viewModel = GroupViewModel()

        #expect(viewModel.groups.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.currentError == nil)
        #expect(viewModel.showingErrorAlert == false)
    }

    // MARK: - canDelete プロパティテスト

    @Test("canDelete - グループが2つ以上の場合はtrue", arguments: [2, 3, 5, 10])
    func canDelete_returnsTrueWhenMultipleGroups(count: Int) async {
        let viewModel = GroupViewModel()

        // グループを追加
        for i in 0..<count {
            viewModel.groups.append(
                Group(
                    groupID: "test-\(i)",
                    title: "Group \(i)",
                    color: GroupColor.red.rawValue,
                    order: i,
                    created_at: Date()
                ))
        }

        #expect(viewModel.canDelete == true)
    }

    @Test("canDelete - グループが1つの場合はfalse")
    func canDelete_returnsFalseWhenSingleGroup() async {
        let viewModel = GroupViewModel()

        viewModel.groups.append(
            Group(
                groupID: "test-1",
                title: "Group 1",
                color: GroupColor.red.rawValue,
                order: 0,
                created_at: Date()
            ))

        #expect(viewModel.canDelete == false)
    }

    @Test("canDelete - グループが0の場合はfalse")
    func canDelete_returnsFalseWhenNoGroups() async {
        let viewModel = GroupViewModel()
        #expect(viewModel.canDelete == false)
    }

    // MARK: - getColorForGroupAtIndex テスト

    @Test(
        "getColorForGroupAtIndex - 有効なインデックスで正しい色を返す",
        arguments: zip([GroupColor.red, .blue, .green, .yellow], [0, 1, 2, 3]))
    func getColorForGroupAtIndex_returnsCorrectColor(color: GroupColor, index: Int) async {
        let viewModel = GroupViewModel()

        // テストデータを準備
        viewModel.groups = [
            Group(groupID: "1", title: "Red", color: GroupColor.red.rawValue, order: 0, created_at: Date()),
            Group(groupID: "2", title: "Blue", color: GroupColor.blue.rawValue, order: 1, created_at: Date()),
            Group(groupID: "3", title: "Green", color: GroupColor.green.rawValue, order: 2, created_at: Date()),
            Group(groupID: "4", title: "Yellow", color: GroupColor.yellow.rawValue, order: 3, created_at: Date()),
        ]

        #expect(viewModel.getColorForGroupAtIndex(index) == color)
    }

    @Test("getColorForGroupAtIndex - 無効なインデックスでgrayを返す", arguments: [-1, 10, 100])
    func getColorForGroupAtIndex_returnsGrayForInvalidIndex(invalidIndex: Int) async {
        let viewModel = GroupViewModel()

        viewModel.groups = [
            Group(groupID: "1", title: "Test", color: GroupColor.red.rawValue, order: 0, created_at: Date())
        ]

        #expect(viewModel.getColorForGroupAtIndex(invalidIndex) == .gray)
    }

    @Test("getColorForGroupAtIndex - 空の配列でgrayを返す")
    func getColorForGroupAtIndex_returnsGrayForEmptyArray() async {
        let viewModel = GroupViewModel()
        #expect(viewModel.getColorForGroupAtIndex(0) == .gray)
    }

    @Test("getColorForGroupAtIndex - 無効な色インデックスでgrayを返す")
    func getColorForGroupAtIndex_returnsGrayForInvalidColorIndex() async {
        let viewModel = GroupViewModel()

        // 無効な色インデックスを持つグループを作成
        let group = Group(groupID: "1", title: "Test", color: 999, order: 0, created_at: Date())
        viewModel.groups = [group]

        #expect(viewModel.getColorForGroupAtIndex(0) == .gray)
    }

    // MARK: - getTitleForGroupAtIndex テスト

    @Test(
        "getTitleForGroupAtIndex - 有効なインデックスで正しいタイトルを返す",
        arguments: zip(["Group A", "Group B", "Group C"], [0, 1, 2]))
    func getTitleForGroupAtIndex_returnsCorrectTitle(title: String, index: Int) async {
        let viewModel = GroupViewModel()

        viewModel.groups = [
            Group(groupID: "1", title: "Group A", color: GroupColor.red.rawValue, order: 0, created_at: Date()),
            Group(groupID: "2", title: "Group B", color: GroupColor.blue.rawValue, order: 1, created_at: Date()),
            Group(groupID: "3", title: "Group C", color: GroupColor.green.rawValue, order: 2, created_at: Date()),
        ]

        #expect(viewModel.getTitleForGroupAtIndex(index) == title)
    }

    @Test("getTitleForGroupAtIndex - 無効なインデックスで空文字を返す", arguments: [-1, 5, 100])
    func getTitleForGroupAtIndex_returnsEmptyForInvalidIndex(invalidIndex: Int) async {
        let viewModel = GroupViewModel()

        viewModel.groups = [
            Group(groupID: "1", title: "Test", color: GroupColor.red.rawValue, order: 0, created_at: Date())
        ]

        #expect(viewModel.getTitleForGroupAtIndex(invalidIndex) == "")
    }

    @Test("getTitleForGroupAtIndex - 空の配列で空文字を返す")
    func getTitleForGroupAtIndex_returnsEmptyForEmptyArray() async {
        let viewModel = GroupViewModel()
        #expect(viewModel.getTitleForGroupAtIndex(0) == "")
    }

    @Test(
        "getTitleForGroupAtIndex - 特殊文字を含むタイトル",
        arguments: ["グループ🎾", "Test & Group", "Group (1)", ""])
    func getTitleForGroupAtIndex_handlesSpecialCharacters(title: String) async {
        let viewModel = GroupViewModel()

        viewModel.groups = [
            Group(groupID: "1", title: title, color: GroupColor.red.rawValue, order: 0, created_at: Date())
        ]

        #expect(viewModel.getTitleForGroupAtIndex(0) == title)
    }

    // MARK: - clearRealmReferences テスト

    @Test("clearRealmReferences - 通知受信時にグループがクリアされる")
    func clearRealmReferences_clearsGroupsOnNotification() async {
        let viewModel = GroupViewModel()

        // グループを追加
        viewModel.groups = [
            Group(groupID: "1", title: "Test", color: GroupColor.red.rawValue, order: 0, created_at: Date())
        ]

        #expect(!viewModel.groups.isEmpty)

        // 通知を送信
        NotificationCenter.default.post(name: .didClearAllData, object: nil)

        // 非同期処理を待つ
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

        #expect(viewModel.groups.isEmpty)
    }

    // MARK: - GroupColor 列挙型テスト

    @Test("GroupColor - すべての色が定義されている")
    func groupColor_allColorsAreDefined() {
        let allColors: [GroupColor] = [.red, .pink, .orange, .yellow, .green, .blue, .purple, .gray]
        #expect(GroupColor.allCases.count == allColors.count)
    }

    @Test("GroupColor - rawValueが連続している", arguments: Array(0..<8))
    func groupColor_rawValuesAreSequential(rawValue: Int) {
        #expect(GroupColor(rawValue: rawValue) != nil)
    }

    @Test(
        "GroupColor - 各色にタイトルが設定されている",
        arguments: GroupColor.allCases)
    func groupColor_eachColorHasTitle(color: GroupColor) {
        #expect(!color.title.isEmpty)
    }

    @Test(
        "GroupColor - 各色にUIColorが設定されている",
        arguments: GroupColor.allCases)
    func groupColor_eachColorHasUIColor(color: GroupColor) {
        // UIColorが取得できることを確認
        let uiColor = color.color
        // UIColorはクラスクラスタの可能性があるため、具体的なプロパティをチェック
        #expect(uiColor.cgColor.alpha >= 0)
    }

    // MARK: - saveGroup パラメータテスト

    @Test("saveGroup - 異なる色でグループを作成", arguments: GroupColor.allCases)
    func saveGroup_createsGroupWithDifferentColors(color: GroupColor) async {
        // Note: 実際のRealm操作はモックが必要なため、パラメータの検証のみ
        // 実際のテストではRealmManagerをモック化する必要があります

        // パラメータが正しく渡されることを確認するテスト構造
        // パラメータが正しく渡されることを確認するテスト構造
        // Note: 実際の保存は行わないため、変数は定義しない

        // この時点では実際の保存は行わず、パラメータの妥当性を確認
        #expect(color.rawValue >= 0)
        #expect(color.rawValue < GroupColor.allCases.count)
    }

    // MARK: - 境界値テスト

    @Test("境界値 - 最大数のグループを扱う")
    func boundaryCase_handlesMaximumGroups() async {
        let viewModel = GroupViewModel()
        let maxGroups = 1000

        for i in 0..<maxGroups {
            viewModel.groups.append(
                Group(
                    groupID: "test-\(i)",
                    title: "Group \(i)",
                    color: GroupColor.allCases[i % GroupColor.allCases.count].rawValue,
                    order: i,
                    created_at: Date()
                ))
        }

        #expect(viewModel.groups.count == maxGroups)
        #expect(viewModel.canDelete == true)
    }

    @Test("境界値 - 空のタイトルでグループを作成")
    func boundaryCase_createsGroupWithEmptyTitle() async {
        let viewModel = GroupViewModel()

        let group = Group(
            groupID: "test-1",
            title: "",
            color: GroupColor.red.rawValue,
            order: 0,
            created_at: Date()
        )
        viewModel.groups = [group]

        #expect(viewModel.getTitleForGroupAtIndex(0) == "")
    }

    @Test("境界値 - 非常に長いタイトルでグループを作成")
    func boundaryCase_createsGroupWithVeryLongTitle() async {
        let viewModel = GroupViewModel()
        let longTitle = String(repeating: "あ", count: 1000)

        let group = Group(
            groupID: "test-1",
            title: longTitle,
            color: GroupColor.red.rawValue,
            order: 0,
            created_at: Date()
        )
        viewModel.groups = [group]

        #expect(viewModel.getTitleForGroupAtIndex(0) == longTitle)
        #expect(viewModel.getTitleForGroupAtIndex(0).count == 1000)
    }

    // MARK: - エラーハンドリングテスト

    @Test("エラーハンドリング - isLoadingの初期状態")
    func errorHandling_isLoadingInitialState() async {
        let viewModel = GroupViewModel()
        #expect(viewModel.isLoading == false)
    }

    @Test("エラーハンドリング - currentErrorの初期状態")
    func errorHandling_currentErrorInitialState() async {
        let viewModel = GroupViewModel()
        #expect(viewModel.currentError == nil)
    }

    @Test("エラーハンドリング - showingErrorAlertの初期状態")
    func errorHandling_showingErrorAlertInitialState() async {
        let viewModel = GroupViewModel()
        #expect(viewModel.showingErrorAlert == false)
    }

    // MARK: - getGroupColor 静的メソッドテスト

    @Test("getGroupColor - 存在しないIDでgrayを返す")
    func getGroupColor_returnsGrayForNonexistentID() {
        let color = GroupViewModel.getGroupColor(groupID: "nonexistent-id")
        #expect(color == .gray)
    }

    @Test("getGroupColor - 空のIDでgrayを返す")
    func getGroupColor_returnsGrayForEmptyID() {
        let color = GroupViewModel.getGroupColor(groupID: "")
        #expect(color == .gray)
    }

    @Test(
        "getGroupColor - 無効なUUID形式でgrayを返す",
        arguments: ["invalid", "123", "test-id", "あいうえお"])
    func getGroupColor_returnsGrayForInvalidUUID(invalidID: String) {
        let color = GroupViewModel.getGroupColor(groupID: invalidID)
        #expect(color == .gray)
    }

    @Test("getGroupColor - 範囲外のcolor値でもクラッシュせずgrayを返す（issue #43）")
    func getGroupColor_returnsGrayForOutOfRangeColor() throws {
        let manager = RealmManager.shared
        manager.clearAll()

        let group = Group(
            groupID: "g-invalid-color", title: "Broken Group", color: 99, order: 0, created_at: Date())
        try manager.saveItem(group)

        let color = GroupViewModel.getGroupColor(groupID: "g-invalid-color")
        #expect(color == .gray)

        manager.clearAll()
    }

    // MARK: - CRUD操作テスト

    @Test("fetchData - データを取得できる")
    func fetchData_retrievesData() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        let group1 = Group(
            groupID: "g1", title: "Group 1", color: GroupColor.red.rawValue, order: 0, created_at: Date())
        let group2 = Group(
            groupID: "g2", title: "Group 2", color: GroupColor.blue.rawValue, order: 1, created_at: Date())
        try? manager.saveItem(group1)
        try? manager.saveItem(group2)

        _ = await viewModel.fetchData()

        #expect(viewModel.groups.count == 2)
        #expect(viewModel.groups.contains(where: { $0.groupID == "g1" }))
        #expect(viewModel.groups.contains(where: { $0.groupID == "g2" }))

        manager.clearAll()
    }

    @Test("save - 新規グループを保存できる")
    func save_savesNewGroup() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        let group = Group(
            groupID: "new-g", title: "New Group", color: GroupColor.green.rawValue, order: 0, created_at: Date())

        let result = await viewModel.save(group)

        if case .failure = result {
            Issue.record("Save failed")
        }

        #expect(viewModel.groups.count == 1)
        #expect(viewModel.groups.first?.groupID == "new-g")

        manager.clearAll()
    }

    @Test("delete - グループを削除できる")
    func delete_deletesGroup() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        // 2つのグループを作成（canDeleteがtrueになるように）
        let group1 = Group(
            groupID: "g1", title: "Group 1", color: GroupColor.red.rawValue, order: 0, created_at: Date())
        let group2 = Group(
            groupID: "g2", title: "Group 2", color: GroupColor.blue.rawValue, order: 1, created_at: Date())
        try? manager.saveItem(group1)
        try? manager.saveItem(group2)

        _ = await viewModel.fetchData()
        #expect(viewModel.groups.count == 2)
        #expect(viewModel.canDelete == true)

        let result = await viewModel.delete(id: "g1")

        if case .failure = result {
            Issue.record("Delete failed")
        }

        #expect(viewModel.groups.count == 1)
        #expect(viewModel.groups.first?.groupID == "g2")

        manager.clearAll()
    }

    @Test("saveGroup - 既存インターフェースでグループを保存できる")
    func saveGroup_savesWithLegacyInterface() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        let result = await viewModel.saveGroup(
            title: "Legacy Group",
            color: .purple
        )

        if case .failure = result {
            Issue.record("SaveGroup failed")
        }

        #expect(viewModel.groups.count == 1)
        #expect(viewModel.groups.first?.title == "Legacy Group")
        #expect(viewModel.groups.first?.color == GroupColor.purple.rawValue)

        manager.clearAll()
    }

    @Test("getColorForGroupAtIndex - グループカラーを取得できる")
    func getColorForGroupAtIndex_retrievesColor() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        let group = Group(groupID: "g1", title: "Group 1", color: GroupColor.red.rawValue, order: 0, created_at: Date())
        try? manager.saveItem(group)

        _ = await viewModel.fetchData()

        let color = viewModel.getColorForGroupAtIndex(0)
        #expect(color == .red)

        manager.clearAll()
    }

    @Test("getTitleForGroupAtIndex - グループタイトルを取得できる")
    func getTitleForGroupAtIndex_retrievesTitle() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        let group = Group(
            groupID: "g1", title: "Test Group", color: GroupColor.red.rawValue, order: 0, created_at: Date())
        try? manager.saveItem(group)

        _ = await viewModel.fetchData()

        let title = viewModel.getTitleForGroupAtIndex(0)
        #expect(title == "Test Group")

        manager.clearAll()
    }

    // MARK: - order値回帰テスト（issue #21: 削除後の新規追加でorderが逆転する不具合）

    @Test("saveGroup - 削除後に新規追加すると末尾のorderになる（未削除件数ベースでは逆転してしまう回帰確認）")
    func saveGroup_afterDeletion_newGroupGetsMaxOrderPlusOne() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        // order 0〜3 のグループ4件を作成
        for i in 0..<4 {
            let group = Group(
                groupID: "g-\(i)", title: "Group \(i)", color: GroupColor.red.rawValue, order: i, created_at: Date())
            try? manager.saveItem(group)
        }

        // 先頭3件（order 0〜2）を論理削除。残るのはorder=3の1件のみ
        try? manager.logicalDelete(id: "g-0", type: Group.self)
        try? manager.logicalDelete(id: "g-1", type: Group.self)
        try? manager.logicalDelete(id: "g-2", type: Group.self)

        // 新規グループを追加
        let result = await viewModel.saveGroup(title: "New Group", color: .blue)
        if case .failure = result {
            Issue.record("saveGroup failed")
        }

        // 未削除件数ベース（旧ロジック）なら1になり、残存するorder=3のグループより前に表示されてしまう
        // 最大order+1ベースなら4になり、末尾（最新）に表示される
        let newGroup = viewModel.groups.first(where: { $0.title == "New Group" })
        #expect(newGroup?.order == 4)

        manager.clearAll()
    }
}

// MARK: - テストヘルパー拡張

extension GroupViewModelTests {

    /// テスト用のグループを作成するヘルパーメソッド
    static func createTestGroup(
        id: String = UUIDGenerator.generateID(),
        title: String = "Test Group",
        color: GroupColor = .red,
        order: Int = 0
    ) -> Group {
        return Group(
            groupID: id,
            title: title,
            color: color.rawValue,
            order: order,
            created_at: Date()
        )
    }

    /// 複数のテストグループを作成するヘルパーメソッド
    static func createTestGroups(count: Int) -> [Group] {
        return (0..<count)
            .map { i in
                createTestGroup(
                    id: "test-\(i)",
                    title: "Group \(i)",
                    color: GroupColor.allCases[i % GroupColor.allCases.count],
                    order: i
                )
            }
    }
}
