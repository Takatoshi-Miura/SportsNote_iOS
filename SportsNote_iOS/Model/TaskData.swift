import Foundation
import RealmSwift

/// 課題
open class TaskData: Object {
    @Persisted(primaryKey: true) var taskID: String
    @Persisted var userID: String
    @Persisted var groupID: String
    @Persisted var title: String
    @Persisted var cause: String
    @Persisted var order: Int
    @Persisted var isComplete: Bool
    @Persisted var isDeleted: Bool
    @Persisted var created_at: Date
    @Persisted var updated_at: Date
    
    override init() {
        super.init()
        taskID = UUID().uuidString
        groupID = ""
        title = ""
        cause = ""
        order = 0
        isComplete = false
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
        cause: String,
        groupID: String,
        isComplete: Bool = false
    ) {
        self.init()
        self.title = title
        self.cause = cause
        self.groupID = groupID
        self.isComplete = isComplete
    }
    
    public override static func primaryKey() -> String? {
        return "taskID"
    }
}

// 課題追加用データ
struct AddTaskData {
    let title: String
    let cause: String
    let measuresTitle: String
    let groupList: [Group]

    init(title: String = "", cause: String = "", measuresTitle: String = "", groupList: [Group] = []) {
        self.title = title
        self.cause = cause
        self.measuresTitle = measuresTitle
        self.groupList = groupList
    }
}

// 課題一覧用データ
struct TaskListData {
    let taskID: String
    let groupID: String
    let groupColor: GroupColor
    let title: String
    let measuresID: String
    let measures: String
    var memoID: String?
    let order: Int
}

// 課題詳細用データ
struct TaskDetailData {
    let task: TaskData
    var measuresList: [Measures]
}
