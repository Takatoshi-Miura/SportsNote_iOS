import Combine
import Foundation
import RealmSwift
import SwiftUI

@MainActor
class TaskViewModel: ObservableObject, @preconcurrency BaseViewModelProtocol, @preconcurrency CRUDViewModelProtocol,
    @preconcurrency FirebaseSyncable
{
    typealias EntityType = TaskData
    @Published var tasks: [TaskData] = []
    @Published var taskListData: [TaskListData] = []
    @Published var taskDetail: TaskDetailData?
    @Published var isLoading: Bool = false
    @Published var currentError: SportsNoteError?
    @Published var showingErrorAlert: Bool = false

    // タスク更新通知パブリッシャー
    let taskUpdatedPublisher = PassthroughSubject<Void, Never>()

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
        isLoading = true
        defer { isLoading = false }

        do {
            // グループIDでフィルタリング
            let allTasks = try RealmManager.shared.getDataList(clazz: TaskData.self)
            tasks = allTasks.filter { $0.groupID == groupID && !$0.isDeleted }
                .sorted { $0.order < $1.order }
            convertToTaskListData()
            hideErrorAlert()
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "TaskViewModel-fetchTasksByGroupID")
            return .failure(sportsNoteError)
        }
    }

    /// 課題の詳細情報を取得（新Resultパターン対応）
    /// - Parameter taskID: 課題ID
    /// - Returns: Result
    func fetchTaskDetail(taskID: String) async -> Result<Void, SportsNoteError> {
        do {
            if let task = try RealmManager.shared.getObjectById(id: taskID, type: TaskData.self) {
                let measures = RealmManager.shared.getMeasuresByTaskID(taskID: taskID)
                taskDetail = TaskDetailData(task: task, measuresList: measures)
                return .success(())
            } else {
                taskDetail = nil
                return .success(())
            }
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "TaskViewModel-fetchTaskDetail")
            return .failure(sportsNoteError)
        }
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
    @discardableResult
    func saveTask(
        taskID: String? = nil,
        title: String,
        cause: String,
        groupID: String,
        order: Int? = nil,
        isComplete: Bool = false,
        created_at: Date? = nil
    ) -> TaskData {
        let newTaskID = taskID ?? UUID().uuidString
        let newOrder = order ?? ((try? RealmManager.shared.getCount(clazz: TaskData.self)) ?? 0)
        let newCreatedAt = created_at ?? Date()

        let task = TaskData(
            taskID: newTaskID,
            title: title,
            cause: cause,
            groupID: groupID,
            order: newOrder,
            isComplete: isComplete,
            created_at: newCreatedAt
        )
        try? RealmManager.shared.saveItem(task)

        // Firebaseへの同期
        if Network.isOnline() && UserDefaultsManager.get(key: UserDefaultsManager.Keys.isLogin, defaultValue: false) {
            Task {
                let isUpdate = taskID != nil
                if isUpdate {
                    try await FirebaseManager.shared.updateTask(task: task)
                } else {
                    try await FirebaseManager.shared.saveTask(task: task)
                }
            }
        }

        // Refresh task list
        Task {
            _ = await fetchData()
        }

        // タスク詳細情報を表示している場合は、詳細情報も更新
        if let detail = taskDetail, detail.task.taskID == newTaskID {
            Task {
                _ = await fetchTaskDetail(taskID: newTaskID)
            }
        }

        // タスク更新通知を送信
        taskUpdatedPublisher.send()

        return task
    }

    /// 新しい課題を保存（View層向けの簡易メソッド）
    /// - Parameters:
    ///   - title: 課題タイトル
    ///   - cause: 原因
    ///   - groupID: グループID
    /// - Returns: 保存された課題データとResult
    func saveNewTask(title: String, cause: String, groupID: String) async -> Result<TaskData, SportsNoteError> {
        let newTaskID = UUID().uuidString
        let newOrder = (try? RealmManager.shared.getCount(clazz: TaskData.self)) ?? 0

        let newTask = TaskData(
            taskID: newTaskID,
            title: title,
            cause: cause,
            groupID: groupID,
            order: newOrder,
            isComplete: false,
            created_at: Date()
        )

        let result = await save(newTask, isUpdate: false)
        switch result {
        case .success:
            return .success(newTask)
        case .failure(let error):
            return .failure(error)
        }
    }

    /// 課題の完了状態を切り替え（新Resultパターン対応）
    /// - Parameter taskID: 課題ID
    /// - Returns: Result
    func toggleTaskCompletion(taskID: String) async -> Result<Void, SportsNoteError> {
        do {
            guard let taskToUpdate = try RealmManager.shared.getObjectById(id: taskID, type: TaskData.self) else {
                let error = SportsNoteError.systemError("Task not found: \(taskID)")
                return .failure(error)
            }

            let updatedTask = TaskData(
                taskID: taskToUpdate.taskID,
                title: taskToUpdate.title,
                cause: taskToUpdate.cause,
                groupID: taskToUpdate.groupID,
                order: taskToUpdate.order,
                isComplete: !taskToUpdate.isComplete,
                created_at: taskToUpdate.created_at
            )

            return await save(updatedTask, isUpdate: true)
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "TaskViewModel-toggleTaskCompletion")
            return .failure(sportsNoteError)
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
            Task {
                let result = await syncEntityToFirebase(entity, isUpdate: isUpdate)
                if case .failure(let error) = result {
                    // Firebase同期エラーは既存エラーがない場合のみ設定
                    await MainActor.run {
                        if currentError == nil {
                            showErrorAlert(error)
                        }
                    }
                }
            }

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
                if let deletedTask = try? RealmManager.shared.getObjectById(id: id, type: TaskData.self) {
                    let result = await syncEntityToFirebase(deletedTask, isUpdate: true)
                    if case .failure(let error) = result {
                        await MainActor.run {
                            if currentError == nil {
                                showErrorAlert(error)
                            }
                        }
                    }
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
    }

    /// 最も優先度の高い（orderが低い）対策を取得
    /// - Parameter taskID: 課題ID
    /// - Returns: 対策オブジェクト（存在しない場合はnil）
    private func getMostPriorityMeasures(taskID: String) -> Measures? {
        let measuresList = RealmManager.shared.getMeasuresByTaskID(taskID: taskID)
        return measuresList.min { $0.order < $1.order }
    }

    // MARK: - Measures

    /// 対策の並び順を更新（新Resultパターン対応）
    /// - Parameter measures: 並び替え後の対策リスト
    /// - Returns: Result
    func updateMeasuresOrder(measures: [Measures]) async -> Result<Void, SportsNoteError> {
        guard !measures.isEmpty else {
            return .success(())
        }

        let measuresViewModel = MeasuresViewModel()
        // TODO: MeasuresViewModelも将来的にResultパターンに対応する
        measuresViewModel.updateMeasuresOrder(measures: measures)

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
