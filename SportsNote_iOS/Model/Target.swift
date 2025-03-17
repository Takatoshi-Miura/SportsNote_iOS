import Foundation
import RealmSwift

/// 目標
open class Target: Object {
    @Persisted(primaryKey: true) var targetID: String
    @Persisted var userID: String
    @Persisted var title: String
    @Persisted var year: Int
    @Persisted var month: Int
    @Persisted var isYearlyTarget: Bool
    @Persisted var isDeleted: Bool
    @Persisted var created_at: Date
    @Persisted var updated_at: Date
    
    override init() {
        super.init()
        targetID = UUID().uuidString
        userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
        title = ""
        year = 2020
        month = 1
        isYearlyTarget = false
        isDeleted = false
        created_at = Date()
        updated_at = Date()
    }
    
    convenience init(
        title: String,
        year: Int,
        month: Int,
        isYearlyTarget: Bool = false
    ) {
        self.init()
        self.title = title
        self.year = year
        self.month = month
        self.isYearlyTarget = isYearlyTarget
    }
    
    public override static func primaryKey() -> String? {
        return "targetID"
    }
}
