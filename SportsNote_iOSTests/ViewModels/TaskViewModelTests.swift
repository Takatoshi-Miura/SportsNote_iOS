//
//  TaskViewModelTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2025/11/23.
//

import Foundation
import Testing
import RealmSwift

@testable import SportsNote_iOS

@Suite("TaskViewModel Tests", .serialized)
@MainActor
struct TaskViewModelTests {
    
    init() async throws {
        RealmManager.shared.setupInMemoryRealm()
    }
    
    // MARK: - 初期化テスト
    
    @Test("初期化 - プロパティが正しく初期化される")
    func initialization_propertiesAreInitializedCorrectly() async {
        let viewModel = TaskViewModel()
        
        #expect(viewModel.tasks.isEmpty)
        #expect(viewModel.taskListData.isEmpty)
        #expect(viewModel.filteredTaskListData.isEmpty)
        #expect(viewModel.taskDetail == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.currentError == nil)
        #expect(viewModel.showingErrorAlert == false)
    }
    
    // MARK: - プロパティテスト
    
    @Test("プロパティ - tasksの設定と取得")
    func property_tasksSetAndGet() async {
        let viewModel = TaskViewModel()
        
        let testTask = TaskData(
            taskID: "task-1",
            title: "Test Task",
            cause: "Test Cause",
            groupID: "group-1",
            order: 0,
            isComplete: false,
            created_at: Date()
        )
        
        viewModel.tasks = [testTask]
        
        #expect(viewModel.tasks.count == 1)
        #expect(viewModel.tasks[0].title == "Test Task")
    }
    
    @Test("プロパティ - taskListDataの設定と取得")
    func property_taskListDataSetAndGet() async {
        let viewModel = TaskViewModel()
        
        let testTaskListData = TaskListData(
            taskID: "task-1",
            groupID: "group-1",
            groupColor: .red,
            title: "Test Task",
            measuresID: "measures-1",
            measures: "Test Measures",
            memoID: nil,
            order: 0,
            isComplete: false
        )
        
        viewModel.taskListData = [testTaskListData]
        
        #expect(viewModel.taskListData.count == 1)
        #expect(viewModel.taskListData[0].title == "Test Task")
    }
    
    // MARK: - isComplete フラグテスト
    
    @Test("isComplete - 完了状態の課題")
    func isComplete_completedTask() async {
        let task = TaskData(
            taskID: "task-1",
            title: "Completed Task",
            cause: "Cause",
            groupID: "group-1",
            order: 0,
            isComplete: true,
            created_at: Date()
        )
        
        #expect(task.isComplete == true)
    }
    
    @Test("isComplete - 未完了状態の課題")
    func isComplete_incompleteTask() async {
        let task = TaskData(
            taskID: "task-1",
            title: "Incomplete Task",
            cause: "Cause",
            groupID: "group-1",
            order: 0,
            isComplete: false,
            created_at: Date()
        )
        
        #expect(task.isComplete == false)
    }
    
    @Test("isComplete - 完了状態の切り替え")
    func isComplete_toggleState() async {
        let task = TaskData(
            taskID: "task-1",
            title: "Task",
            cause: "Cause",
            groupID: "group-1",
            order: 0,
            isComplete: false,
            created_at: Date()
        )
        
        #expect(task.isComplete == false)
        
        // 完了状態を切り替え
        let updatedTask = TaskData(
            taskID: task.taskID,
            title: task.title,
            cause: task.cause,
            groupID: task.groupID,
            order: task.order,
            isComplete: !task.isComplete,
            created_at: task.created_at
        )
        
        #expect(updatedTask.isComplete == true)
    }
    
    // MARK: - 通知処理テスト
    
    @Test("通知処理 - didClearAllData通知でクリアされる")
    func notification_clearsOnDidClearAllData() async {
        let viewModel = TaskViewModel()
        
        // データを追加
        let testTask = TaskData(
            taskID: "task-1",
            title: "Test",
            cause: "Cause",
            groupID: "group-1",
            order: 0,
            isComplete: false,
            created_at: Date()
        )
        viewModel.tasks = [testTask]
        
        #expect(!viewModel.tasks.isEmpty)
        
        // 通知を送信
        NotificationCenter.default.post(name: .didClearAllData, object: nil)
        
        // 非同期処理を待つ
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        #expect(viewModel.tasks.isEmpty)
        #expect(viewModel.taskListData.isEmpty)
        #expect(viewModel.filteredTaskListData.isEmpty)
        #expect(viewModel.taskDetail == nil)
    }
    
