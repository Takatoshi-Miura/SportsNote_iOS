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

    private var cancellables = Set<AnyCancellable>()

    init() {
        // 初期化のみ実行、データ取得はView側で明示的に実行
        observeClearAllData(cancellables: &cancellables)
    }

    /// Realmオブジェクトの参照をクリア
    func clearRealmReferences() {
        tasks = []
        taskListData = []
        filteredTaskListData = []
        taskDetail = nil
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
        await fetchByIdDefault(id: id, context: "TaskViewModel-fetchById")
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
            let error = SportsNoteError.systemError(LocalizedStrings.measuresTitleRequiredError)
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
            let error = SportsNoteError.systemError(LocalizedStrings.taskTitleRequiredError)
            return .failure(error)
        }

        let taskResult = await fetchById(id: taskID)
        switch taskResult {
        case .success(let existingTask):
            guard let existingTask = existingTask else {
                let error = SportsNoteError.systemError(String(format: LocalizedStrings.taskNotFoundError, taskID))
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
                let error = SportsNoteError.systemError(String(format: LocalizedStrings.taskNotFoundError, taskID))
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
            // 更新時は、エンティティ再構築時にUserDefaultsの現在値で上書きされてしまったuserIDを、
            // Realmに永続化済みの値に戻す（アカウント作成直後のuserID切替タイミングでも
            // Firebase更新が正しいドキュメントIDに対して行われるようにするため。issue #74）
            if isUpdate,
                let existingTask = try RealmManager.shared.getObjectById(id: entity.taskID, type: TaskData.self)
            {
                entity.userID = existingTask.userID
            }

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
            // 1. 削除前にオブジェクトを取得（論理削除後はisDeleted=trueで取得できなくなるため）
            let taskToDelete = try RealmManager.shared.getObjectById(id: id, type: TaskData.self)

            // 2. Realm操作はMainActorで実行
            try RealmManager.shared.logicalDelete(id: id, type: TaskData.self)

            // 3. Firebase同期はバックグラウンドで実行（削除前に取得したオブジェクトを使用）
            if let taskToDelete = taskToDelete {
                Task {
                    performBackgroundSync(taskToDelete, isUpdate: true)
                }
            }

            // 4. UI更新
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
            // groupIDが変更された場合は移動先グループ内の最大order+1を採番し、
            // 既存課題とのorder衝突を防ぐ（groupIDが変わらない通常の更新ではorderを維持する）
            let order: Int
            if groupID != existingTask.groupID {
                order = RealmManager.shared.getNextOrder(
                    clazz: TaskData.self,
                    predicate: NSPredicate(format: "groupID == %@", groupID)
                )
            } else {
                order = existingTask.order
            }

            return TaskData(
                taskID: existingTask.taskID,
                title: title,
                cause: cause,
                groupID: groupID,
                order: order,
                isComplete: overrideIsComplete ?? existingTask.isComplete,
                created_at: existingTask.created_at
            )
        } else {
            // 新規作成の場合: 新しいTaskDataを作成
            let newTaskID = UUIDGenerator.generateID()
            let newOrder = RealmManager.shared.getNextOrder(
                clazz: TaskData.self,
                predicate: NSPredicate(format: "groupID == %@", groupID)
            )

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

    /// メモをmeasuresID経由で課題（TaskListData）に関連付ける
    /// - Parameter memos: 対象のメモ一覧（呼び出し側でnoteID・isDeletedによるフィルタ済みを渡すこと）
    /// - Returns: taskIDで重複排除した(task: TaskListData, memo: Memo)のペア配列
    func associateTasksWithMemos(memos: [Memo]) -> [(task: TaskListData, memo: Memo)] {
        var result: [String: (task: TaskListData, memo: Memo)] = [:]
        for memo in memos {
            // memo.measuresIDが指す対策のtaskIDを解決してから突合する。
            // taskListData.measuresIDは常に現在の最優先対策のIDのため、対策の並び替えで
            // 変わった場合でもtaskIDで突合すれば同一課題として認識できる（issue #109）
            guard let measures = try? RealmManager.shared.getObjectById(id: memo.measuresID, type: Measures.self)
            else {
                continue
            }
            if let task = taskListData.first(where: { $0.taskID == measures.taskID }) {
                result[task.taskID] = (task: task, memo: memo)
            }
        }
        // Dictionary経由で組み立てるため列挙順が不定になる。task.order昇順にソートし、
        // アプリ再起動のたびに表示順が入れ替わらないようにする（issue #137）。
        // orderはグループ内スコープで採番されるため異なるグループの課題間で同値になり得る。
        // taskIDを副次キーにして同値時の順序も決定的にする
        return Array(result.values)
            .sorted {
                $0.task.order != $1.task.order ? $0.task.order < $1.task.order : $0.task.taskID < $1.task.taskID
            }
    }

    /// 未追加のタスクを取得（taskReflectionsから直接算出）
    /// - Parameter taskReflections: ノートに追加済みの課題と感想のマップ
    /// - Returns: 未追加タスクのリスト
    func getUnaddedTasks(taskReflections: [TaskListData: String]) -> [TaskListData] {
        let addedTaskIds = Set(taskReflections.keys.map { $0.taskID })
        return getUnaddedTasks(excludingTaskIds: addedTaskIds)
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

    /// 対策表示上の並び替えを同期的に即時反映する（Realm永続化・Firebase同期は含まない）
    /// MeasuresListView.onMoveハンドラから非同期Taskでラップせず直接呼ぶことで、ドラッグを離した瞬間に
    /// 並び順が確定するようにするため分離した（issue #165、issue #161のreorderTaskListDataと同パターン）
    /// - Parameters:
    ///   - source: 移動元のインデックス
    ///   - destination: 移動先のインデックス
    /// - Returns: Realm永続化用の並び替え後の対策配列（`persistMeasuresOrder`に渡す）。taskDetail未取得時はnil
    func reorderMeasuresListData(from source: IndexSet, to destination: Int) -> [Measures]? {
        guard var detail = taskDetail else { return nil }
        detail.measuresList.move(fromOffsets: source, toOffset: destination)
        taskDetail = detail
        return detail.measuresList
    }

    /// 並び替え後の対策配列をRealmへ永続化し、課題詳細を再取得して整合させる
    /// （Realm保存・Firebase同期自体はMeasuresViewModel.updateMeasuresOrderに委譲、ロジックは変更しない）
    /// - Parameter measures: `reorderMeasuresListData`が返す並び替え後の対策配列
    /// - Returns: Result
    func persistMeasuresOrder(_ measures: [Measures]) async -> Result<Void, SportsNoteError> {
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

    /// 対策の並び替え（表示反映＋永続化を一括で行う）。moveTaskと対になる統合テスト用の便利メソッド
    /// - Parameters:
    ///   - source: 移動元のインデックス
    ///   - destination: 移動先のインデックス
    /// - Returns: Result
    func moveMeasures(from source: IndexSet, to destination: Int) async -> Result<Void, SportsNoteError> {
        guard let reordered = reorderMeasuresListData(from: source, to: destination) else {
            return .success(())
        }
        return await persistMeasuresOrder(reordered)
    }

    // MARK: - 並び替え処理

    /// 表示上の並び替えを同期的に即時反映する（Realm永続化・Firebase同期は含まない）
    /// List.onMoveハンドラから非同期Taskでラップせず直接呼ぶことで、ドラッグを離した瞬間に
    /// 並び順が確定するようにするため分離した（issue #161）
    /// - Parameters:
    ///   - source: 移動元のインデックス
    ///   - destination: 移動先のインデックス
    /// - Returns: Realm永続化用のマージ済み課題配列（完了課題を含む全件、`persistTaskOrder`に渡す）
    func reorderTaskListData(from source: IndexSet, to destination: Int) -> [TaskData] {
        // filteredTaskListData上で移動（表示上の並び替え）
        var reordered = filteredTaskListData
        reordered.move(fromOffsets: source, toOffset: destination)
        filteredTaskListData = reordered

        // 表示中（可視）の課題IDと、並び替え後の新しい順序のTaskData配列を作成
        let visibleTaskIDs = Set(reordered.map { $0.taskID })
        var visibleTasksInNewOrder =
            reordered.compactMap { listData in
                tasks.first { $0.taskID == listData.taskID }
            }
            .makeIterator()

        // 現在保持している全課題（完了課題を含む）を既存orderの昇順で並べ、
        // 可視だった位置だけを新しい順序の課題に差し替える。
        // 非表示（完了）課題は元の相対順序のまま据え置くことで、
        // 全件をまとめてupdateTaskOrderに渡してもorderの重複が発生しないようにする。
        let mergedTasks: [TaskData] = tasks.sorted { $0.order < $1.order }
            .map { task in
                if visibleTaskIDs.contains(task.taskID) {
                    return visibleTasksInNewOrder.next() ?? task
                } else {
                    return task
                }
            }
        return mergedTasks
    }

    /// 並び替え後の課題配列をRealmへ永続化し、Firebaseへバックグラウンド同期する
    /// - Parameter mergedTasks: `reorderTaskListData`が返す並び替え後の全課題配列
    /// - Returns: Result
    func persistTaskOrder(_ mergedTasks: [TaskData]) async -> Result<Void, SportsNoteError> {
        do {
            try RealmManager.shared.updateTaskOrder(tasks: mergedTasks)

            // Firebase同期（バックグラウンド）
            // ログアウト/アカウント削除等でのRealm全削除前に完了を待機できるよう追跡登録する（Issue #84対応）
            let syncTask = Task<Void, Never> {
                for task in mergedTasks {
                    _ = await syncEntityToFirebase(task, isUpdate: true)
                }
            }
            BackgroundSyncTracker.shared.track(syncTask)

            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(
                error, context: "TaskViewModel-moveTask")
            return .failure(sportsNoteError)
        }
    }

    /// 課題の並び替え（表示反映＋永続化を一括で行う）
    /// - Parameters:
    ///   - source: 移動元のインデックス
    ///   - destination: 移動先のインデックス
    /// - Returns: Result
    func moveTask(from source: IndexSet, to destination: Int) async -> Result<Void, SportsNoteError> {
        let mergedTasks = reorderTaskListData(from: source, to: destination)
        return await persistTaskOrder(mergedTasks)
    }

    // MARK: - Firebase同期処理

    /// 指定された課題をFirebaseに同期する
    /// - Parameters:
    ///   - entity: 同期する課題
    ///   - isUpdate: 更新かどうか
    /// - Returns: 同期処理の結果
    func syncEntityToFirebase(_ entity: TaskData, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
        await syncEntityToFirebaseDefault(
            isUpdate: isUpdate,
            context: "TaskViewModel-syncEntityToFirebase",
            updateAction: { try await FirebaseManager.shared.updateTask(task: entity) },
            saveAction: { try await FirebaseManager.shared.saveTask(task: entity) }
        )
    }

    /// 全ての課題をFirebaseに同期する
    /// - Returns: 同期処理の結果
    func syncToFirebase() async -> Result<Void, SportsNoteError> {
        await syncToFirebaseDefault(context: "TaskViewModel-syncToFirebase")
    }
}
