import SwiftUI
import RealmSwift

@MainActor
class GroupViewModel: ObservableObject {
    @Published var groups: [Group] = []
    
    init() {
        fetchGroups()
    }
    
    // MARK: - Data Operations
    
    func fetchGroups() {
        groups = RealmManager.shared.getDataList(clazz: Group.self)
    }
    
    /// グループ保存処理(更新も兼ねる)
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
        
        RealmManager.shared.saveItem(group)

        // TODO: Firebaseへの同期

        fetchGroups()
    }
    
    func deleteGroup(id: String) {
        RealmManager.shared.logicalDelete(id: id, type: Group.self)
        fetchGroups()
    }
}