    // MARK: - 境界値テスト
    
    @Test("境界値 - 空のタイトル")
    func boundaryCase_emptyTitle() async {
        let task = TaskData(
            taskID: "task-1",
            title: "",
            cause: "Cause",
            groupID: "group-1",
            order: 0,
            isComplete: false,
            created_at: Date()
        )
        
        #expect(task.title == "")
    }
    
    @Test("境界値 - 空の原因")
    func boundaryCase_emptyCause() async {
        let task = TaskData(
            taskID: "task-1",
            title: "Task",
            cause: "",
            groupID: "group-1",
            order: 0,
            isComplete: false,
            created_at: Date()
        )
        
        #expect(task.cause == "")
    }
    
    @Test("境界値 - 非常に長いタイトル")
    func boundaryCase_veryLongTitle() async {
        let longTitle = String(repeating: "課題", count: 500)
        let task = TaskData(
            taskID: "task-1",
            title: longTitle,
            cause: "Cause",
            groupID: "group-1",
            order: 0,
            isComplete: false,
            created_at: Date()
        )
        
        #expect(task.title == longTitle)
        #expect(task.title.count == 1000)
    }
    
    @Test("境界値 - 特殊文字を含むタイトル",
          arguments: [
            "課題🎾",
            "Task\nWith\nNewlines",
            "Task & Special <> Characters"
          ])
    func boundaryCase_specialCharactersInTitle(title: String) async {
        let task = TaskData(
            taskID: "task-1",
            title: title,
            cause: "Cause",
            groupID: "group-1",
            order: 0,
            isComplete: false,
            created_at: Date()
        )
        
        #expect(task.title == title)
    }
    
    @Test("境界値 - 大量の課題", arguments: [10, 50, 100])
    func boundaryCase_largeTasksList(count: Int) async {
        let viewModel = TaskViewModel()
        
        var tasks: [TaskData] = []
        for i in 0..<count {
            let task = TaskData(
                taskID: "task-\(i)",
                title: "Task \(i)",
                cause: "Cause \(i)",
                groupID: "group-1",
                order: i,
                isComplete: false,
                created_at: Date()
            )
            tasks.append(task)
        }
        
        viewModel.tasks = tasks
        
        #expect(viewModel.tasks.count == count)
    }
    
    // MARK: - order値テスト
    
    @Test("order値 - 異なるorder値", arguments: [0, 1, 10, 100, 999])
    func orderValue_differentOrders(order: Int) async {
        let task = TaskData(
            taskID: "task-1",
            title: "Task",
            cause: "Cause",
            groupID: "group-1",
            order: order,
            isComplete: false,
            created_at: Date()
        )
        
        #expect(task.order == order)
    }
    
    @Test("order値 - 負のorder値")
    func orderValue_negativeOrder() async {
        let task = TaskData(
            taskID: "task-1",
            title: "Task",
            cause: "Cause",
            groupID: "group-1",
            order: -1,
            isComplete: false,
            created_at: Date()
        )
        
        #expect(task.order == -1)
    }
    
    // MARK: - 複数groupIDテスト
    
    @Test("複数groupID - 異なるgroupIDを持つ課題")
    func multipleGroupIds_differentGroupIds() async {
        let viewModel = TaskViewModel()
        
        let task1 = TaskData(
            taskID: "task-1",
            title: "Task 1",
            cause: "Cause 1",
            groupID: "group-1",
            order: 0,
            isComplete: false,
            created_at: Date()
        )
        
        let task2 = TaskData(
            taskID: "task-2",
            title: "Task 2",
            cause: "Cause 2",
            groupID: "group-2",
            order: 0,
            isComplete: false,
            created_at: Date()
        )
        
        viewModel.tasks = [task1, task2]
        
        #expect(viewModel.tasks.count == 2)
        #expect(viewModel.tasks[0].groupID == "group-1")
        #expect(viewModel.tasks[1].groupID == "group-2")
    }
    
