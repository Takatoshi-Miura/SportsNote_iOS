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
    
    func saveGroup(title: String, color: GroupColor, order: Int? = nil) {
        let newOrder = order ?? RealmManager.shared.getCount(clazz: Group.self)
        
        let group = Group(
            title: title,
            color: color.rawValue,
            order: newOrder,
            created_at: Date()
        )
        
        RealmManager.shared.saveItem(group)
        fetchGroups()
    }
    
    func updateGroup(group: Group) {
        RealmManager.shared.saveItem(group)
        fetchGroups()
    }
    
    func updateExistingGroup(id: String, title: String, color: Int) {
        do {
            let realm = try Realm()
            if let groupToUpdate = realm.object(ofType: Group.self, forPrimaryKey: id) {
                try realm.write {
                    groupToUpdate.title = title
                    groupToUpdate.color = color
                    groupToUpdate.updated_at = Date()
                }
                fetchGroups()
            }
        } catch {
            print("Error updating group: \(error)")
        }
    }
    
    func deleteGroup(id: String) {
        RealmManager.shared.logicalDelete(id: id, type: Group.self)
        fetchGroups()
    }
}
