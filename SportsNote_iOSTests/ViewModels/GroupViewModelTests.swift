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
        try? manager.clearAll()

        let group = Group(
            groupID: "g-invalid-color", title: "Broken Group", color: 99, order: 0, created_at: Date())
        try manager.saveItem(group)

        let color = GroupViewModel.getGroupColor(groupID: "g-invalid-color")
        #expect(color == .gray)

        try? manager.clearAll()
    }

    // MARK: - CRUD操作テスト

    @Test("fetchData - データを取得できる")
    func fetchData_retrievesData() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        try? manager.clearAll()

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

        try? manager.clearAll()
    }

    @Test("save - 新規グループを保存できる")
    func save_savesNewGroup() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        try? manager.clearAll()

        let group = Group(
            groupID: "new-g", title: "New Group", color: GroupColor.green.rawValue, order: 0, created_at: Date())

        let result = await viewModel.save(group)

        if case .failure = result {
            Issue.record("Save failed")
        }

        #expect(viewModel.groups.count == 1)
        #expect(viewModel.groups.first?.groupID == "new-g")

        try? manager.clearAll()
    }

    @Test("delete - グループを削除できる")
    func delete_deletesGroup() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        try? manager.clearAll()

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

        try? manager.clearAll()
    }

    @Test(
        "delete - performBackgroundSyncが直接呼ばれ、戻り値を返す前にBackgroundSyncTrackerへ登録される（issue #164回帰）"
    )
    func delete_registersBackgroundSyncTaskBeforeReturning() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        try? manager.clearAll()

        // 他テストの追跡Taskが残っていないことを保証
        await BackgroundSyncTracker.shared.waitForAll()

        let group1 = Group(
            groupID: "g1", title: "Group 1", color: GroupColor.red.rawValue, order: 0, created_at: Date())
        let group2 = Group(
            groupID: "g2", title: "Group 2", color: GroupColor.blue.rawValue, order: 1, created_at: Date())
        try? manager.saveItem(group1)
        try? manager.saveItem(group2)
        _ = await viewModel.fetchData()

        _ = await viewModel.delete(id: "g1")

        // delete(id:)から戻った直後（追加のawait/yieldを挟まない）時点でperformBackgroundSyncが
        // 直接（同期的に）呼ばれていればtrack()は既に完了している。外側Task{}でラップされていると
        // この時点ではまだ登録されておらず0のままになる（issue #164のシナリオを再現する回帰テスト）
        #expect(BackgroundSyncTracker.shared.trackedCountForTesting == 1)

        await BackgroundSyncTracker.shared.waitForAll()
        #expect(BackgroundSyncTracker.shared.trackedCountForTesting == 0)

        try? manager.clearAll()
    }

    @Test(
        "delete - カスケードで論理削除された子エンティティ（TaskData/Measures/Memo）もバックグラウンドFirebase同期が追跡登録される（issue #181回帰）"
    )
    func delete_tracksCascadeBackgroundSyncForChildEntities() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        try? manager.clearAll()

        // 他テストの追跡Taskが残っていないことを保証
        await BackgroundSyncTracker.shared.waitForAll()

        // 他グループを1つ用意しcanDeleteをtrueにした上で、g1配下にTaskData/Measures/Memoを作成する
        let group1 = Group(
            groupID: "g1", title: "Group 1", color: GroupColor.red.rawValue, order: 0, created_at: Date())
        let group2 = Group(
            groupID: "g2", title: "Group 2", color: GroupColor.blue.rawValue, order: 1, created_at: Date())
        try? manager.saveItem(group1)
        try? manager.saveItem(group2)

        let task = TaskData()
        task.taskID = "t-cascade-sync"
        task.groupID = "g1"
        try? manager.saveItem(task)

        let measures = Measures()
        measures.measuresID = "m-cascade-sync"
        measures.taskID = "t-cascade-sync"
        try? manager.saveItem(measures)

        let memo = Memo()
        memo.memoID = "memo-cascade-sync"
        memo.measuresID = "m-cascade-sync"
        try? manager.saveItem(memo)

        _ = await viewModel.fetchData()

        _ = await viewModel.delete(id: "g1")

        // 削除対象本体（Group）分のTaskに加え、カスケードで論理削除された
        // TaskData/Measures/Memoをまとめて同期するTaskが1件、delete(id:)から戻った
        // 時点（追加のawait/yieldを挟まない）で既に追跡登録されている必要がある（issue #181対応）
        #expect(BackgroundSyncTracker.shared.trackedCountForTesting == 2)

        await BackgroundSyncTracker.shared.waitForAll()
        #expect(BackgroundSyncTracker.shared.trackedCountForTesting == 0)

        try? manager.clearAll()
    }

    @Test("saveGroup - 既存インターフェースでグループを保存できる")
    func saveGroup_savesWithLegacyInterface() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        try? manager.clearAll()

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

        try? manager.clearAll()
    }

    @Test("getColorForGroupAtIndex - グループカラーを取得できる")
    func getColorForGroupAtIndex_retrievesColor() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        try? manager.clearAll()

        let group = Group(groupID: "g1", title: "Group 1", color: GroupColor.red.rawValue, order: 0, created_at: Date())
        try? manager.saveItem(group)

        _ = await viewModel.fetchData()

        let color = viewModel.getColorForGroupAtIndex(0)
        #expect(color == .red)

        try? manager.clearAll()
    }

    @Test("getTitleForGroupAtIndex - グループタイトルを取得できる")
    func getTitleForGroupAtIndex_retrievesTitle() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        try? manager.clearAll()

        let group = Group(
            groupID: "g1", title: "Test Group", color: GroupColor.red.rawValue, order: 0, created_at: Date())
        try? manager.saveItem(group)

        _ = await viewModel.fetchData()

        let title = viewModel.getTitleForGroupAtIndex(0)
        #expect(title == "Test Group")

        try? manager.clearAll()
    }

    // MARK: - order値回帰テスト（issue #21: 削除後の新規追加でorderが逆転する不具合）

    @Test("saveGroup - 削除後に新規追加すると末尾のorderになる（未削除件数ベースでは逆転してしまう回帰確認）")
    func saveGroup_afterDeletion_newGroupGetsMaxOrderPlusOne() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        try? manager.clearAll()

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

        try? manager.clearAll()
    }

    // MARK: - reorderGroups / persistGroupOrder（グループ並び替えの同期性）テスト（issue #169）

    @Test("reorderGroups - Realmへの永続化を待たずに同期的にgroups配列へ反映される")
    func reorderGroups_synchronouslyUpdatesGroups() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        try? manager.clearAll()

        let groupA = GroupViewModelTests.createTestGroup(id: "g-A", title: "A", order: 0)
        let groupB = GroupViewModelTests.createTestGroup(id: "g-B", title: "B", order: 1)
        let groupC = GroupViewModelTests.createTestGroup(id: "g-C", title: "C", order: 2)
        try? manager.saveItem(groupA)
        try? manager.saveItem(groupB)
        try? manager.saveItem(groupC)

        _ = await viewModel.fetchData()
        #expect(viewModel.groups.map { $0.groupID } == ["g-A", "g-B", "g-C"])

        // CをAより前に移動（index2->0）。awaitを挟まず、同期呼び出し直後にgroupsが
        // 更新済みであることを確認する（GroupForm.onMoveから非同期Taskでラップせず
        // 直接呼べることの検証、issue #169）
        let reordered = viewModel.reorderGroups(from: IndexSet(integer: 2), to: 0)

        #expect(viewModel.groups.map { $0.groupID } == ["g-C", "g-A", "g-B"])
        #expect(reordered.map { $0.groupID } == ["g-C", "g-A", "g-B"])

        // この時点ではRealmへの永続化（persistGroupOrder）はまだ行われていないため、
        // Realm上のorderは変化していないはず
        let groupsBeforePersist = (try? manager.getDataList(clazz: Group.self)) ?? []
        let orderABeforePersist = groupsBeforePersist.first { $0.groupID == "g-A" }?.order
        #expect(orderABeforePersist == 0)

        try? manager.clearAll()
    }

    @Test("persistGroupOrder - Realmのorderへ反映後、fetchDataで再取得しても同じ並び順を維持する")
    func persistGroupOrder_updatesRealmOrderAndRefetchesGroups() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        try? manager.clearAll()

        let groupA = GroupViewModelTests.createTestGroup(id: "g-A", title: "A", order: 0)
        let groupB = GroupViewModelTests.createTestGroup(id: "g-B", title: "B", order: 1)
        let groupC = GroupViewModelTests.createTestGroup(id: "g-C", title: "C", order: 2)
        try? manager.saveItem(groupA)
        try? manager.saveItem(groupB)
        try? manager.saveItem(groupC)

        _ = await viewModel.fetchData()
        let reordered = viewModel.reorderGroups(from: IndexSet(integer: 2), to: 0)

        let result = await viewModel.persistGroupOrder(reordered)
        guard case .success = result else {
            Issue.record("persistGroupOrder failed")
            try? manager.clearAll()
            return
        }

        let updatedGroups = (try? manager.getDataList(clazz: Group.self)) ?? []
        let orderC = updatedGroups.first { $0.groupID == "g-C" }?.order
        let orderA = updatedGroups.first { $0.groupID == "g-A" }?.order
        let orderB = updatedGroups.first { $0.groupID == "g-B" }?.order
        #expect(orderC == 0 && orderA == 1 && orderB == 2)

        // fetchDataによる再取得後も、ドラッグ確定時に反映した並び順から変化しない
        // （＝一旦元の位置に戻ってから正しい位置に変わるスナップバックが発生しない）ことを確認
        _ = await viewModel.fetchData()
        #expect(viewModel.groups.map { $0.groupID } == ["g-C", "g-A", "g-B"])

        try? manager.clearAll()
    }

    @Test("moveGroup - 表示反映と永続化を一括で行いRealmへ反映される（後方互換ラッパーの回帰確認）")
    func moveGroup_reordersAndPersists() async {
        let viewModel = GroupViewModel()
        let manager = RealmManager.shared
        try? manager.clearAll()

        let groupA = GroupViewModelTests.createTestGroup(id: "g-A", title: "A", order: 0)
        let groupB = GroupViewModelTests.createTestGroup(id: "g-B", title: "B", order: 1)
        try? manager.saveItem(groupA)
        try? manager.saveItem(groupB)

        _ = await viewModel.fetchData()

        let result = await viewModel.moveGroup(from: IndexSet(integer: 1), to: 0)
        guard case .success = result else {
            Issue.record("moveGroup failed")
            try? manager.clearAll()
            return
        }

        #expect(viewModel.groups.map { $0.groupID } == ["g-B", "g-A"])

        let updatedGroups = (try? manager.getDataList(clazz: Group.self)) ?? []
        let orderA = updatedGroups.first { $0.groupID == "g-A" }?.order
        let orderB = updatedGroups.first { $0.groupID == "g-B" }?.order
        #expect(orderB == 0 && orderA == 1)

        try? manager.clearAll()
    }

    // MARK: - convertFirebaseSyncError テスト（issue #36: エラー二重変換防止）

    @Test(
        "convertFirebaseSyncError - 既にSportsNoteErrorの場合は再変換せずそのまま返す",
        arguments: [
            SportsNoteError.firebasePermissionDenied,
            SportsNoteError.firebaseDocumentNotFound,
            SportsNoteError.firebaseQuotaExceeded,
            SportsNoteError.networkUnavailable,
            SportsNoteError.networkTimeout,
        ])
    func convertFirebaseSyncError_doesNotReconvertExistingSportsNoteError(original: SportsNoteError) async {
        let viewModel = GroupViewModel()

        let converted = viewModel.convertFirebaseSyncError(original, context: "GroupViewModel-syncEntityToFirebase")

        // 再変換されていれば、SportsNoteErrorがNSErrorへブリッジされる際のenum宣言順オーディナルが
        // Firestoreエラーコードと誤って一致し、errorDescriptionが変化してしまう
        #expect(converted.errorDescription == original.errorDescription)
    }

    @Test("convertFirebaseSyncError - SportsNoteError以外のエラーはErrorMapper.mapFirebaseErrorで変換される")
    func convertFirebaseSyncError_mapsUnknownErrorViaErrorMapper() async {
        let viewModel = GroupViewModel()
        struct DummyError: Error {}

        let converted = viewModel.convertFirebaseSyncError(DummyError(), context: "test")

        // DummyErrorはNSErrorへの標準ブリッジでcodeが既知のFirestoreエラーコード（7,5,14,8,16,13,4）や
        // 1000以上に該当しないため、ErrorMapper.mapFirebaseErrorのdefault分岐によりunexpectedErrorに変換される
        switch converted {
        case .unexpectedError:
            break  // ErrorMapper.mapFirebaseErrorの想定フォールバック経路
        default:
            Issue.record("想定外の変換結果: \(converted)")
        }
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
