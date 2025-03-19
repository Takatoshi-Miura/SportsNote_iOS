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
        self.measuresID = ""
        self.noteID = ""
        self.detail = ""
        self.isDeleted = false
        self.created_at = Date()
        self.updated_at = Date()
        self.noteDate = Date()
        
        // UserDefaultsから同期的に値を取得
        if let userID = UserDefaults.standard.string(forKey: "userID") {
            self.userID = userID
        } else {
            self.userID = ""
        }
    }

    convenience init(
        measuresID: String,
        noteID: String,
        detail: String
    ) {
        self.init()
        self.measuresID = measuresID
        self.noteID = noteID
        self.detail = detail
    }

    override static func primaryKey() -> String? {
        return "memoID"
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
