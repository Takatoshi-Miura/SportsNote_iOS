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

    @Test("associateTasksWithMemos - measuresIDが指す対策のtaskIDで課題とメモがペアになる")
    func associateTasksWithMemos_matchesTaskByMeasuresID() async {
        let manager = RealmManager.shared
        manager.clearAll()

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

        try? manager.saveItem(
            Measures(measuresID: "measures-1", taskID: "task-1", title: "Test Measures", order: 0, created_at: Date())
        )

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

        manager.clearAll()
    }

    @Test("associateTasksWithMemos - measuresIDが指す対策のtaskIDがtaskListDataに存在しない場合はペアに含まれない")
    func associateTasksWithMemos_noMatchIsExcluded() async {
        let manager = RealmManager.shared
        manager.clearAll()

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

        // "measures-unmatched"はtask-1ではなく別課題(task-999)に属する対策
        try? manager.saveItem(
            Measures(
                measuresID: "measures-unmatched", taskID: "task-999", title: "Other", order: 0, created_at: Date())
        )

        let memo = Memo(
            memoID: "memo-1",
            measuresID: "measures-unmatched",
            noteID: "note-1",
            detail: "振り返り内容",
            created_at: Date()
        )

        let pairs = viewModel.associateTasksWithMemos(memos: [memo])

        #expect(pairs.isEmpty)

        manager.clearAll()
    }

    @Test("associateTasksWithMemos - 対策の並び替えでmeasuresIDが変わっても、taskIDで同一課題として突合される")
    func associateTasksWithMemos_matchesAfterMeasuresReorder() async {
        let manager = RealmManager.shared
        manager.clearAll()

        let viewModel = TaskViewModel()
        // taskListData.measuresIDは並び替え後の現在の最優先対策(measures-B)を指す
        let task = TaskListData(
            taskID: "task-1",
            groupID: "group-1",
            groupColor: .red,
            title: "Test Task",
            measuresID: "measures-b",
            measures: "Measures B",
            memoID: nil,
            order: 0,
            isComplete: false
        )
        viewModel.taskListData = [task]

        // Measures A・Bともtask-1に属する（並び替え後の優先度はB=0, A=1）
        try? manager.saveItem(
            Measures(measuresID: "measures-a", taskID: "task-1", title: "Measures A", order: 1, created_at: Date()))
        try? manager.saveItem(
            Measures(measuresID: "measures-b", taskID: "task-1", title: "Measures B", order: 0, created_at: Date()))

        // Memoは並び替え前の最優先対策(measures-a)に対して作成されたもの
        let memo = Memo(
            memoID: "memo-1",
            measuresID: "measures-a",
            noteID: "note-1",
            detail: "並び替え前の振り返り",
            created_at: Date()
        )

        let pairs = viewModel.associateTasksWithMemos(memos: [memo])

        #expect(pairs.count == 1)
        #expect(pairs.first?.task.taskID == "task-1")
        #expect(pairs.first?.memo.memoID == "memo-1")

        manager.clearAll()
    }

    @Test("associateTasksWithMemos - 同一課題に複数メモが一致する場合はtaskIDで重複排除される")
    func associateTasksWithMemos_dedupesBySameTaskID() async {
        let manager = RealmManager.shared
        manager.clearAll()

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

        try? manager.saveItem(
            Measures(measuresID: "measures-1", taskID: "task-1", title: "Test Measures", order: 0, created_at: Date())
        )

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

        manager.clearAll()
    }

    @Test("associateTasksWithMemos - 複数課題・複数メモで正しくペアが構築される")
    func associateTasksWithMemos_multipleTasksAndMemos() async {
        let manager = RealmManager.shared
        manager.clearAll()

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

        try? manager.saveItem(
            Measures(measuresID: "measures-1", taskID: "task-1", title: "Measures 1", order: 0, created_at: Date()))
        try? manager.saveItem(
            Measures(measuresID: "measures-2", taskID: "task-2", title: "Measures 2", order: 0, created_at: Date()))

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

        manager.clearAll()
    }

    @Test("associateTasksWithMemos - 戻り値がtask.order昇順にソートされる（issue #137: Dictionary列挙順への依存を排除）")
    func associateTasksWithMemos_sortsResultByTaskOrder() async {
        let manager = RealmManager.shared
        manager.clearAll()

        let viewModel = TaskViewModel()
        // orderが降順になるように課題を用意し、Dictionary経由でも意図した順序に
        // 並び替えられることを確認する
        let task1 = TaskListData(
            taskID: "task-1",
            groupID: "group-1",
            groupColor: .red,
            title: "Task 1",
            measuresID: "measures-1",
            measures: "Measures 1",
            memoID: nil,
            order: 2,
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
            order: 0,
            isComplete: false
        )
        let task3 = TaskListData(
            taskID: "task-3",
            groupID: "group-1",
            groupColor: .green,
            title: "Task 3",
            measuresID: "measures-3",
            measures: "Measures 3",
            memoID: nil,
            order: 1,
            isComplete: false
        )
        viewModel.taskListData = [task1, task2, task3]

        // associateTasksWithMemosはmemo.measuresIDに対応するMeasuresの実在確認を行うため、
        // Realmに保存しておく必要がある（issue #162: 未保存のため常に空配列になっていた不備の修正）
        try? manager.saveItem(
            Measures(measuresID: "measures-1", taskID: "task-1", title: "Measures 1", order: 2, created_at: Date()))
        try? manager.saveItem(
            Measures(measuresID: "measures-2", taskID: "task-2", title: "Measures 2", order: 0, created_at: Date()))
        try? manager.saveItem(
            Measures(measuresID: "measures-3", taskID: "task-3", title: "Measures 3", order: 1, created_at: Date()))

        let memo1 = Memo(
            memoID: "memo-1", measuresID: "measures-1", noteID: "note-1", detail: "1", created_at: Date())
        let memo2 = Memo(
            memoID: "memo-2", measuresID: "measures-2", noteID: "note-1", detail: "2", created_at: Date())
        let memo3 = Memo(
            memoID: "memo-3", measuresID: "measures-3", noteID: "note-1", detail: "3", created_at: Date())

        let pairs = viewModel.associateTasksWithMemos(memos: [memo1, memo2, memo3])

        #expect(pairs.map { $0.task.taskID } == ["task-2", "task-3", "task-1"])

        manager.clearAll()
    }

    @Test(
        "associateTasksWithMemos - orderが同値の課題はtaskID昇順でタイブレークされる（異なるグループの課題がorder同値になるケース）"
    )
    func associateTasksWithMemos_sameOrderTiesBreakByTaskID() async {
        let manager = RealmManager.shared
        manager.clearAll()

        let viewModel = TaskViewModel()
        // 異なるグループの課題はグループ内スコープでorderが採番されるため、
        // order=0同士が複数存在しうる
        let taskB = TaskListData(
            taskID: "task-b",
            groupID: "group-b",
            groupColor: .blue,
            title: "Task B",
            measuresID: "measures-b",
            measures: "Measures B",
            memoID: nil,
            order: 0,
            isComplete: false
        )
        let taskA = TaskListData(
            taskID: "task-a",
            groupID: "group-a",
            groupColor: .red,
            title: "Task A",
            measuresID: "measures-a",
            measures: "Measures A",
            memoID: nil,
            order: 0,
            isComplete: false
        )
        viewModel.taskListData = [taskB, taskA]

        // associateTasksWithMemosはmemo.measuresIDに対応するMeasuresの実在確認を行うため、
        // Realmに保存しておく必要がある（issue #162: 未保存のため常に空配列になっていた不備の修正）
        try? manager.saveItem(
            Measures(measuresID: "measures-b", taskID: "task-b", title: "Measures B", order: 0, created_at: Date()))
        try? manager.saveItem(
            Measures(measuresID: "measures-a", taskID: "task-a", title: "Measures A", order: 0, created_at: Date()))

        let memoB = Memo(
            memoID: "memo-b", measuresID: "measures-b", noteID: "note-1", detail: "B", created_at: Date())
        let memoA = Memo(
            memoID: "memo-a", measuresID: "measures-a", noteID: "note-1", detail: "A", created_at: Date())

        let pairs = viewModel.associateTasksWithMemos(memos: [memoB, memoA])

        #expect(pairs.map { $0.task.taskID } == ["task-a", "task-b"])

        manager.clearAll()
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

    @Test(
        "delete - performBackgroundSyncが直接呼ばれ、戻り値を返す前にBackgroundSyncTrackerへ登録される（issue #164回帰）"
    )
    func delete_registersBackgroundSyncTaskBeforeReturning() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        // 他テストの追跡Taskが残っていないことを保証
        await BackgroundSyncTracker.shared.waitForAll()

        let task = TaskData(
            taskID: "t1", title: "Task", cause: "Cause", groupID: "g1", order: 0, isComplete: false, created_at: Date())
        try? manager.saveItem(task)
        _ = await viewModel.fetchData()

        _ = await viewModel.delete(id: "t1")

        // delete(id:)から戻った直後（追加のawait/yieldを挟まない）時点でperformBackgroundSyncが
        // 直接（同期的に）呼ばれていればtrack()は既に完了している。外側Task{}でラップされていると
        // この時点ではまだ登録されておらず0のままになる（issue #164のシナリオを再現する回帰テスト）
        #expect(BackgroundSyncTracker.shared.trackedCountForTesting == 1)

        await BackgroundSyncTracker.shared.waitForAll()
        #expect(BackgroundSyncTracker.shared.trackedCountForTesting == 0)

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

    // MARK: - グループ変更時のorder衝突回帰テスト（issue #106）

    @Test("updateTask - グループを変更した場合、移動先グループ内の最大order+1に再採番される")
    func updateTask_groupChanged_reassignsOrderToAvoidCollision() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        // Group1にTask A（order=0）
        let taskA = TaskData(
            taskID: "task-a", title: "Task A", cause: "", groupID: "group1", order: 0, isComplete: false,
            created_at: Date())
        try? manager.saveItem(taskA)

        // Group2にTask X（order=0）・Task Y（order=1）
        let taskX = TaskData(
            taskID: "task-x", title: "Task X", cause: "", groupID: "group2", order: 0, isComplete: false,
            created_at: Date())
        let taskY = TaskData(
            taskID: "task-y", title: "Task Y", cause: "", groupID: "group2", order: 1, isComplete: false,
            created_at: Date())
        try? manager.saveItem(taskX)
        try? manager.saveItem(taskY)

        // Task AをGroup2に変更して保存
        _ = await viewModel.updateTask(taskID: "task-a", title: "Task A", cause: "", groupID: "group2")

        let updatedTaskA = try? manager.getObjectById(id: "task-a", type: TaskData.self)
        #expect(updatedTaskA?.groupID == "group2")
        // Group2内の既存最大order(1)+1に採番され、Task X・Task Yと衝突しないこと
        #expect(updatedTaskA?.order == 2)

        manager.clearAll()
    }

    @Test("updateTask - グループを変更しない場合、orderは維持される")
    func updateTask_groupUnchanged_preservesOrder() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        let task = TaskData(
            taskID: "task-a", title: "Task A", cause: "", groupID: "group1", order: 3, isComplete: false,
            created_at: Date())
        try? manager.saveItem(task)

        // グループを変更せずタイトルのみ更新
        _ = await viewModel.updateTask(taskID: "task-a", title: "Updated", cause: "", groupID: "group1")

        let updatedTask = try? manager.getObjectById(id: "task-a", type: TaskData.self)
        #expect(updatedTask?.order == 3)

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

    // MARK: - moveTask（並び替え）テスト

    @Test("moveTask - 完了課題非表示中に並び替えてもorderが重複しない")
    func moveTask_doesNotCauseOrderCollisionWhenCompletedTasksHidden() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        // A(order0,未完了) B(order1,完了) C(order2,未完了)
        let taskA = TaskViewModelTests.createTestTask(id: "A", groupID: "g1", order: 0, isComplete: false)
        let taskB = TaskViewModelTests.createTestTask(id: "B", groupID: "g1", order: 1, isComplete: true)
        let taskC = TaskViewModelTests.createTestTask(id: "C", groupID: "g1", order: 2, isComplete: false)
        try? manager.saveItem(taskA)
        try? manager.saveItem(taskB)
        try? manager.saveItem(taskC)

        _ = await viewModel.fetchData()
        // showCompletedTasksはデフォルトfalse -> filteredTaskListDataは[A, C]のはず
        #expect(viewModel.filteredTaskListData.map { $0.taskID } == ["A", "C"])

        // CをAより前に移動（index1->0）
        let result = await viewModel.moveTask(from: IndexSet(integer: 1), to: 0)
        guard case .success = result else {
            Issue.record("moveTask failed")
            manager.clearAll()
            return
        }

        // Realmから最新状態を取得してorderの一意性を検証
        let updatedTasks = (try? manager.getDataList(clazz: TaskData.self)) ?? []
        let orders = updatedTasks.map { $0.order }
        #expect(Set(orders).count == orders.count, "orderが重複してはいけない")

        // A/Bで重複していないことを明示的に確認
        let orderA = updatedTasks.first { $0.taskID == "A" }?.order
        let orderB = updatedTasks.first { $0.taskID == "B" }?.order
        let orderC = updatedTasks.first { $0.taskID == "C" }?.order
        #expect(orderA != nil && orderB != nil && orderC != nil)
        #expect(orderA != orderB)

        manager.clearAll()
    }

    @Test("moveTask - 完了課題表示ONにした際にorderが重複しない")
    func moveTask_thenShowCompletedTasks_orderIsStable() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        let taskA = TaskViewModelTests.createTestTask(id: "A", groupID: "g1", order: 0, isComplete: false)
        let taskB = TaskViewModelTests.createTestTask(id: "B", groupID: "g1", order: 1, isComplete: true)
        let taskC = TaskViewModelTests.createTestTask(id: "C", groupID: "g1", order: 2, isComplete: false)
        try? manager.saveItem(taskA)
        try? manager.saveItem(taskB)
        try? manager.saveItem(taskC)

        _ = await viewModel.fetchData()
        _ = await viewModel.moveTask(from: IndexSet(integer: 1), to: 0)

        // 完了課題を表示
        _ = await viewModel.fetchData()
        viewModel.showCompletedTasks = true

        let orders = viewModel.filteredTaskListData.map { $0.order }
        #expect(Set(orders).count == orders.count, "表示ON後もorderが重複していない")

        manager.clearAll()
    }

    @Test("moveTask - showCompletedTasksがtrueの場合は全件が並び替え対象になる")
    func moveTask_allTasksVisible_reordersAllCorrectly() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        let taskA = TaskViewModelTests.createTestTask(id: "A", groupID: "g1", order: 0, isComplete: false)
        let taskB = TaskViewModelTests.createTestTask(id: "B", groupID: "g1", order: 1, isComplete: true)
        try? manager.saveItem(taskA)
        try? manager.saveItem(taskB)

        _ = await viewModel.fetchData()
        viewModel.showCompletedTasks = true
        #expect(viewModel.filteredTaskListData.count == 2)

        // BをAより前に移動（index1->0）
        let result = await viewModel.moveTask(from: IndexSet(integer: 1), to: 0)
        guard case .success = result else {
            Issue.record("moveTask failed")
            manager.clearAll()
            return
        }

        let updatedTasks = (try? manager.getDataList(clazz: TaskData.self)) ?? []
        let orderA = updatedTasks.first { $0.taskID == "A" }?.order
        let orderB = updatedTasks.first { $0.taskID == "B" }?.order
        #expect(orderB == 0 && orderA == 1)

        manager.clearAll()
    }

    // MARK: - reorderTaskListData（表示反映の同期性）テスト（issue #161）

    @Test(
        "reorderTaskListData - Realmへの永続化を待たずに同期的にfilteredTaskListDataへ反映される"
    )
    func reorderTaskListData_synchronouslyUpdatesFilteredTaskListData() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        let taskA = TaskViewModelTests.createTestTask(id: "A", groupID: "g1", order: 0, isComplete: false)
        let taskB = TaskViewModelTests.createTestTask(id: "B", groupID: "g1", order: 1, isComplete: false)
        let taskC = TaskViewModelTests.createTestTask(id: "C", groupID: "g1", order: 2, isComplete: false)
        try? manager.saveItem(taskA)
        try? manager.saveItem(taskB)
        try? manager.saveItem(taskC)

        _ = await viewModel.fetchData()
        #expect(viewModel.filteredTaskListData.map { $0.taskID } == ["A", "B", "C"])

        // CをAより前に移動（index2->0）。awaitを挟まず、同期呼び出し直後に
        // filteredTaskListDataが更新済みであることを確認する
        // (List.onMoveハンドラから非同期Taskでラップせず直接呼べることの検証、issue #161)
        let mergedTasks = viewModel.reorderTaskListData(from: IndexSet(integer: 2), to: 0)

        #expect(viewModel.filteredTaskListData.map { $0.taskID } == ["C", "A", "B"])
        #expect(mergedTasks.map { $0.taskID } == ["C", "A", "B"])

        // この時点ではRealmへの永続化（persistTaskOrder）はまだ行われていないため、
        // Realm上のorderは変化していないはず
        let tasksBeforePersist = (try? manager.getDataList(clazz: TaskData.self)) ?? []
        let orderABeforePersist = tasksBeforePersist.first { $0.taskID == "A" }?.order
        #expect(orderABeforePersist == 0)

        // persistTaskOrderを実行して初めてRealmに反映される
        let result = await viewModel.persistTaskOrder(mergedTasks)
        guard case .success = result else {
            Issue.record("persistTaskOrder failed")
            manager.clearAll()
            return
        }

        let updatedTasks = (try? manager.getDataList(clazz: TaskData.self)) ?? []
        let orderC = updatedTasks.first { $0.taskID == "C" }?.order
        let orderA = updatedTasks.first { $0.taskID == "A" }?.order
        let orderB = updatedTasks.first { $0.taskID == "B" }?.order
        #expect(orderC == 0 && orderA == 1 && orderB == 2)

        manager.clearAll()
    }

    @Test(
        "persistTaskOrder - 完了課題表示ON中に並び替えた後OFFに切り替えても順序が保持される"
    )
    func persistTaskOrder_thenToggleShowCompletedTasksOff_orderIsPreserved() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        // A(order0,未完了) B(order1,完了) C(order2,未完了)
        let taskA = TaskViewModelTests.createTestTask(id: "A", groupID: "g1", order: 0, isComplete: false)
        let taskB = TaskViewModelTests.createTestTask(id: "B", groupID: "g1", order: 1, isComplete: true)
        let taskC = TaskViewModelTests.createTestTask(id: "C", groupID: "g1", order: 2, isComplete: false)
        try? manager.saveItem(taskA)
        try? manager.saveItem(taskB)
        try? manager.saveItem(taskC)

        _ = await viewModel.fetchData()

        // 完了課題を表示した状態でCをAより前に移動（index2->0）
        viewModel.showCompletedTasks = true
        let mergedTasks = viewModel.reorderTaskListData(from: IndexSet(integer: 2), to: 0)
        let result = await viewModel.persistTaskOrder(mergedTasks)
        guard case .success = result else {
            Issue.record("persistTaskOrder failed")
            manager.clearAll()
            return
        }
        #expect(viewModel.filteredTaskListData.map { $0.taskID } == ["C", "A", "B"])

        // 完了課題表示をOFFに戻しても、並び替え後の順序（未完了課題のみ）が保持されているべき（issue #177）
        viewModel.showCompletedTasks = false
        #expect(viewModel.filteredTaskListData.map { $0.taskID } == ["C", "A"])

        manager.clearAll()
    }

    // MARK: - reorderMeasuresListData / persistMeasuresOrder（対策並び替えの同期性）テスト（issue #165）

    @Test(
        "reorderMeasuresListData - Realmへの永続化を待たずに同期的にtaskDetail.measuresListへ反映される"
    )
    func reorderMeasuresListData_synchronouslyUpdatesTaskDetailMeasuresList() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        let task = TaskViewModelTests.createTestTask(id: "task-1", groupID: "g1", order: 0)
        try? manager.saveItem(task)
        let measuresA = TaskViewModelTests.createTestMeasures(
            id: "m-A", taskID: "task-1", title: "A", order: 0)
        let measuresB = TaskViewModelTests.createTestMeasures(
            id: "m-B", taskID: "task-1", title: "B", order: 1)
        let measuresC = TaskViewModelTests.createTestMeasures(
            id: "m-C", taskID: "task-1", title: "C", order: 2)
        try? manager.saveItem(measuresA)
        try? manager.saveItem(measuresB)
        try? manager.saveItem(measuresC)

        _ = await viewModel.fetchTaskDetail(taskID: "task-1")
        #expect(viewModel.taskDetail?.measuresList.map { $0.measuresID } == ["m-A", "m-B", "m-C"])

        // CをAより前に移動（index2->0）。awaitを挟まず、同期呼び出し直後に
        // taskDetail.measuresListが更新済みであることを確認する
        // (MeasuresListView.onMoveハンドラから非同期Taskでラップせず直接呼べることの検証、issue #165)
        let reordered = viewModel.reorderMeasuresListData(from: IndexSet(integer: 2), to: 0)

        #expect(viewModel.taskDetail?.measuresList.map { $0.measuresID } == ["m-C", "m-A", "m-B"])
        #expect(reordered?.map { $0.measuresID } == ["m-C", "m-A", "m-B"])

        // この時点ではRealmへの永続化（persistMeasuresOrder）はまだ行われていないため、
        // Realm上のorderは変化していないはず
        let measuresBeforePersist = manager.getMeasuresByTaskID(taskID: "task-1")
        let orderABeforePersist = measuresBeforePersist.first { $0.measuresID == "m-A" }?.order
        #expect(orderABeforePersist == 0)

        manager.clearAll()
    }

    @Test(
        "persistMeasuresOrder - Realmのorderへ反映後、fetchTaskDetail再取得でも同じ並び順を維持する"
    )
    func persistMeasuresOrder_updatesRealmOrderAndRefetchesTaskDetail() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        let task = TaskViewModelTests.createTestTask(id: "task-1", groupID: "g1", order: 0)
        try? manager.saveItem(task)
        let measuresA = TaskViewModelTests.createTestMeasures(
            id: "m-A", taskID: "task-1", title: "A", order: 0)
        let measuresB = TaskViewModelTests.createTestMeasures(
            id: "m-B", taskID: "task-1", title: "B", order: 1)
        let measuresC = TaskViewModelTests.createTestMeasures(
            id: "m-C", taskID: "task-1", title: "C", order: 2)
        try? manager.saveItem(measuresA)
        try? manager.saveItem(measuresB)
        try? manager.saveItem(measuresC)

        _ = await viewModel.fetchTaskDetail(taskID: "task-1")
        guard let reordered = viewModel.reorderMeasuresListData(from: IndexSet(integer: 2), to: 0) else {
            Issue.record("reorderMeasuresListData returned nil")
            manager.clearAll()
            return
        }

        let result = await viewModel.persistMeasuresOrder(reordered)
        guard case .success = result else {
            Issue.record("persistMeasuresOrder failed")
            manager.clearAll()
            return
        }

        let updatedMeasures = manager.getMeasuresByTaskID(taskID: "task-1")
        let orderC = updatedMeasures.first { $0.measuresID == "m-C" }?.order
        let orderA = updatedMeasures.first { $0.measuresID == "m-A" }?.order
        let orderB = updatedMeasures.first { $0.measuresID == "m-B" }?.order
        #expect(orderC == 0 && orderA == 1 && orderB == 2)

        // fetchTaskDetailによる再取得後も、ドラッグ確定時に反映した並び順から変化しない
        // （＝一旦元の位置に戻ってから正しい位置に変わるスナップバックが発生しない）ことを確認
        #expect(viewModel.taskDetail?.measuresList.map { $0.measuresID } == ["m-C", "m-A", "m-B"])

        manager.clearAll()
    }

    @Test("reorderMeasuresListData - taskDetailがnilの場合はnilを返しクラッシュしない")
    func reorderMeasuresListData_withNilTaskDetail_returnsNil() async {
        let viewModel = TaskViewModel()
        RealmManager.shared.clearAll()

        #expect(viewModel.taskDetail == nil)
        let reordered = viewModel.reorderMeasuresListData(from: IndexSet(integer: 0), to: 1)
        #expect(reordered == nil)
    }

    @Test("persistMeasuresOrder - 空配列を渡した場合は即座に成功を返す")
    func persistMeasuresOrder_withEmptyArray_returnsSuccessWithoutCallingMeasuresViewModel() async {
        let viewModel = TaskViewModel()
        RealmManager.shared.clearAll()

        let result = await viewModel.persistMeasuresOrder([])
        guard case .success = result else {
            Issue.record("persistMeasuresOrder with empty array should succeed immediately")
            return
        }
    }

    @Test("moveMeasures - 表示反映と永続化を一括で行いRealmへ反映される")
    func moveMeasures_reordersAndPersists() async {
        let viewModel = TaskViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        let task = TaskViewModelTests.createTestTask(id: "task-1", groupID: "g1", order: 0)
        try? manager.saveItem(task)
        let measuresA = TaskViewModelTests.createTestMeasures(
            id: "m-A", taskID: "task-1", title: "A", order: 0)
        let measuresB = TaskViewModelTests.createTestMeasures(
            id: "m-B", taskID: "task-1", title: "B", order: 1)
        try? manager.saveItem(measuresA)
        try? manager.saveItem(measuresB)

        _ = await viewModel.fetchTaskDetail(taskID: "task-1")

        let result = await viewModel.moveMeasures(from: IndexSet(integer: 1), to: 0)
        guard case .success = result else {
            Issue.record("moveMeasures failed")
            manager.clearAll()
            return
        }

        let updatedMeasures = manager.getMeasuresByTaskID(taskID: "task-1")
        let orderA = updatedMeasures.first { $0.measuresID == "m-A" }?.order
        let orderB = updatedMeasures.first { $0.measuresID == "m-B" }?.order
        #expect(orderB == 0 && orderA == 1)

        manager.clearAll()
    }

    // MARK: - convertFirebaseSyncError テスト（issue #36: エラー二重変換防止）

    @Test(
        "convertFirebaseSyncError - 既にSportsNoteErrorの場合は再変換せずそのまま返す",
        arguments: [
            SportsNoteError.firebasePermissionDenied,
            SportsNoteError.firebaseDocumentNotFound,
            SportsNoteError.networkTimeout,
        ])
    func convertFirebaseSyncError_doesNotReconvertExistingSportsNoteError(original: SportsNoteError) async {
        let viewModel = TaskViewModel()

        let converted = viewModel.convertFirebaseSyncError(original, context: "TaskViewModel-syncEntityToFirebase")

        #expect(converted.errorDescription == original.errorDescription)
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

    /// テスト用のMeasuresを作成
    static func createTestMeasures(
        id: String = "measures-1",
        taskID: String = "task-1",
        title: String = "Test Measures",
        order: Int = 0,
        isDeleted: Bool = false
    ) -> Measures {
        return Measures(
            measuresID: id,
            taskID: taskID,
            title: title,
            order: order,
            created_at: Date(),
            isDeleted: isDeleted
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
