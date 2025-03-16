import Foundation
import RealmSwift

/// メモ
class Memo: Object {
    @Persisted(primaryKey: true) var memoID: String
    @Persisted var userID: String
    @Persisted var measuresID: String
    @Persisted var noteID: String
    @Persisted var detail: String
    @Persisted var isDeleted: Bool
    @Persisted var created_at: Date
    @Persisted var updated_at: Date
    @Persisted var noteDate: Date

    /// デフォルトイニシャライザ
    override init() {
        super.init()
        self.memoID = UUID().uuidString
        self.userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: UUID().uuidString)
        self.measuresID = ""
        self.noteID = ""
        self.detail = ""
        self.isDeleted = false
        self.created_at = Date()
        self.updated_at = Date()
        self.noteDate = Date()
    }

    convenience init(
        memoID: String = UUID().uuidString,
        measuresID: String,
        noteID: String,
        detail: String,
        created_at: Date = Date()
    ) {
        self.init()
        self.memoID = memoID
        self.userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: UUID().uuidString)
        self.measuresID = measuresID
        self.noteID = noteID
        self.detail = detail
        self.isDeleted = false
        self.created_at = created_at
        self.updated_at = Date()
        self.noteDate = Date()
    }
}

/// 対策画面用のデータクラス
struct MeasuresMemo {
    let memoID: String
    let measuresID: String
    let noteID: String
    let detail: String
    let date: Date
}
