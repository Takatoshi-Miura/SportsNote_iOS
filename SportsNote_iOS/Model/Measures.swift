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

    /// デフォルトイニシャライザ
    convenience override init() {
        self.init(
            measuresID: UUID().uuidString,
            taskID: "",
            title: "",
            order: 0,
            created_at: Date()
        )
    }

    convenience init(
        measuresID: String = UUID().uuidString,
        taskID: String,
        title: String,
        order: Int,
        created_at: Date = Date()
    ) {
        self.init()
        self.measuresID = measuresID
        self.userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: UUID().uuidString)
        self.taskID = taskID
        self.title = title
        self.order = order
        self.isDeleted = false
        self.created_at = created_at
        self.updated_at = Date()
    }
}
