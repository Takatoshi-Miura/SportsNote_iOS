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

    // デフォルトイニシャライザ
    convenience override init() {
        self.init(
            taskID: UUID().uuidString,
            title: "",
            cause: "",
            groupID: "",
            isComplete: false,
            created_at: Date()
        )
    }

    convenience init(
        taskID: String = UUID().uuidString,
        title: String,
        cause: String,
        groupID: String,
        isComplete: Bool,
        created_at: Date = Date()
    ) {
        self.init()
        self.taskID = taskID
        self.userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: UUID().uuidString)
        self.groupID = groupID
        self.title = title
        self.cause = cause
        self.order = 0
        self.isComplete = isComplete
        self.isDeleted = false
        self.created_at = created_at
        self.updated_at = Date()
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
