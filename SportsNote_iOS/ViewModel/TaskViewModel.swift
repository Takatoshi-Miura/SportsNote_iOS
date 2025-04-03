import Foundation
import SwiftUI
import RealmSwift
import Combine

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskData] = []
    @Published var taskListData: [TaskListData] = []
    @Published var taskDetail: TaskDetailData?
    
    // タスク更新通知パブリッシャー
    let taskUpdatedPublisher = PassthroughSubject<Void, Never>()
    
    init() {
        fetchAllTasks()
    }
    
    // MARK: - Tasks
    
    /// 全ての課題を取得
    func fetchAllTasks() {
        tasks = RealmManager.shared.getDataList(clazz: TaskData.self)
        convertToTaskListData()
    }
    
    /// 指定したグループIDの課題を取得
    /// - Parameter groupID: グループID
    func fetchTasksByGroupID(groupID: String) {
        do {
            let realm = try Realm()
            tasks = realm.objects(TaskData.self)
                .filter("groupID == %@ AND isDeleted == false", groupID)
                .sorted(byKeyPath: "order", ascending: true)
                .map { $0 }
            convertToTaskListData()
        } catch {
            print("Error fetching tasks by group ID: \(error)")
            tasks = []
            taskListData = []
        }
    }
    
    /// TaskDataをTaskListDataに変換する
    private func convertToTaskListData() {
        var taskList = [TaskListData]()
        
        for task in tasks {
            // グループカラーを取得
            let groupColor = getGroupColor(groupID: task.groupID)
            
            // 対策情報を取得
            let measures = getMostPriorityMeasures(taskID: task.taskID)
            
            // TaskListDataを作成
            let taskListItem = TaskListData(
                taskID: task.taskID,
                groupID: task.groupID,
                groupColor: groupColor,
                title: task.title,
                measuresID: measures?.measuresID ?? "",
                measures: measures?.title ?? "未設定",
                memoID: nil,
                order: task.order,
                isComplete: task.isComplete
            )
            taskList.append(taskListItem)
        }
        
        taskListData = taskList
    }
    
    /// グループIDに基づいて色を取得
    /// - Parameter groupID: グループID
    /// - Returns: GroupColorの列挙型
    private func getGroupColor(groupID: String) -> GroupColor {
        if let group = RealmManager.shared.getObjectById(id: groupID, type: Group.self) {
            return GroupColor.allCases[Int(group.color)]
        }
        return GroupColor.gray // デフォルトはグレー
    }
    
    /// 最も優先度の高い（orderが低い）対策を取得
    /// - Parameter taskID: 課題ID
    /// - Returns: 対策オブジェクト（存在しない場合はnil）
    private func getMostPriorityMeasures(taskID: String) -> Measures? {
        let measuresList = RealmManager.shared.getMeasuresByTaskID(taskID: taskID)
        return measuresList.min { $0.order < $1.order }
    }
    
    /// 課題保存処理(更新も兼ねる)
    /// - Parameters:
    ///   - taskID: 課題ID（新規作成時はnil）
    ///   - title: 課題タイトル
    ///   - cause: 原因
    ///   - groupID: グループID
    ///   - isComplete: 完了状態
    ///   - order: 表示順序（指定がない場合は自動計算）
    ///   - created_at: 作成日時（指定がない場合は現在時刻）
    func saveTask(
        taskID: String? = nil,
        title: String,
        cause: String,
        groupID: String,
        isComplete: Bool = false,
        order: Int? = nil,
        created_at: Date? = nil
    ) {
        let newTaskID = taskID ?? UUID().uuidString
        let newOrder = order ?? RealmManager.shared.getCount(clazz: TaskData.self)
        let newCreatedAt = created_at ?? Date()
        
        // Create task
        let task = TaskData(
            title: title,
            cause: cause,
            groupID: groupID,
            isComplete: isComplete
        )
        task.taskID = newTaskID
        task.order = newOrder
        task.created_at = newCreatedAt
        
        // Save to Realm
        RealmManager.shared.saveItem(task)
        
        // TODO: Firebaseへの同期
        
        // Refresh task list
        fetchAllTasks()
        
        // タスク詳細情報を表示している場合は、詳細情報も更新
        if let detail = taskDetail, detail.task.taskID == newTaskID {
            fetchTaskDetail(taskID: newTaskID)
        }
        
        // タスク更新通知を送信
        taskUpdatedPublisher.send()
    }
    
    /// 課題の完了状態を切り替え
    /// - Parameter taskID: 課題ID
    func toggleTaskCompletion(taskID: String) {
        if let taskToUpdate = RealmManager.shared.getObjectById(id: taskID, type: TaskData.self) {
            let updatedTask = TaskData(
                title: taskToUpdate.title,
                cause: taskToUpdate.cause,
                groupID: taskToUpdate.groupID,
                isComplete: !taskToUpdate.isComplete
            )
            updatedTask.taskID = taskToUpdate.taskID
            updatedTask.order = taskToUpdate.order
            updatedTask.created_at = taskToUpdate.created_at
            
            // Save to Realm
            RealmManager.shared.saveItem(updatedTask)
            
            // Fetch the updated task from Realm to refresh local data
            fetchAllTasks() // これにより tasks と taskListData が更新される
            
            // タスク詳細情報を表示している場合は、詳細情報も更新
            if let detail = taskDetail, detail.task.taskID == taskID {
                fetchTaskDetail(taskID: taskID)
            }
            
            // タスク更新通知を送信
            taskUpdatedPublisher.send()
        }
    }
    
    /// 課題を削除
    /// - Parameter id: 課題ID
    func deleteTask(id: String) {
        RealmManager.shared.logicalDelete(id: id, type: TaskData.self)
        
        // Update task list by removing the deleted task
        tasks.removeAll(where: { $0.taskID == id })
        taskListData.removeAll(where: { $0.taskID == id })
        self.objectWillChange.send()
        
        // タスク更新通知を送信
        taskUpdatedPublisher.send()
    }
    
    /// タスク一覧を更新する（外部からの呼び出し用）
    func refreshTasks() {
        fetchAllTasks()
    }
    
    // MARK: - Task Detail
    
    /// 課題の詳細情報を取得
    /// - Parameter taskID: 課題ID
    func fetchTaskDetail(taskID: String) {
        if let task = RealmManager.shared.getObjectById(id: taskID, type: TaskData.self) {
            let measures = RealmManager.shared.getMeasuresByTaskID(taskID: taskID)
            taskDetail = TaskDetailData(task: task, measuresList: measures)
        } else {
            taskDetail = nil
        }
    }
    
    // MARK: - Measures
    
    /// 対策を追加
    /// - Parameters:
    ///   - title: 対策タイトル
    ///   - taskID: 対象の課題ID
    ///   - order: 表示順序
    func addMeasure(title: String, taskID: String, order: Int? = nil) {
        // Calculate order if not provided
        let newOrder = order ?? RealmManager.shared.getMeasuresByTaskID(taskID: taskID).count
        
        // Create measures
        let measures = Measures(
            taskID: taskID,
            title: title,
            order: newOrder
        )
        
        // Save to Realm
        RealmManager.shared.saveItem(measures)
        
        // Update task detail if viewing
        if let detail = taskDetail, detail.task.taskID == taskID {
            fetchTaskDetail(taskID: taskID)
        }
    }
    
    /// 対策を削除
    /// - Parameter measuresID: 対策ID
    func deleteMeasure(measuresID: String) {
        do {
            let realm = try Realm()
            if let measure = realm.object(ofType: Measures.self, forPrimaryKey: measuresID) {
                let taskID = measure.taskID
                
                // Delete measure
                RealmManager.shared.logicalDelete(id: measuresID, type: Measures.self)
                
                // Update task detail if viewing
                if let detail = taskDetail, detail.task.taskID == taskID {
                    fetchTaskDetail(taskID: taskID)
                }
            }
        } catch {
            print("Error deleting measure: \(error)")
        }
    }
    
    /// 対策の並び順を更新
    /// - Parameter measures: 並び替え後の対策リスト
    func updateMeasuresOrder(measures: [Measures]) {
        guard !measures.isEmpty else { return }
        
        do {
            let realm = try Realm()
            try realm.write {
                // 各対策のorderプロパティを更新
                for (index, measure) in measures.enumerated() {
                    if let measureToUpdate = realm.object(ofType: Measures.self, forPrimaryKey: measure.measuresID) {
                        measureToUpdate.order = index
                        measureToUpdate.updated_at = Date()
                    }
                }
            }
            
            // 対策の並び替えが完了したら、詳細画面を更新
            if let detail = taskDetail {
                fetchTaskDetail(taskID: detail.task.taskID)
            }
        } catch {
            print("Error updating measures order: \(error)")
        }
    }
}
