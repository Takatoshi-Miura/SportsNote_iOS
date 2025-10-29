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

    /// グループが削除可能かどうかを判定
    var canDelete: Bool {
        return groups.count > 1
    }

    init() {
        // 初期化のみ実行、データ取得はView側で明示的に実行
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
        let newOrder = order ?? getDefaultOrder()
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

    /// デフォルトの並び順を取得する
    /// - Returns: 並び順
    private func getDefaultOrder() -> Int {
        do {
            return try RealmManager.shared.getCount(clazz: Group.self)
        } catch {
            // エラー時は0を返す（デフォルト値）
            return 0
        }
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
            // Realm操作はMainActorで実行
            try RealmManager.shared.saveItem(entity)

            // Firebase同期を非同期で実行（MainActorを維持）
            Task {
                let syncResult = await syncEntityToFirebase(entity, isUpdate: isUpdate)
                if case .failure(let error) = syncResult {
                    showErrorAlert(error)
                }
            }

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
        guard isOnlineAndLoggedIn else { return .success(()) }

        do {
            if isUpdate {
                try await FirebaseManager.shared.updateGroup(group: entity)
            } else {
                try await FirebaseManager.shared.saveGroup(group: entity)
            }
            return .success(())
        } catch {
            let sportsNoteError = ErrorMapper.mapFirebaseError(error, context: "GroupViewModel-syncEntityToFirebase")
            return .failure(sportsNoteError)
        }
    }

    /// 指定されたIDのエンティティを削除
    /// - Parameter id: ID
    /// - Returns: Result
    func delete(id: String) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // Realm操作はMainActorで実行
            try RealmManager.shared.logicalDelete(id: id, type: Group.self)

            // Firebase同期を非同期で実行（MainActorを維持）
            if let deletedGroup = try RealmManager.shared.getObjectById(id: id, type: Group.self) {
                Task {
                    let syncResult = await syncEntityToFirebase(deletedGroup, isUpdate: true)
                    if case .failure(let error) = syncResult {
                        showErrorAlert(error)
                    }
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
        do {
            let group = try RealmManager.shared.getObjectById(id: id, type: Group.self)
            hideErrorAlert()
            return .success(group)
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "GroupViewModel-fetchById")
            return .failure(sportsNoteError)
        }
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
            return GroupColor.allCases[Int(group.color)]
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