    @Test("複数groupID - 同じgroupIDを持つ複数の課題")
    func multipleGroupIds_sameGroupId() async {
        let viewModel = TaskViewModel()
        
        let tasks = (0..<5).map { i in
            TaskData(
                taskID: "task-\(i)",
                title: "Task \(i)",
                cause: "Cause \(i)",
                groupID: "group-1",
                order: i,
                isComplete: false,
                created_at: Date()
            )
        }
        
        viewModel.tasks = tasks
        
        #expect(viewModel.tasks.count == 5)
        #expect(viewModel.tasks.allSatisfy { $0.groupID == "group-1" })
    }
    
    // MARK: - TaskListData構造体テスト
    
    @Test("TaskListData構造体 - プロパティが正しく設定される")
    func taskListDataStruct_propertiesSetCorrectly() async {
        let taskListData = TaskListData(
            taskID: "task-1",
            groupID: "group-1",
            groupColor: .red,
            title: "Test Task",
            measuresID: "measures-1",
            measures: "Test Measures",
            memoID: nil,
            order: 0,
            isComplete: false
        )
        
        #expect(taskListData.taskID == "task-1")
        #expect(taskListData.title == "Test Task")
        #expect(taskListData.groupID == "group-1")
        #expect(taskListData.groupColor == .red)
        #expect(taskListData.isComplete == false)
        #expect(taskListData.measures == "Test Measures")
    }
    
    @Test("TaskListData構造体 - measuresを含む")
    func taskListDataStruct_withMeasures() async {
        let taskListData = TaskListData(
            taskID: "task-1",
            groupID: "group-1",
            groupColor: .red,
            title: "Test Task",
            measuresID: "m1",
            measures: "Measure 1, Measure 2",
            memoID: nil,
            order: 0,
            isComplete: false
        )
        
        #expect(taskListData.measures == "Measure 1, Measure 2")
    }
    
    // MARK: - エラーハンドリングテスト
    
    @Test("エラーハンドリング - isLoadingの初期状態")
    func errorHandling_isLoadingInitialState() async {
        let viewModel = TaskViewModel()
        #expect(viewModel.isLoading == false)
    }
    
    @Test("エラーハンドリング - currentErrorの初期状態")
    func errorHandling_currentErrorInitialState() async {
        let viewModel = TaskViewModel()
        #expect(viewModel.currentError == nil)
    }
    
    @Test("エラーハンドリング - showingErrorAlertの初期状態")
    func errorHandling_showingErrorAlertInitialState() async {
        let viewModel = TaskViewModel()
        #expect(viewModel.showingErrorAlert == false)
    }
    
    // MARK: - 日付テスト
    
    @Test("日付 - 異なる作成日時")
    func date_differentCreatedDates() async {
        let date1 = Date()
        let date2 = Date().addingTimeInterval(-86400) // 1日前
        
        let task1 = TaskData(
            taskID: "task-1",
            title: "Task 1",
            cause: "Cause 1",
            groupID: "group-1",
            order: 0,
            isComplete: false,
            created_at: date1
        )
        
        let task2 = TaskData(
            taskID: "task-2",
            title: "Task 2",
            cause: "Cause 2",
            groupID: "group-1",
            order: 1,
            isComplete: false,
            created_at: date2
        )
        
        #expect(task1.created_at.timeIntervalSince1970 > task2.created_at.timeIntervalSince1970)
    }
    
    // MARK: - フィルタリングテスト
    
    @Test("フィルタリング - filteredTaskListDataの設定")
    func filtering_setFilteredTaskListData() async {
        let viewModel = TaskViewModel()
        
        let allTasks = (0..<10).map { i in
            TaskListData(
                taskID: "task-\(i)",
                groupID: i < 5 ? "group-1" : "group-2",
                groupColor: .red,
                title: "Task \(i)",
                measuresID: "measures-\(i)",
                measures: "Measures \(i)",
                memoID: nil,
                order: i,
                isComplete: false
            )
        }
        
        viewModel.taskListData = allTasks
        
        // group-1のみをフィルタ
        let filtered = allTasks.filter { $0.groupID == "group-1" }
        viewModel.filteredTaskListData = filtered
        
        #expect(viewModel.filteredTaskListData.count == 5)
        #expect(viewModel.filteredTaskListData.allSatisfy { $0.groupID == "group-1" })
    }
    
