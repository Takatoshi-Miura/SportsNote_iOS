import UIKit
import RealmSwift

/// 対策
class Measures: Object {
    @Persisted(primaryKey: true) var measuresID: String
    @Persisted var userID: String
    @Persisted var taskID: String
    @Persisted var title: String
    @Persisted var order: Int
    @Persisted var isDeleted: Bool
    @Persisted var created_at: Date
    @Persisted var updated_at: Date
    
    override init() {
        super.init()
        measuresID = UUID().uuidString
        userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        taskID = ""
        title = ""
        order = 0
        isDeleted = false
        created_at = Date()
        updated_at = Date()
    }
    
    convenience init(
        taskID: String,
        title: String,
        order: Int
    ) {
        self.init()
        self.taskID = taskID
        self.title = title
        self.order = order
    }
    
    override static func primaryKey() -> String? {
        return "measuresID"
    }
}
