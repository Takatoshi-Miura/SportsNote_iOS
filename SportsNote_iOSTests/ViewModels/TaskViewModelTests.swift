//
//  TaskViewModelTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2025/11/23.
//

import Foundation
import RealmSwift
import Testing

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
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

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

    @Test(
        "境界値 - 特殊文字を含むタイトル",
        arguments: [
            "課題🎾",
            "Task\nWith\nNewlines",
            "Task & Special <> Characters",
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

        let tasks = (0..<5)
            .map { i in
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

    // MARK: - associateTasksWithMemosテスト（issue #65）

    @Test("associateTasksWithMemos - measuresIDが一致する課題とメモがペアになる")
    func associateTasksWithMemos_matchesTaskByMeasuresID() async {
        let viewModel = TaskViewModel()
        let task = TaskListData(
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
        viewModel.taskListData = [task]

        let memo = Memo(
            memoID: "memo-1",
            measuresID: "measures-1",
            noteID: "note-1",
            detail: "振り返り内容",
            created_at: Date()
        )

        let pairs = viewModel.associateTasksWithMemos(memos: [memo])

        #expect(pairs.count == 1)
        #expect(pairs.first?.task.taskID == "task-1")
        #expect(pairs.first?.memo.memoID == "memo-1")
        #expect(pairs.first?.memo.detail == "振り返り内容")
    }

    @Test("associateTasksWithMemos - measuresIDが一致しない場合はペアに含まれない")
    func associateTasksWithMemos_noMatchIsExcluded() async {
        let viewModel = TaskViewModel()
        let task = TaskListData(
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
        viewModel.taskListData = [task]

        let memo = Memo(
            memoID: "memo-1",
            measuresID: "measures-unmatched",
            noteID: "note-1",
            detail: "振り返り内容",
            created_at: Date()
        )

        let pairs = viewModel.associateTasksWithMemos(memos: [memo])

        #expect(pairs.isEmpty)
    }

    @Test("associateTasksWithMemos - 同一課題に複数メモが一致する場合はtaskIDで重複排除される")
    func associateTasksWithMemos_dedupesBySameTaskID() async {
        let viewModel = TaskViewModel()
        let task = TaskListData(
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
        viewModel.taskListData = [task]

        let memo1 = Memo(
            memoID: "memo-1",
            measuresID: "measures-1",
            noteID: "note-1",
            detail: "1件目",
            created_at: Date()
        )
        let memo2 = Memo(
            memoID: "memo-2",
            measuresID: "measures-1",
            noteID: "note-1",
            detail: "2件目",
            created_at: Date()
        )

        let pairs = viewModel.associateTasksWithMemos(memos: [memo1, memo2])

        #expect(pairs.count == 1)
        #expect(pairs.first?.task.taskID == "task-1")
        // 重複排除は後勝ち（辞書の上書き）であることを固定化する（クロスレビュー指摘反映）
        #expect(pairs.first?.memo.memoID == "memo-2")
        #expect(pairs.first?.memo.detail == "2件目")
    }

    @Test("associateTasksWithMemos - 複数課題・複数メモで正しくペアが構築される")
    func associateTasksWithMemos_multipleTasksAndMemos() async {
        let viewModel = TaskViewModel()
        let task1 = TaskListData(
            taskID: "task-1",
            groupID: "group-1",
            groupColor: .red,
            title: "Task 1",
            measuresID: "measures-1",
            measures: "Measures 1",
            memoID: nil,
            order: 0,
            isComplete: false
        )
        let task2 = TaskListData(
            taskID: "task-2",
            groupID: "group-1",
            groupColor: .blue,
            title: "Task 2",
            measuresID: "measures-2",
            measures: "Measures 2",
            memoID: nil,
            order: 1,
            isComplete: false
        )
        viewModel.taskListData = [task1, task2]

        let memo1 = Memo(
            memoID: "memo-1",
            measuresID: "measures-1",
            noteID: "note-1",
            detail: "課題1の振り返り",
            created_at: Date()
        )
        let memo2 = Memo(
            memoID: "memo-2",
            measuresID: "measures-2",
            noteID: "note-1",
            detail: "課題2の振り返り",
            created_at: Date()
        )

        let pairs = viewModel.associateTasksWithMemos(memos: [memo1, memo2])

        #expect(pairs.count == 2)
        #expect(Set(pairs.map { $0.task.taskID }) == Set(["task-1", "task-2"]))
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
        let date2 = Date().addingTimeInterval(-86400)  // 1日前

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

        let allTasks = (0..<10)
            .map { i in
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

    // MARK: - 未追加課題取得テスト（issue #86: getUnaddedTasksの重複解消）

    @Test("未追加課題取得 - taskReflectionsに含まれる課題を除外する")
    func getUnaddedTasks_excludesTasksInTaskReflections() async {
        let viewModel = TaskViewModel()

        let allTasks = (0..<3)
            .map { i in
                TaskListData(
                    taskID: "task-\(i)",
                    groupID: "group-1",
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

        // task-0のみをtaskReflectionsに追加済みとする
        let taskReflections: [TaskListData: String] = [allTasks[0]: "感想"]

        let unaddedTasks = viewModel.getUnaddedTasks(taskReflections: taskReflections)

        #expect(unaddedTasks.count == 2)
        #expect(!unaddedTasks.contains { $0.taskID == "task-0" })
        #expect(unaddedTasks.contains { $0.taskID == "task-1" })
        #expect(unaddedTasks.contains { $0.taskID == "task-2" })
    }

    @Test("未追加課題取得 - excludingTaskIds版と同じ結果になる")
    func getUnaddedTasks_matchesExcludingTaskIdsOverload() async {
        let viewModel = TaskViewModel()

        let allTasks = (0..<4)
            .map { i in
                TaskListData(
                    taskID: "task-\(i)",
                    groupID: "group-1",
                    groupColor: .red,
                    title: "Task \(i)",
                    measuresID: "measures-\(i)",
                    measures: "Measures \(i)",
                    memoID: nil,
                    order: i,
                    isComplete: i == 3  // task-3は完了済み
                )
            }
        viewModel.taskListData = allTasks

        let taskReflections: [TaskListData: String] = [allTasks[1]: "感想"]
        let excludingTaskIds: Set<String> = ["task-1"]

        let resultFromTaskReflections = viewModel.getUnaddedTasks(taskReflections: taskReflections)
        let resultFromExcludingIds = viewModel.getUnaddedTasks(excludingTaskIds: excludingTaskIds)

        #expect(Set(resultFromTaskReflections.map { $0.taskID }) == Set(resultFromExcludingIds.map { $0.taskID }))
        #expect(!resultFromTaskReflections.contains { $0.taskID == "task-3" })  // 完了済みは除外
    }

    // MARK: - 完了/未完了の混在テスト

    @Test("完了/未完了 - 混在する課題リスト")
    func completionMix_mixedCompletionStatus() async {
        let viewModel = TaskViewModel()

        let tasks = (0..<10)
            .map { i in
                TaskData(
                    taskID: "task-\(i)",
                    title: "Task \(i)",
                    cause: "Cause \(i)",
                    groupID: "group-1",
                    order: i,
                    isComplete: i % 2 == 0,  // 偶数番号は完了
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

        let task1 = TaskData(
            taskID: "t1", title: "Task 1", cause: "Cause 1", groupID: "g1", order: 0, isComplete: false,
            created_at: Date())
        let task2 = TaskData(
            taskID: "t2", title: "Task 2", cause: "Cause 2", groupID: "g1", order: 1, isComplete: false,
            created_at: Date())
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

        let task = TaskData(
            taskID: "new-task", title: "New Task", cause: "Cause", groupID: "g1", order: 0, isComplete: false,
            created_at: Date())

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

        let task = TaskData(
            taskID: "t1", title: "Task", cause: "Cause", groupID: "g1", order: 0, isComplete: false, created_at: Date())
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

        let task = TaskData(
            taskID: "t1", title: "Task", cause: "Cause", groupID: "g1", order: 0, isComplete: false, created_at: Date())
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

        let task1 = TaskData(
            taskID: "t1", title: "Task 1", cause: "Cause 1", groupID: "g1", order: 0, isComplete: false,
            created_at: Date())
        let task2 = TaskData(
            taskID: "t2", title: "Task 2", cause: "Cause 2", groupID: "g1", order: 1, isComplete: false,
            created_at: Date())
        let task3 = TaskData(
            taskID: "t3", title: "Task 3", cause: "Cause 3", groupID: "g2", order: 0, isComplete: false,
            created_at: Date())
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

        let task = TaskData(
            taskID: "t1", title: "Original", cause: "Original Cause", groupID: "g1", order: 0, isComplete: false,
            created_at: Date())
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

    // MARK: - order値回帰テスト（issue #21: 削除後の新規追加でorderが逆転する不具合）

    @Test("saveNewTaskWithMeasures - 削除後に新規追加すると末尾のorderになる（未削除件数ベースでは逆転してしまう回帰確認）")
    func saveNewTaskWithMeasures_afterDeletion_newTaskGetsMaxOrderPlusOne() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        // groupID "g1" に order 0〜4 の課題5件を作成
        for i in 0..<5 {
            let task = TaskData(
                taskID: "t-\(i)", title: "Task \(i)", cause: "Cause \(i)", groupID: "g1", order: i, isComplete: false,
                created_at: Date())
            try? manager.saveItem(task)
        }

        // 先頭4件（order 0〜3）を論理削除。残るのはorder=4の1件のみ
        for i in 0..<4 {
            try? manager.logicalDelete(id: "t-\(i)", type: TaskData.self)
        }

        // 新規課題を追加
        let result = await viewModel.saveNewTaskWithMeasures(title: "New Task", cause: "New Cause", groupID: "g1")

        guard case .success(let newTask) = result else {
            Issue.record("saveNewTaskWithMeasures failed")
            manager.clearAll()
            return
        }

        // 未削除件数ベース（旧ロジック）なら1になり、残存するorder=4の課題より前に表示されてしまう
        // 最大order+1ベースなら5になり、末尾（最新）に表示される
        #expect(newTask.order == 5)

        manager.clearAll()
    }

    @Test("saveNewTaskWithMeasures - 別グループの削除件数は新規課題のorderに影響しない")
    func saveNewTaskWithMeasures_differentGroupDeletion_doesNotAffectOrder() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        // groupID "gA" に課題3件を作成し、全て削除
        for i in 0..<3 {
            let task = TaskData(
                taskID: "a-\(i)", title: "A \(i)", cause: "Cause", groupID: "gA", order: i, isComplete: false,
                created_at: Date())
            try? manager.saveItem(task)
        }
        for i in 0..<3 {
            try? manager.logicalDelete(id: "a-\(i)", type: TaskData.self)
        }

        // groupID "gB" に課題1件（order=0）を作成
        let bTask = TaskData(
            taskID: "b-0", title: "B 0", cause: "Cause", groupID: "gB", order: 0, isComplete: false, created_at: Date())
        try? manager.saveItem(bTask)

        // gBに新規課題を追加。gAの削除件数（3件）に影響されず、gB内の最大order+1（1）になるべき
        let result = await viewModel.saveNewTaskWithMeasures(title: "New B Task", cause: "Cause", groupID: "gB")

        guard case .success(let newTask) = result else {
            Issue.record("saveNewTaskWithMeasures failed")
            manager.clearAll()
            return
        }

        #expect(newTask.order == 1)

        manager.clearAll()
    }

    @Test("showCompletedTasks - 完了タスクの表示切り替えができる")
    func showCompletedTasks_togglesFilteredTasks() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        let task1 = TaskData(
            taskID: "t1", title: "Task 1", cause: "Cause 1", groupID: "g1", order: 0, isComplete: false,
            created_at: Date())
        let task2 = TaskData(
            taskID: "t2", title: "Task 2", cause: "Cause 2", groupID: "g1", order: 1, isComplete: true,
            created_at: Date())
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
        return (0..<count)
            .map { i in
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
