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
        taskID = ""
        title = ""
        order = 0
        isDeleted = false
        created_at = Date()
        updated_at = Date()
        
        // UserDefaultsから同期的に値を取得
        if let userID = UserDefaults.standard.string(forKey: "userID") {
            self.userID = userID
        } else {
            self.userID = ""
        }
    }
    
    convenience init(
        measuresID: String,
        taskID: String,
        title: String,
        order: Int,
        created_at: Date
    ) {
        self.init()
        self.measuresID = measuresID
        self.taskID = taskID
        self.title = title
        self.order = order
        self.created_at = created_at
    }
    
    override static func primaryKey() -> String? {
        return "measuresID"
    }
}
