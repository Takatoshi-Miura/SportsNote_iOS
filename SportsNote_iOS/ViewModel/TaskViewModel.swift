import Foundation
import SwiftUI
import RealmSwift

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskData] = []
    @Published var taskDetail: TaskDetailData?
    
    init() {
        fetchAllTasks()
    }
    
    // MARK: - Tasks
    
    /// 全ての課題を取得
    func fetchAllTasks() {
        tasks = RealmManager.shared.getDataList(clazz: TaskData.self)
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
        } catch {
            print("Error fetching tasks by group ID: \(error)")
            tasks = []
        }
    }
    
    /// 課題を保存
    /// - Parameters:
    ///   - title: 課題タイトル
    ///   - cause: 原因
    ///   - groupID: グループID
    ///   - isComplete: 完了状態
    ///   - order: 表示順序
    func saveTask(title: String, cause: String, groupID: String, isComplete: Bool = false, order: Int? = nil) {
        // Calculate order if not provided
        let newOrder = order ?? RealmManager.shared.getCount(clazz: TaskData.self)
        
        // Create task
        let task = TaskData(
            title: title,
            cause: cause,
            groupID: groupID,
            isComplete: isComplete
        )
        task.order = newOrder
        
        // Save to Realm
        RealmManager.shared.saveItem(task)
        
        // Refresh task list
        fetchAllTasks()
    }
    
    /// 課題の完了状態を切り替え
    /// - Parameter task: 対象の課題
    func toggleTaskCompletion(task: TaskData) {
        do {
            let realm = try Realm()
            if let taskToUpdate = realm.object(ofType: TaskData.self, forPrimaryKey: task.taskID) {
                try realm.write {
                    taskToUpdate.isComplete = !taskToUpdate.isComplete
                    taskToUpdate.updated_at = Date()
                }
                
                // Update the local task list
                if let index = tasks.firstIndex(where: { $0.taskID == task.taskID }) {
                    tasks[index].isComplete = !tasks[index].isComplete
                    self.objectWillChange.send()
                }
            }
        } catch {
            print("Error toggling task completion: \(error)")
        }
    }
    
    /// 課題を削除
    /// - Parameter id: 課題ID
    func deleteTask(id: String) {
        RealmManager.shared.logicalDelete(id: id, type: TaskData.self)
        
        // Update task list by removing the deleted task
        tasks.removeAll(where: { $0.taskID == id })
        self.objectWillChange.send()
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
}