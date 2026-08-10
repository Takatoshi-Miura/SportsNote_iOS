import Combine
import Foundation
import RealmSwift

@MainActor
class GroupViewModel: ObservableObject, BaseViewModelProtocol, CRUDViewModelProtocol, FirebaseSyncable {
    typealias EntityType = Group
    @Published var groups: [Group] = []
    @Published var isLoading: Bool = false
    @Published var currentError: SportsNoteError?
    @Published var showingErrorAlert: Bool = false

    private var cancellables = Set<AnyCancellable>()

    /// グループが削除可能かどうかを判定
    var canDelete: Bool {
        return groups.count > 1
    }

    init() {
        // 初期化のみ実行、データ取得はView側で明示的に実行
        observeClearAllData(cancellables: &cancellables)
    }

    /// Realmオブジェクトの参照をクリア
    func clearRealmReferences() {
        groups = []
    }

    // MARK: - CURD処理

    /// データを取得
    /// - Returns: Result
    func fetchData() async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // Realm操作はMainActorで実行
            groups = try RealmManager.shared.getDataList(clazz: Group.self)
            hideErrorAlert()
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "GroupViewModel-fetchData")
            return .failure(sportsNoteError)
        }
    }

    /// グループ保存処理(更新も兼ねる) - 既存インターフェースとの互換性のため
    /// - Parameters:
    ///   - groupID: グループID
    ///   - title: タイトル
    ///   - color: カラー
    ///   - order: 並び順
    ///   - created_at: 作成日時
    /// - Returns: Result
    func saveGroup(
        groupID: String? = nil,
        title: String,
        color: GroupColor,
        order: Int? = nil,
        created_at: Date? = nil
    ) async -> Result<Void, SportsNoteError> {
        let newGroupID = groupID ?? UUIDGenerator.generateID()
        let newOrder = order ?? RealmManager.shared.getNextOrder(clazz: Group.self)
        let newCreatedAt = created_at ?? Date()

        let group = Group(
            groupID: newGroupID,
            title: title,
            color: color.rawValue,
            order: newOrder,
            created_at: newCreatedAt
        )

        let isUpdate = groupID != nil
        return await save(group, isUpdate: isUpdate)
    }

    /// グループ表示上の並び替えを同期的に即時反映する（Realm永続化・Firebase同期は含まない）
    /// GroupForm.onMoveハンドラから非同期Taskでラップせず直接呼ぶことで、ドラッグを離した瞬間に
    /// 並び順が確定するようにするため分離した（issue #169、issue #161のreorderTaskListDataと同パターン）
    /// - Parameters:
    ///   - source: 移動元インデックス集合（ForEach .onMove の引数）
    ///   - destination: 移動先インデックス
    /// - Returns: Realm永続化用の並び替え後のグループ配列（`persistGroupOrder`に渡す）
    func reorderGroups(from source: IndexSet, to destination: Int) -> [Group] {
        var reorderedGroups = groups
        reorderedGroups.move(fromOffsets: source, toOffset: destination)
        groups = reorderedGroups
        return reorderedGroups
    }

    /// 並び替え後のグループ配列をRealmへ永続化し、Firebaseへ同期する
    /// - Parameter reorderedGroups: `reorderGroups`が返す並び替え後のグループ配列
    /// - Returns: Result
    func persistGroupOrder(_ reorderedGroups: [Group]) async -> Result<Void, SportsNoteError> {
        do {
            try RealmManager.shared.updateGroupOrder(groups: reorderedGroups)
            // Firebase 同期（各グループを order 更新で同期）
            // ログアウト/アカウント削除等でのRealm全削除前に完了を待機できるよう追跡登録する（Issue #84対応）
            let syncTask = Task<Void, Never> {
                for group in reorderedGroups {
                    _ = await syncEntityToFirebase(group, isUpdate: true)
                }
            }
            BackgroundSyncTracker.shared.track(syncTask)
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "GroupViewModel-moveGroup")
            return .failure(sportsNoteError)
        }
    }

    /// グループの並び順を変更し Realm に保存（表示反映＋永続化を一括で行う、後方互換用ラッパー）
    /// - Parameters:
    ///   - source: 移動元インデックス集合（ForEach .onMove の引数）
    ///   - destination: 移動先インデックス
    /// - Returns: Result
    func moveGroup(from source: IndexSet, to destination: Int) async -> Result<Void, SportsNoteError> {
        let reorderedGroups = reorderGroups(from: source, to: destination)
        return await persistGroupOrder(reorderedGroups)
    }

    /// エンティティを保存（新規作成・更新）
    /// - Parameters:
    ///   - entity: エンティティ
    ///   - isUpdate: 更新要否
    /// - Returns: Result
    func save(_ entity: Group, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // 更新時は、エンティティ再構築時にUserDefaultsの現在値で上書きされてしまったuserIDを、
            // Realmに永続化済みの値に戻す（アカウント作成直後のuserID切替タイミングでも
            // Firebase更新が正しいドキュメントIDに対して行われるようにするため。issue #74）
            if isUpdate, let existingGroup = try RealmManager.shared.getObjectById(id: entity.groupID, type: Group.self)
            {
                entity.userID = existingGroup.userID
            }

            // Realm操作はMainActorで実行
            try RealmManager.shared.saveItem(entity)

            // Firebase同期はバックグラウンドで実行
            performBackgroundSync(entity, isUpdate: isUpdate)

            // UI更新
            groups = try RealmManager.shared.getDataList(clazz: Group.self)
            hideErrorAlert()
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "GroupViewModel-save")
            return .failure(sportsNoteError)
        }
    }

    /// エンティティをFirebaseに同期する
    /// - Parameters:
    ///   - entity: エンティティ
    ///   - isUpdate: 更新要否
    /// - Returns: Result
    func syncEntityToFirebase(_ entity: Group, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
        await syncEntityToFirebaseDefault(
            isUpdate: isUpdate,
            context: "GroupViewModel-syncEntityToFirebase",
            updateAction: { try await FirebaseManager.shared.updateGroup(group: entity) },
            saveAction: { try await FirebaseManager.shared.saveGroup(group: entity) }
        )
    }

    /// 指定されたIDのエンティティを削除
    /// - Parameter id: ID
    /// - Returns: Result
    func delete(id: String) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // 削除前にオブジェクトを取得（論理削除後はisDeleted=trueで取得できなくなるため）
            let groupToDelete = try RealmManager.shared.getObjectById(id: id, type: Group.self)

            // Realm操作はMainActorで実行
            try RealmManager.shared.logicalDelete(id: id, type: Group.self)

            // Firebase同期はバックグラウンドで実行（削除前に取得したオブジェクトを使用）
            if let groupToDelete = groupToDelete {
                Task {
                    performBackgroundSync(groupToDelete, isUpdate: true)
                }
            }

            // UI更新
            groups = try RealmManager.shared.getDataList(clazz: Group.self)
            hideErrorAlert()
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "GroupViewModel-delete")
            return .failure(sportsNoteError)
        }
    }

    /// 指定されたIDのエンティティを取得
    /// - Parameter id: ID
    /// - Returns: Result
    func fetchById(id: String) async -> Result<Group?, SportsNoteError> {
        await fetchByIdDefault(id: id, context: "GroupViewModel-fetchById", onSuccess: { self.hideErrorAlert() })
    }

    /// Firebaseへの同期処理を実行
    /// プロトコル準拠用のため未実装
    func syncToFirebase() async -> Result<Void, SportsNoteError> {
        return .success(())
    }

    // MARK: - Static Utility Methods

    /// グループIDに基づいて色を取得する静的メソッド
    /// - Parameter groupID: グループID
    /// - Returns: GroupColorの列挙型
    static func getGroupColor(groupID: String) -> GroupColor {
        if let group = try? RealmManager.shared.getObjectById(id: groupID, type: Group.self) {
            return group.groupColor
        }
        return GroupColor.gray
    }

    // MARK: - Presentation Logic

    /// グループ配列のインデックスから色を取得（プレゼンテーション用）
    /// - Parameter index: グループ配列のインデックス
    /// - Returns: GroupColor（インデックスが範囲外の場合はgray）
    func getColorForGroupAtIndex(_ index: Int) -> GroupColor {
        guard groups.indices.contains(index) else { return .gray }
        let colorIndex = Int(groups[index].color)
        return GroupColor.allCases.indices.contains(colorIndex) ? GroupColor.allCases[colorIndex] : .gray
    }

    /// グループ配列のインデックスからタイトルを取得（プレゼンテーション用）
    /// - Parameter index: グループ配列のインデックス
    /// - Returns: グループタイトル（インデックスが範囲外の場合は空文字）
    func getTitleForGroupAtIndex(_ index: Int) -> String {
        return groups.indices.contains(index) ? groups[index].title : ""
    }

}
