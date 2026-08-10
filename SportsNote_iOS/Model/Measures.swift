import RealmSwift
import UIKit

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
        measuresID = UUIDGenerator.generateID()
        taskID = ""
        title = ""
        order = 0
        isDeleted = false
        created_at = Date()
        updated_at = Date()

        // UserDefaultsから同期的に値を取得
        self.userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
    }

    convenience init(
        measuresID: String,
        taskID: String,
        title: String,
        order: Int,
        created_at: Date,
        isDeleted: Bool = false
    ) {
        self.init()
        self.measuresID = measuresID
        self.taskID = taskID
        self.title = title
        self.order = order
        self.created_at = created_at
        self.isDeleted = isDeleted
    }

    override static func primaryKey() -> String? {
        return "measuresID"
    }
}
