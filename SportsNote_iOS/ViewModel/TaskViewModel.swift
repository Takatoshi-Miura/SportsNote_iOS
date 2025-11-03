import Combine
import Foundation
import RealmSwift

@MainActor
class TaskViewModel: ObservableObject, BaseViewModelProtocol, CRUDViewModelProtocol, FirebaseSyncable {
    typealias EntityType = TaskData
    @Published var tasks: [TaskData] = []
    @Published var taskListData: [TaskListData] = []
    @Published var filteredTaskListData: [TaskListData] = []
    @Published var taskDetail: TaskDetailData?
    @Published var showCompletedTasks: Bool = false {
        didSet {
            updateFilteredTaskListData()
        }
    }
    @Published var isLoading: Bool = false
    @Published var currentError: SportsNoteError?
    @Published var showingErrorAlert: Bool = false

    // タスク更新通知パブリッシャー
    let taskUpdatedPublisher = PassthroughSubject<Void, Never>()

    // 対策管理用ViewModel
    private let measuresViewModel = MeasuresViewModel()

    init() {
        // 初期化のみ実行、データ取得はView側で明示的に実行
    }

    // MARK: - CRUD処理

    /// データを取得（プロトコル準拠）
    /// - Returns: Result
    func fetchData() async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // Realm操作はMainActorで実行
            tasks = try RealmManager.shared.getDataList(clazz: TaskData.self)
            convertToTaskListData()
            hideErrorAlert()
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "TaskViewModel-fetchData")
            return .failure(sportsNoteError)
        }
    }

    /// 指定IDの課題を取得（プロトコル準拠）
    /// - Parameter id: 課題ID
    /// - Returns: Result
    func fetchById(id: String) async -> Result<TaskData?, SportsNoteError> {
        do {
            let task = try RealmManager.shared.getObjectById(id: id, type: TaskData.self)
            return .success(task)
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "TaskViewModel-fetchById")
            return .failure(sportsNoteError)
        }
    }

    /// 指定したグループIDの課題を取得（新Resultパターン対応）
    /// - Parameter groupID: グループID
    /// - Returns: Result
    func fetchTasksByGroupID(groupID: String) async -> Result<Void, SportsNoteError> {
        let result = await fetchData()
        switch result {
        case .success:
            // fetchData()で取得済みのデータをグループIDでフィルタリング
            tasks = tasks.filter { $0.groupID == groupID }
            convertToTaskListData()
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }

    /// 課題の詳細情報を取得（新Resultパターン対応）
    /// - Parameter taskID: 課題ID
    /// - Returns: Result
    func fetchTaskDetail(taskID: String) async -> Result<Void, SportsNoteError> {
        let taskResult = await fetchById(id: taskID)
        switch taskResult {
        case .success(let task):
            if let task = task {
                let measuresResult = await measuresViewModel.getMeasuresByTaskID(taskID: taskID)
                switch measuresResult {
                case .success(let measures):
                    taskDetail = TaskDetailData(task: task, measuresList: measures)
                    return .success(())
                case .failure(let error):
                    return .failure(error)
                }
            } else {
                taskDetail = nil
                return .success(())
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    /// 課題と対策を新規保存
    /// - Parameters:
    ///   - title: 課題タイトル
    ///   - cause: 原因
    ///   - groupID: グループID
    ///   - measuresTitle: 対策タイトル（nilの場合は対策を保存しない）
    /// - Returns: 保存された課題データとResult
    func saveNewTaskWithMeasures(
        title: String, cause: String, groupID: String, measuresTitle: String? = nil
    ) async -> Result<TaskData, SportsNoteError> {
        // 課題を保存
        let newTask = createTaskData(title: title, cause: cause, groupID: groupID)
        let taskResult = await save(newTask, isUpdate: false)
        switch taskResult {
        case .success:
            // 対策タイトルが指定されている場合は対策も保存
            if let measuresTitle = measuresTitle, !measuresTitle.isEmpty {
                let result = await measuresViewModel.saveMeasures(
                    taskID: newTask.taskID,
                    title: measuresTitle,
                    order: 0
                )
                if case .failure(let error) = result {
                    return .failure(error)
                }
                // 対策保存後にTaskListDataを再生成
                do {
                    tasks = try RealmManager.shared.getDataList(clazz: TaskData.self)
                    convertToTaskListData()
                } catch {
                    // エラーが発生してもタスク自体は保存されているので継続
                    print("TaskListData再生成エラー: \(error)")
                }
            }
            return .success(newTask)
        case .failure(let error):
            return .failure(error)
        }
    }

    /// 既存課題に対策を追加
    /// - Parameters:
    ///   - taskID: 課題ID
    ///   - title: 対策タイトル
    /// - Returns: Result
    func addMeasureToTask(taskID: String, title: String) async -> Result<Void, SportsNoteError> {
        guard !title.isEmpty else {
            let error = SportsNoteError.systemError("対策タイトルは必須項目です")
            return .failure(error)
        }

        let result = await measuresViewModel.saveMeasures(
            taskID: taskID,
            title: title
        )

        // 成功時はタスク詳細を再取得
        if case .success = result {
            _ = await fetchTaskDetail(taskID: taskID)
        }

        return result
    }

    /// 既存課題の詳細を更新
    /// - Parameters:
    ///   - taskID: 更新対象の課題ID
    ///   - title: 新しい課題タイトル
    ///   - cause: 新しい原因
    ///   - groupID: 新しいグループID
    /// - Returns: Result
    func updateTask(
        taskID: String, title: String, cause: String, groupID: String
    ) async -> Result<Void, SportsNoteError> {
        // バリデーション
        guard !title.isEmpty else {
            let error = SportsNoteError.systemError("タイトルは必須項目です")
            return .failure(error)
        }

        let taskResult = await fetchById(id: taskID)
        switch taskResult {
        case .success(let existingTask):
            guard let existingTask = existingTask else {
                let error = SportsNoteError.systemError("Task not found: \(taskID)")
                return .failure(error)
            }

            // 新しいTaskDataオブジェクトを構築
            let updatedTask = createTaskData(
                title: title,
                cause: cause,
                groupID: groupID,
                basedOn: existingTask
            )

            // 既存のsaveメソッドを使用して更新
            return await save(updatedTask, isUpdate: true)
        case .failure(let error):
            return .failure(error)
        }
    }

    /// 課題の完了状態を切り替え（新Resultパターン対応）
    /// - Parameter taskID: 課題ID
    /// - Returns: Result
    func toggleTaskCompletion(taskID: String) async -> Result<Void, SportsNoteError> {
        let taskResult = await fetchById(id: taskID)
        switch taskResult {
        case .success(let taskToUpdate):
            guard let taskToUpdate = taskToUpdate else {
                let error = SportsNoteError.systemError("Task not found: \(taskID)")
                return .failure(error)
            }

            let updatedTask = createTaskData(
                title: taskToUpdate.title,
                cause: taskToUpdate.cause,
                groupID: taskToUpdate.groupID,
                basedOn: taskToUpdate,
                overrideIsComplete: !taskToUpdate.isComplete
            )

            return await save(updatedTask, isUpdate: true)
        case .failure(let error):
            return .failure(error)
        }
    }

    /// 課題保存処理（プロトコル準拠）
    /// - Parameters:
    ///   - entity: 保存するTaskData
    ///   - isUpdate: 更新かどうか
    /// - Returns: Result
    func save(_ entity: TaskData, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // 1. Realm操作はMainActorで実行
            try RealmManager.shared.saveItem(entity)

            // 2. Firebase同期はバックグラウンドで実行
            performBackgroundSync(entity, isUpdate: isUpdate)

            // 3. UI更新
            tasks = try RealmManager.shared.getDataList(clazz: TaskData.self)
            convertToTaskListData()

            // タスク更新通知を送信
            taskUpdatedPublisher.send()

            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "TaskViewModel-save")
            return .failure(sportsNoteError)
        }
    }

    /// 課題削除処理（プロトコル準拠）
    /// - Parameter id: 削除する課題ID
    /// - Returns: Result
    func delete(id: String) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // 1. Realm操作はMainActorで実行
            try RealmManager.shared.logicalDelete(id: id, type: TaskData.self)

            // 2. Firebase同期はバックグラウンドで実行
            Task {
                let taskResult = await fetchById(id: id)
                if case .success(let deletedTask) = taskResult, let deletedTask = deletedTask {
                    performBackgroundSync(deletedTask, isUpdate: true)
                }
            }

            // 3. UI更新
            tasks.removeAll(where: { $0.taskID == id })
            taskListData.removeAll(where: { $0.taskID == id })

            // タスク更新通知を送信
            taskUpdatedPublisher.send()

            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "TaskViewModel-delete")
            return .failure(sportsNoteError)
        }
    }

    /// TaskDataオブジェクトを作成（新規・更新両対応）
    /// - Parameters:
    ///   - title: 課題タイトル
    ///   - cause: 原因
    ///   - groupID: グループID
    ///   - basedOn: 更新ベースとなる既存TaskData（nilの場合は新規作成）
    ///   - overrideIsComplete: 完了状態を明示的に変更する場合の値
    /// - Returns: 作成されたTaskData
    private func createTaskData(
        title: String,
        cause: String,
        groupID: String,
        basedOn existingTask: TaskData? = nil,
        overrideIsComplete: Bool? = nil
    ) -> TaskData {
        if let existingTask = existingTask {
            // 更新の場合: 既存データをベースに新しいTaskDataを作成
            return TaskData(
                taskID: existingTask.taskID,
                title: title,
                cause: cause,
                groupID: groupID,
                order: existingTask.order,
                isComplete: overrideIsComplete ?? existingTask.isComplete,
                created_at: existingTask.created_at
            )
        } else {
            // 新規作成の場合: 新しいTaskDataを作成
            let newTaskID = UUIDGenerator.generateID()
            let newOrder = (try? RealmManager.shared.getCount(clazz: TaskData.self)) ?? 0

            return TaskData(
                taskID: newTaskID,
                title: title,
                cause: cause,
                groupID: groupID,
                order: newOrder,
                isComplete: false,
                created_at: Date()
            )
        }
    }

    /// TaskDataをTaskListDataに変換する
    private func convertToTaskListData() {
        var taskList = [TaskListData]()

        for task in tasks {
            // グループカラーを取得
            let groupColor = GroupViewModel.getGroupColor(groupID: task.groupID)

            // 対策情報を取得
            let measures = getMostPriorityMeasures(taskID: task.taskID)

            // TaskListDataを作成
            let taskListItem = TaskListData(
                taskID: task.taskID,
                groupID: task.groupID,
                groupColor: groupColor,
                title: task.title,
                measuresID: measures?.measuresID ?? "",
                measures: measures?.title ?? "",
                memoID: nil,
                order: task.order,
                isComplete: task.isComplete
            )
            taskList.append(taskListItem)
        }

        taskListData = taskList
        updateFilteredTaskListData()
    }

    /// フィルタリングされたタスクリストを更新
    private func updateFilteredTaskListData() {
        if showCompletedTasks {
            // 完了タスクを表示する場合はすべて表示
            filteredTaskListData = taskListData
        } else {
            // 完了タスクを非表示にする場合はフィルタリング
            filteredTaskListData = taskListData.filter { taskListItem in
                // tasksから完了状態を取得
                let isComplete = tasks.first(where: { $0.taskID == taskListItem.taskID })?.isComplete ?? false
                return !isComplete
            }
        }
    }

    /// 未追加のタスクを取得（ノート編集画面用）
    /// - Parameter excludingTaskIds: 除外するタスクIDのセット
    /// - Returns: 未追加タスクのリスト
    func getUnaddedTasks(excludingTaskIds: Set<String>) -> [TaskListData] {
        return taskListData.filter { taskListItem in
            // 未完了 && 対策あり && 除外リストに含まれない
            !taskListItem.isComplete
                && !taskListItem.measuresID.isEmpty
                && !excludingTaskIds.contains(taskListItem.taskID)
        }
    }

    // MARK: - Measures委譲メソッド

    /// 最も優先度の高い（orderが低い）対策を取得（MeasuresViewModelへの委譲）
    /// - Parameter taskID: 課題ID
    /// - Returns: 対策オブジェクト（存在しない場合はnil）
    private func getMostPriorityMeasures(taskID: String) -> Measures? {
        // 同期的な処理が必要なため、RealmManagerを直接使用
        // 将来的にはconvertToTaskListData()の非同期化を検討
        let measuresList = RealmManager.shared.getMeasuresByTaskID(taskID: taskID)
        return measuresList.min { $0.order < $1.order }
    }

    /// 対策の並び順を更新（MeasuresViewModelへの委譲メソッド）
    /// - Parameter measures: 並び替え後の対策リスト
    /// - Returns: Result
    func updateMeasuresOrder(measures: [Measures]) async -> Result<Void, SportsNoteError> {
        guard !measures.isEmpty else {
            return .success(())
        }

        // MeasuresViewModelに委譲
        let result = await measuresViewModel.updateMeasuresOrder(measures: measures)
        if case .failure(let error) = result {
            return .failure(error)
        }

        // 対策の並び替えが完了したら、詳細画面を更新
        if let detail = taskDetail {
            let detailResult = await fetchTaskDetail(taskID: detail.task.taskID)
            if case .failure(let error) = detailResult {
                return .failure(error)
            }
        }

        return .success(())
    }

    // MARK: - Firebase同期処理

    /// 指定された課題をFirebaseに同期する
    /// - Parameters:
    ///   - entity: 同期する課題
    ///   - isUpdate: 更新かどうか
    /// - Returns: 同期処理の結果
    func syncEntityToFirebase(_ entity: TaskData, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
        guard isOnlineAndLoggedIn else {
            return .success(())
        }

        do {
            if isUpdate {
                try await FirebaseManager.shared.updateTask(task: entity)
            } else {
                try await FirebaseManager.shared.saveTask(task: entity)
            }
            return .success(())
        } catch {
            let sportsNoteError = ErrorMapper.mapFirebaseError(error, context: "TaskViewModel-syncEntityToFirebase")
            return .failure(sportsNoteError)
        }
    }

    /// 全ての課題をFirebaseに同期する
    /// - Returns: 同期処理の結果
    func syncToFirebase() async -> Result<Void, SportsNoteError> {
        guard isOnlineAndLoggedIn else {
            return .success(())
        }

        do {
            let allTasks = try RealmManager.shared.getDataList(clazz: TaskData.self)
            for task in allTasks {
                let result = await syncEntityToFirebase(task)
                if case .failure(let error) = result {
                    return .failure(error)
                }
            }
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "TaskViewModel-syncToFirebase")
            return .failure(sportsNoteError)
        }
    }
}
