import RealmSwift
import SwiftUI

@MainActor
class GroupViewModel: ObservableObject, @preconcurrency BaseViewModelProtocol, @preconcurrency CRUDViewModelProtocol,
    @preconcurrency FirebaseSyncable
{
    typealias EntityType = Group
    @Published var groups: [Group] = []
    @Published var isLoading: Bool = false
    @Published var currentError: SportsNoteError?
    @Published var showingErrorAlert: Bool = false

    init() {
        // 初期化のみ実行、データ取得はView側で明示的に実行
    }

    /// データを取得する基本メソッド
    func fetchData() async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // Realm操作はMainActorで実行
            groups = try RealmManager.shared.getDataList(clazz: Group.self)
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
    /// - Returns: 保存結果
    func saveGroup(
        groupID: String? = nil,
        title: String,
        color: GroupColor,
        order: Int? = nil,
        created_at: Date? = nil
    ) async -> Result<Void, SportsNoteError> {
        let newGroupID = groupID ?? UUID().uuidString
        let newOrder =
            order
            ?? {
                do {
                    return try RealmManager.shared.getCount(clazz: Group.self)
                } catch {
                    // エラー時は0を返す（デフォルト値）
                    return 0
                }
            }()
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

    /// エンティティを保存（新規作成・更新）する
    func save(_ entity: Group, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // Realm操作はMainActorで実行
            try RealmManager.shared.saveItem(entity)

            // Firebase同期のみバックグラウンドで実行
            Task.detached {
                try? await self.syncEntityToFirebase(entity, isUpdate: isUpdate)
            }

            // UI更新
            groups = try RealmManager.shared.getDataList(clazz: Group.self)
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "GroupViewModel-save")
            return .failure(sportsNoteError)
        }
    }

    /// エンティティをFirebaseに同期する
    func syncEntityToFirebase(_ entity: Group, isUpdate: Bool = false) async throws {
        guard isOnlineAndLoggedIn else { return }

        if isUpdate {
            try await FirebaseManager.shared.updateGroup(group: entity)
        } else {
            try await FirebaseManager.shared.saveGroup(group: entity)
        }
    }

    /// 指定されたIDのエンティティを削除する
    func delete(id: String) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // 1. Realm操作はMainActorで実行
            try RealmManager.shared.logicalDelete(id: id, type: Group.self)

            // 2. Firebase同期のみバックグラウンドで実行
            if isOnlineAndLoggedIn {
                if let deletedGroup = try RealmManager.shared.getObjectById(id: id, type: Group.self) {
                    Task.detached {
                        try? await FirebaseManager.shared.saveGroup(group: deletedGroup)
                    }
                }
            }

            // 3. UI更新
            groups = try RealmManager.shared.getDataList(clazz: Group.self)
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "GroupViewModel-delete")
            return .failure(sportsNoteError)
        }
    }


    /// 指定されたIDのエンティティを取得する
    func fetchById(id: String) async -> Result<Group?, SportsNoteError> {
        do {
            let group = try RealmManager.shared.getObjectById(id: id, type: Group.self)
            return .success(group)
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "GroupViewModel-fetchById")
            return .failure(sportsNoteError)
        }
    }

    /// Firebaseへの同期処理を実行する
    func syncToFirebase() async throws {
        guard isOnlineAndLoggedIn else { return }

        let allGroups = try RealmManager.shared.getDataList(clazz: Group.self)

        for group in allGroups {
            try await syncEntityToFirebase(group)
        }
    }
}