    // MARK: - 完了/未完了の混在テスト
    
    @Test("完了/未完了 - 混在する課題リスト")
    func completionMix_mixedCompletionStatus() async {
        let viewModel = TaskViewModel()
        
        let tasks = (0..<10).map { i in
            TaskData(
                taskID: "task-\(i)",
                title: "Task \(i)",
                cause: "Cause \(i)",
                groupID: "group-1",
                order: i,
                isComplete: i % 2 == 0, // 偶数番号は完了
                created_at: Date()
            )
        }
        
        viewModel.tasks = tasks
        
        let completedCount = viewModel.tasks.filter { $0.isComplete }.count
        let incompleteCount = viewModel.tasks.filter { !$0.isComplete }.count
        
        #expect(completedCount == 5)
        #expect(incompleteCount == 5)
    }
    
    // MARK: - CRUD操作テスト
    
    @Test("fetchData - データを取得できる")
    func fetchData_retrievesData() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let task1 = TaskData(taskID: "t1", title: "Task 1", cause: "Cause 1", groupID: "g1", order: 0, isComplete: false, created_at: Date())
        let task2 = TaskData(taskID: "t2", title: "Task 2", cause: "Cause 2", groupID: "g1", order: 1, isComplete: false, created_at: Date())
        try? manager.saveItem(task1)
        try? manager.saveItem(task2)
        
        _ = await viewModel.fetchData()
        
        #expect(viewModel.tasks.count == 2)
        
