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

    // デフォルトイニシャライザ
    convenience override init() {
        self.init(
            targetID: UUID().uuidString,
            userID: UUID().uuidString, // TODO: UserDefaultsから取得
            title: "",
            year: 2020,
            month: 1,
            isYearlyTarget: false,
            isDeleted: false,
            created_at: Date(),
            updated_at: Date()
        )
    }

    convenience init(
        targetID: String = UUID().uuidString,
        userID: String = UUID().uuidString, // TODO: UserDefaultsから取得
        title: String,
        year: Int,
        month: Int,
        isYearlyTarget: Bool = false,
        isDeleted: Bool = false,
        created_at: Date = Date(),
        updated_at: Date = Date()
    ) {
        self.init()
        self.targetID = targetID
        self.userID = userID
        self.title = title
        self.year = year
        self.month = month
        self.isYearlyTarget = isYearlyTarget
        self.isDeleted = isDeleted
        self.created_at = created_at
        self.updated_at = updated_at
    }
}
