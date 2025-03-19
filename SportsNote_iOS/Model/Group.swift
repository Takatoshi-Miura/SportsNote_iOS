import UIKit
import RealmSwift

/// グループ
class Group: Object {
    @Persisted(primaryKey: true) var groupID: String
    @Persisted var userID: String
    @Persisted var title: String
    @Persisted var color: Int
    @Persisted var order: Int
    @Persisted var isDeleted: Bool
    @Persisted var created_at: Date
    @Persisted var updated_at: Date
    
    override init() {
        super.init()
        groupID = UUID().uuidString
        title = ""
        color = GroupColor.red.rawValue
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
        title: String,
        color: Int,
        order: Int,
        created_at: Date
    ) {
        self.init()
        self.title = title
        self.color = color
        self.order = order
        self.created_at = created_at
    }

    override static func primaryKey() -> String? {
        return "groupID"
    }
}

enum GroupColor: Int, CaseIterable {
    case red
    case pink
    case orange
    case yellow
    case green
    case blue
    case purple
    case gray
    
    var title: String {
        switch self {
        case .red: return LocalizedStrings.red
        case .pink: return LocalizedStrings.pink
        case .orange: return LocalizedStrings.orange
        case .yellow: return LocalizedStrings.yellow
        case .green: return LocalizedStrings.green
        case .blue: return LocalizedStrings.blue
        case .purple: return LocalizedStrings.purple
        case .gray: return LocalizedStrings.gray
        }
    }
    
    var color: UIColor {
        switch self {
        case .red: return UIColor.systemRed
        case .pink: return UIColor.systemPink
        case .orange: return UIColor.systemOrange
        case .yellow: return UIColor.systemYellow
        case .green: return UIColor.systemGreen
        case .blue: return UIColor.systemBlue
        case .purple: return UIColor.systemPurple
        case .gray: return UIColor.systemGray
        }
    }
}