        manager.clearAll()
    }
    
    @Test("save - 新規課題を保存できる")
    func save_savesNewTask() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let task = TaskData(taskID: "new-task", title: "New Task", cause: "Cause", groupID: "g1", order: 0, isComplete: false, created_at: Date())
        
        let result = await viewModel.save(task)
        
        if case .failure = result {
            Issue.record("Save failed")
        }
        
        #expect(viewModel.tasks.count == 1)
        
        manager.clearAll()
    }
    
    @Test("delete - 課題を削除できる")
    func delete_deletesTask() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let task = TaskData(taskID: "t1", title: "Task", cause: "Cause", groupID: "g1", order: 0, isComplete: false, created_at: Date())
        try? manager.saveItem(task)
        
        _ = await viewModel.fetchData()
        #expect(viewModel.tasks.count == 1)
        
        let result = await viewModel.delete(id: "t1")
        
        if case .failure = result {
            Issue.record("Delete failed")
        }
        
        #expect(viewModel.tasks.isEmpty)
        
        manager.clearAll()
    }
    
    // MARK: - TaskViewModel特有機能テスト
    
    @Test("toggleTaskCompletion - 課題の完了状態を切り替えられる")
    func toggleTaskCompletion_togglesCompletion() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let task = TaskData(taskID: "t1", title: "Task", cause: "Cause", groupID: "g1", order: 0, isComplete: false, created_at: Date())
        try? manager.saveItem(task)
        
        _ = await viewModel.fetchData()
        #expect(viewModel.tasks.first?.isComplete == false)
        
        _ = await viewModel.toggleTaskCompletion(taskID: "t1")
        
        #expect(viewModel.tasks.first?.isComplete == true)
        
        manager.clearAll()
    }
    
    @Test("fetchTasksByGroupID - グループIDでフィルタリングできる")
    func fetchTasksByGroupID_filtersTasksByGroupID() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let task1 = TaskData(taskID: "t1", title: "Task 1", cause: "Cause 1", groupID: "g1", order: 0, isComplete: false, created_at: Date())
        let task2 = TaskData(taskID: "t2", title: "Task 2", cause: "Cause 2", groupID: "g1", order: 1, isComplete: false, created_at: Date())
        let task3 = TaskData(taskID: "t3", title: "Task 3", cause: "Cause 3", groupID: "g2", order: 0, isComplete: false, created_at: Date())
        try? manager.saveItem(task1)
        try? manager.saveItem(task2)
        try? manager.saveItem(task3)
        
        _ = await viewModel.fetchTasksByGroupID(groupID: "g1")
        
        #expect(viewModel.tasks.count == 2)
        #expect(viewModel.tasks.allSatisfy { $0.groupID == "g1" })
        
        manager.clearAll()
    }
    
    @Test("updateTask - 既存課題を更新できる")
    func updateTask_updatesExistingTask() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let task = TaskData(taskID: "t1", title: "Original", cause: "Original Cause", groupID: "g1", order: 0, isComplete: false, created_at: Date())
        try? manager.saveItem(task)
        
        _ = await viewModel.updateTask(taskID: "t1", title: "Updated", cause: "Updated Cause", groupID: "g1")
        
        let updatedTask = try? manager.getObjectById(id: "t1", type: TaskData.self)
        #expect(updatedTask?.title == "Updated")
        #expect(updatedTask?.cause == "Updated Cause")
        
        manager.clearAll()
    }
    
    @Test("saveNewTaskWithMeasures - 課題と対策を同時に保存できる")
    func saveNewTaskWithMeasures_savesTaskAndMeasures() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let result = await viewModel.saveNewTaskWithMeasures(
            title: "New Task",
            cause: "Cause",
            groupID: "g1",
            measuresTitle: "Measure 1"
        )
        
        if case .success(let task) = result {
            #expect(task.title == "New Task")
            
            // 対策が保存されているか確認
            let measures = manager.getMeasuresByTaskID(taskID: task.taskID)
            #expect(measures.count == 1)
            #expect(measures.first?.title == "Measure 1")
        } else {
            Issue.record("SaveNewTaskWithMeasures failed")
        }
        
        manager.clearAll()
    }
    
    @Test("showCompletedTasks - 完了タスクの表示切り替えができる")
    func showCompletedTasks_togglesFilteredTasks() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let task1 = TaskData(taskID: "t1", title: "Task 1", cause: "Cause 1", groupID: "g1", order: 0, isComplete: false, created_at: Date())
        let task2 = TaskData(taskID: "t2", title: "Task 2", cause: "Cause 2", groupID: "g1", order: 1, isComplete: true, created_at: Date())
        try? manager.saveItem(task1)
        try? manager.saveItem(task2)
        
        _ = await viewModel.fetchData()
        
        // デフォルトは完了タスクを非表示
        #expect(viewModel.showCompletedTasks == false)
        #expect(viewModel.filteredTaskListData.count == 1)
        
        // 完了タスクを表示
        viewModel.showCompletedTasks = true
        #expect(viewModel.filteredTaskListData.count == 2)
        
        manager.clearAll()
    }
}

// MARK: - テストヘルパー拡張

extension TaskViewModelTests {
    
    /// テスト用のTaskDataを作成
    static func createTestTask(
        id: String = "task-1",
        title: String = "Test Task",
        cause: String = "Test Cause",
        groupID: String = "group-1",
        order: Int = 0,
        isComplete: Bool = false
    ) -> TaskData {
        return TaskData(
            taskID: id,
            title: title,
            cause: cause,
            groupID: groupID,
            order: order,
            isComplete: isComplete,
            created_at: Date()
        )
    }
    
    /// テスト用のTaskListDataを作成
    static func createTestTaskListData(
        id: String = "task-1",
        title: String = "Test Task",
        groupID: String = "group-1",
        groupColor: GroupColor = .red,
        measuresID: String = "measures-1",
        measures: String = "Test Measures",
        isComplete: Bool = false,
        order: Int = 0
    ) -> TaskListData {
        return TaskListData(
            taskID: id,
            groupID: groupID,
            groupColor: groupColor,
            title: title,
            measuresID: measuresID,
            measures: measures,
            memoID: nil,
            order: order,
            isComplete: isComplete
        )
    }
    
    /// 複数のテストTaskDataを作成
    static func createTestTasks(count: Int, groupID: String = "group-1") -> [TaskData] {
        return (0..<count).map { i in
            createTestTask(
                id: "task-\(i)",
                title: "Task \(i)",
                cause: "Cause \(i)",
                groupID: groupID,
                order: i,
                isComplete: false
            )
        }
    }
}
