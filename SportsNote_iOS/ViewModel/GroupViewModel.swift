import RealmSwift
import SwiftUI

@MainActor
class GroupViewModel: ObservableObject, BaseViewModelProtocol, CRUDViewModelProtocol, FirebaseSyncable {
    typealias EntityType = Group
    @Published var groups: [Group] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    init() {
        fetchData()
    }

    /// データを取得する基本メソッド
    func fetchData() {
        fetchGroups()
    }
    
    /// グループ取得
    private func fetchGroups() {
        groups = RealmManager.shared.getDataList(clazz: Group.self)
    }

    /// エンティティを保存（新規作成・更新）する
    func save(_ entity: Group, isUpdate: Bool = false) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            RealmManager.shared.saveItem(entity)
            
            if isOnlineAndLoggedIn {
                try await syncEntityToFirebase(entity, isUpdate: isUpdate)
            }
            
            await MainActor.run {
                fetchGroups()
            }
        } catch {
            handleError(error)
            throw error
        }
    }
    
    /// グループ保存処理(更新も兼ねる) - 既存インターフェースとの互換性のため
    /// - Parameters:
    ///   - groupID: グループID
    ///   - title: タイトル
    ///   - color: カラー
    ///   - order: 並び順
    ///   - created_at: 作成日時
    func saveGroup(
        groupID: String? = nil,
        title: String,
        color: GroupColor,
        order: Int? = nil,
        created_at: Date? = nil
    ) {
        let newGroupID = groupID ?? UUID().uuidString
        let newOrder = order ?? RealmManager.shared.getCount(clazz: Group.self)
        let newCreatedAt = created_at ?? Date()

        let group = Group(
            groupID: newGroupID,
            title: title,
            color: color.rawValue,
            order: newOrder,
            created_at: newCreatedAt
        )

        Task {
            do {
                let isUpdate = groupID != nil
                try await save(group, isUpdate: isUpdate)
            } catch {
                // エラーは既にhandleErrorで処理されている
            }
        }
    }

    /// 指定されたIDのエンティティを削除する
    func delete(id: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            RealmManager.shared.logicalDelete(id: id, type: Group.self)
            
            if isOnlineAndLoggedIn {
                if let deletedGroup = RealmManager.shared.getObjectById(id: id, type: Group.self) {
                    try await syncEntityToFirebase(deletedGroup)
                }
            }
            
            await MainActor.run {
                fetchGroups()
            }
        } catch {
            handleError(error)
            throw error
        }
    }
    
    /// グループ削除処理 - 既存インターフェースとの互換性のため
    /// - Parameter id: グループID
    func deleteGroup(id: String) {
        Task {
            do {
                try await delete(id: id)
            } catch {
                // エラーは既にhandleErrorで処理されている
            }
        }
    }
    
    /// 指定されたIDのエンティティを取得する
    func fetchById(id: String) -> Group? {
        return RealmManager.shared.getObjectById(id: id, type: Group.self)
    }
    
    /// Firebaseへの同期処理を実行する
    func syncToFirebase() async throws {
        guard isOnlineAndLoggedIn else { return }
        
        let allGroups = RealmManager.shared.getDataList(clazz: Group.self)
        
        for group in allGroups {
            try await syncEntityToFirebase(group)
        }
    }
    
    /// 指定されたエンティティをFirebaseに同期する
    func syncEntityToFirebase(_ entity: Group, isUpdate: Bool = false) async throws {
        guard isOnlineAndLoggedIn else { return }
        
        if isUpdate {
            try await FirebaseManager.shared.updateGroup(group: entity)
        } else {
            try await FirebaseManager.shared.saveGroup(group: entity)
        }
    }
}
