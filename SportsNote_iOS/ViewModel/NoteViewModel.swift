import Combine
import Foundation
import RealmSwift
import UIKit

@MainActor
class NoteViewModel: ObservableObject, BaseViewModelProtocol, CRUDViewModelProtocol, FirebaseSyncable {
    typealias EntityType = Note
    @Published var notes: [Note] = []
    @Published var selectedNote: Note?
    @Published var practiceNotes: [Note] = []
    @Published var tournamentNotes: [Note] = []
    @Published var freeNotes: [Note] = []
    @Published var memos: [Memo] = []
    @Published var isLoading: Bool = false
    @Published var currentError: SportsNoteError?
    @Published var showingErrorAlert: Bool = false

    private let realmManager = RealmManager.shared
    private var cancellables = Set<AnyCancellable>()

    #if DEBUG
        /// テスト用: updateTaskReflectionsからのMemo Firebase同期呼び出しを記録する
        /// （実Firebase通信を伴わずに呼び出しの発生・isUpdate判定を検証するため）
        var memoSyncCallsForTesting: [(memoID: String, isUpdate: Bool)] = []
    #endif

    init() {
        // 初期化のみ実行、データ取得はView側で明示的に実行
        observeClearAllData(cancellables: &cancellables)
    }

    /// Realmオブジェクトの参照をクリア
    func clearRealmReferences() {
        notes = []
        selectedNote = nil
        practiceNotes = []
        tournamentNotes = []
        freeNotes = []
        memos = []
    }

    // MARK: - READ処理

    /// ノート一覧を取得
    /// - Returns: Result
    func fetchData() async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        // Realm操作はMainActorで実行
        let allNotes = realmManager.getNotes()
        if let freeNote = realmManager.getFreeNote() {
            if !allNotes.contains(where: { $0.noteID == freeNote.noteID }) {
                notes = [freeNote] + allNotes
            } else {
                notes = allNotes
            }
        } else {
            notes = allNotes
        }
        return .success(())
    }

    /// ターゲット画面用: フリーノートを除外してノートを取得
    /// - Returns: Result
    func fetchNotesExcludingFree() async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        // フリーノートを除外したノートのみ取得（getNotes()は既にフリーノート除外済み）
        let allNotes = realmManager.getNotes()
        notes = allNotes
        return .success(())
    }

    /// ノートを取得
    /// - Parameter id: noteID
    func loadNote(id: String) {
        Task {
            isLoading = true
            defer { isLoading = false }

            let result = await fetchById(id: id)
            switch result {
            case .success(let note):
                selectedNote = note
                loadMemos()
            case .failure(let error):
                showErrorAlert(error)
            }
        }
    }

    /// ノートに紐づくメモを取得
    private func loadMemos() {
        if let noteID = selectedNote?.noteID {
            memos = realmManager.getMemosByNoteID(noteID: noteID)
        }
    }

    /// IDでエンティティを取得
    /// - Parameter id: エンティティのID
    /// - Returns: Result
    func fetchById(id: String) async -> Result<Note?, SportsNoteError> {
        await fetchByIdDefault(id: id, context: "NoteViewModel-fetchById")
    }

    /// ノートタイプを取得（同期的）
    /// - Parameter noteID: ノートID
    /// - Returns: NoteType（取得失敗時はnil）
    func getNoteType(noteID: String) -> NoteType? {
        guard let note = try? realmManager.getObjectById(id: noteID, type: Note.self) else {
            return nil
        }
        return NoteType(rawValue: note.noteType)
    }

    // MARK: - CREATE, UPDATE処理

    /// エンティティを保存
    /// - Parameters:
    ///   - entity: 保存するNote
    ///   - isUpdate: 更新フラグ
    /// - Returns: Result
    func save(_ entity: Note, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // 更新時は、エンティティ再構築時にUserDefaultsの現在値で上書きされてしまったuserIDを、
            // Realmに永続化済みの値に戻す（アカウント作成直後のuserID切替タイミングでも
            // Firebase更新が正しいドキュメントIDに対して行われるようにするため。issue #74）
            if isUpdate, let existingNote = try realmManager.getObjectById(id: entity.noteID, type: Note.self) {
                entity.userID = existingNote.userID
            }

            // Realm操作はMainActorで実行
            try realmManager.saveItem(entity)

            // Firebase同期はバックグラウンドで実行
            if isOnlineAndLoggedIn {
                performBackgroundSync(entity, isUpdate: isUpdate)
            }

            // UI更新
            let result = await fetchData()
            return result
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "NoteViewModel-save")
            return .failure(sportsNoteError)
        }
    }

    /// ノート保存処理(新規作成と更新を兼ねる)
    /// - Parameters:
    ///   - noteID: ノートID（更新時に指定、新規作成時はnil）
    ///   - noteType: ノートタイプ（練習、大会、フリー）
    ///   - title: タイトル（フリーノート用）
    ///   - purpose: 目的（練習ノート用）
    ///   - detail: 詳細（練習ノート用）
    ///   - target: 目標（大会ノート用）
    ///   - consciousness: 意識点（大会ノート用）
    ///   - result: 結果（大会ノート用）
    ///   - reflection: 振り返り
    ///   - condition: コンディション
    ///   - date: 日付
    ///   - weather: 天気
    ///   - temperature: 気温
    ///   - created_at: 作成日時
    /// - Returns: 保存したノート
    @discardableResult
    func saveNote(
        noteID: String? = nil,
        noteType: NoteType,
        title: String? = nil,
        purpose: String? = nil,
        detail: String? = nil,
        target: String? = nil,
        consciousness: String? = nil,
        result: String? = nil,
        reflection: String? = nil,
        condition: String? = nil,
        date: Date? = nil,
        weather: Weather? = nil,
        temperature: Int? = nil,
        created_at: Date? = nil
    ) -> Note {
        // 新しいNoteオブジェクトを作成または既存のIDを再利用
        let note = Note()

        if let id = noteID {
            // 既存ノートの更新の場合、IDを設定
            note.noteID = id
        }

        // ノートタイプの設定
        note.noteType = noteType.rawValue

        // 既存のノートからデータを取得
        if let id = noteID, let existingNote = try? realmManager.getObjectById(id: id, type: Note.self) {
            // 既存の値で初期化（明示的に上書きされない限り保持される）
            note.title = existingNote.title
            note.purpose = existingNote.purpose
            note.detail = existingNote.detail
            note.target = existingNote.target
            note.consciousness = existingNote.consciousness
            note.result = existingNote.result
            note.reflection = existingNote.reflection
            note.condition = existingNote.condition
            note.date = existingNote.date
            note.weather = existingNote.weather
            note.temperature = existingNote.temperature
            note.created_at = existingNote.created_at
            note.userID = existingNote.userID
        } else {
            // 新規ノートの場合
            note.created_at = created_at ?? Date()
        }

        // 各ノートタイプに応じたフィールド設定（パラメータで明示的に指定されたもののみ上書き）
        if let title = title {
            note.title = title
        }

        if let purpose = purpose {
            note.purpose = purpose
        }

        if let detail = detail {
            note.detail = detail
        }

        if let target = target {
            note.target = target
        }

        if let consciousness = consciousness {
            note.consciousness = consciousness
        }

        if let result = result {
            note.result = result
        }

        if let reflection = reflection {
            note.reflection = reflection
        }

        if let condition = condition {
            note.condition = condition
        }

        if let date = date {
            note.date = date
        }

        if let weather = weather {
            note.weather = weather.rawValue
        }

        if let temperature = temperature {
            note.temperature = temperature
        }

        // 更新日時は必ず現在の時刻
        note.updated_at = Date()

        // 新しいResultパターンを使用して保存
        Task {
            let isUpdate = noteID != nil
            let result = await save(note, isUpdate: isUpdate)
            if case .failure(let error) = result {
                showErrorAlert(error)
            }
        }

        return note
    }

    /// 練習ノートの保存処理とタスクリフレクションの更新
    /// - Parameters:
    ///   - noteID: ノートID（更新時に指定、新規作成時はnil）
    ///   - purpose: 目的
    ///   - detail: 詳細
    ///   - reflection: 振り返り
    ///   - condition: コンディション
    ///   - date: 日付
    ///   - weather: 天気
    ///   - temperature: 気温
    ///   - created_at: 作成日時
    ///   - taskReflections: タスクの振り返り（キー: TaskListData, 値: 振り返りテキスト）
    func savePracticeNoteWithReflections(
        noteID: String? = nil,
        purpose: String,
        detail: String,
        reflection: String? = nil,
        condition: String? = nil,
        date: Date = Date(),
        weather: Weather = .sunny,
        temperature: Int = 0,
        created_at: Date? = nil,
        taskReflections: [TaskListData: String] = [:]
    ) {
        // ノートを保存
        let note = savePracticeNote(
            noteID: noteID,
            purpose: purpose,
            detail: detail,
            reflection: reflection,
            condition: condition,
            date: date,
            weather: weather,
            temperature: temperature,
            created_at: created_at
        )

        // タスクリフレクションを更新
        updateTaskReflections(noteID: note.noteID, taskReflections: taskReflections)
    }

    /// 練習ノートの保存処理
    @discardableResult
    private func savePracticeNote(
        noteID: String? = nil,
        purpose: String,
        detail: String,
        reflection: String? = nil,
        condition: String? = nil,
        date: Date = Date(),
        weather: Weather = .sunny,
        temperature: Int = 0,
        created_at: Date? = nil
    ) -> Note {
        return saveNote(
            noteID: noteID,
            noteType: .practice,
            purpose: purpose,
            detail: detail,
            reflection: reflection,
            condition: condition,
            date: date,
            weather: weather,
            temperature: temperature,
            created_at: created_at
        )
    }

    /// 課題の振り返りメモを保存・更新
    /// - Parameters:
    ///   - noteID: ノートID
    ///   - taskReflections: タスクの振り返り（キー: TaskListData, 値: 振り返りテキスト）
    private func updateTaskReflections(noteID: String, taskReflections: [TaskListData: String]) {
        for (task, reflectionText) in taskReflections {
            let memo = Memo()
            var existingCreatedAt: Date?
            // 既存メモが元々紐づいていた対策ID。対策の優先度変更後にノートを保存しても、
            // 既存メモの紐付け対策を上書きしないため（issue #160）
            var existingMeasuresID: String?
            var isExistingMemo = false

            // memoIDの決定ロジック:
            // 1. task.memoIDがあればそれを使用(既存メモ編集)
            // 2. なければnoteID+measuresIDで既存メモを検索
            // 3. 既存メモが見つかればそのIDを使用(更新)
            // 4. なければ新規ID生成(新規作成)
            if let existingMemoID = task.memoID {
                memo.memoID = existingMemoID
                isExistingMemo = true
                // 既存メモをRealmから取得し、created_at・measuresIDを引き継ぐ
                let existingMemo = try? realmManager.getObjectById(id: existingMemoID, type: Memo.self)
                existingCreatedAt = existingMemo?.created_at
                existingMeasuresID = existingMemo?.measuresID
            } else {
                let existingMemos = realmManager.getMemosByNoteID(noteID: noteID)
                // task.measuresID（現在の最優先対策のID）だけでなく、taskIDに紐づく
                // 全対策のmeasuresIDのいずれかで検索する。対策の並び替えで最優先対策が
                // 変わった後も、既存メモを同一課題のものとして正しく検出するため（issue #109）
                let taskMeasuresIDs = Set(
                    realmManager.getMeasuresByTaskID(taskID: task.taskID).map { $0.measuresID })
                if let existingMemo = existingMemos.first(where: {
                    taskMeasuresIDs.contains($0.measuresID)
                }) {
                    memo.memoID = existingMemo.memoID  // 既存IDを使用
                    isExistingMemo = true
                    // 検索でヒットした既存メモのcreated_at・measuresIDを引き継ぐ
                    existingCreatedAt = existingMemo.created_at
                    existingMeasuresID = existingMemo.measuresID
                } else {
                    memo.memoID = UUIDGenerator.generateID()  // 新規生成
                }
            }

            // 既存メモがない状態で空文字のままの場合は新規メモを作成しない。
            // 既存メモを空文字に編集するケースは保存対象とする（issue #105）
            if !isExistingMemo && reflectionText.isEmpty { continue }

            // 既存メモを更新する場合は元々紐づいていた対策IDを維持し、
            // 新規作成時のみ現在の最優先対策IDを採用する（issue #160）
            memo.measuresID = existingMeasuresID ?? task.measuresID
            memo.noteID = noteID
            memo.detail = reflectionText
            // 既存メモを更新する場合はcreated_atを維持し、新規作成時のみ現在時刻とする
            memo.created_at = existingCreatedAt ?? Date()
            try? realmManager.saveItem(memo)

            // Firebase同期はバックグラウンドで実行
            // existingCreatedAtが設定されている場合のみ既存メモの更新(isUpdate=true)、
            // それ以外は新規作成(isUpdate=false)。memoIDの決定ロジックと同じ判定材料を再利用する
            performMemoBackgroundSync(memo, isUpdate: existingCreatedAt != nil)
        }

        // メモを再読み込み
        loadMemos()
    }

    /// 課題振り返りメモ(Memo)をFirebaseに同期する
    /// NoteViewModelのFirebaseSyncable.EntityTypeはNoteのため、
    /// Memoの同期にはperformBackgroundSync(EntityType用)を使えず専用の同期処理を持つ
    /// - Parameters:
    ///   - memo: 同期するメモ
    ///   - isUpdate: 更新かどうか
    /// - Returns: 同期処理の結果
    func syncMemoToFirebase(_ memo: Memo, isUpdate: Bool) async -> Result<Void, SportsNoteError> {
        guard isOnlineAndLoggedIn else { return .success(()) }

        do {
            if isUpdate {
                try await FirebaseManager.shared.updateMemo(memo: memo)
            } else {
                try await FirebaseManager.shared.saveMemo(memo: memo)
            }
            return .success(())
        } catch {
            return .failure(ErrorMapper.mapFirebaseError(error, context: "NoteViewModel-syncMemoToFirebase"))
        }
    }

    /// 課題振り返りメモのFirebase同期をバックグラウンドで実行する
    /// - Parameters:
    ///   - memo: 同期するメモ
    ///   - isUpdate: 更新かどうか
    private func performMemoBackgroundSync(_ memo: Memo, isUpdate: Bool) {
        #if DEBUG
            memoSyncCallsForTesting.append((memoID: memo.memoID, isUpdate: isUpdate))
        #endif
        Task {
            let result = await syncMemoToFirebase(memo, isUpdate: isUpdate)
            if case .failure(let error) = result, currentError == nil {
                showErrorAlert(error)
            }
        }
    }

    /// 大会ノートの保存処理
    @discardableResult
    func saveTournamentNote(
        noteID: String? = nil,
        target: String,
        consciousness: String,
        result: String,
        reflection: String? = nil,
        condition: String? = nil,
        date: Date = Date(),
        weather: Weather = .sunny,
        temperature: Int = 0,
        created_at: Date? = nil
    ) -> Note {
        return saveNote(
            noteID: noteID,
            noteType: .tournament,
            target: target,
            consciousness: consciousness,
            result: result,
            reflection: reflection,
            condition: condition,
            date: date,
            weather: weather,
            temperature: temperature,
            created_at: created_at
        )
    }

    /// フリーノートの保存処理
    @discardableResult
    func saveFreeNote(
        noteID: String? = nil,
        title: String,
        detail: String,
        created_at: Date? = nil
    ) -> Note {
        return saveNote(
            noteID: noteID,
            noteType: .free,
            title: title,
            detail: detail,
            created_at: created_at
        )
    }

    // MARK: - DELETE処理

    /// エンティティを削除
    /// - Parameter id: 削除するエンティティのID
    /// - Returns: Result
    func delete(id: String) async -> Result<Void, SportsNoteError> {
        // フリーノートの削除を防ぐ（共通処理呼び出し前に判定）
        if let note = notes.first(where: { $0.noteID == id }),
            note.noteType == NoteType.free.rawValue
        {
            return .failure(.systemError(LocalizedStrings.cannotDeleteFreeNote))
        }

        return await deleteDefault(
            id: id,
            context: "NoteViewModel-delete",
            removeFromLocalCache: {
                // UI更新
                self.notes.removeAll(where: { $0.noteID == id })
            }
            // 元実装通りhideErrorAlert()は呼ばない
        )
    }

    /// エンティティをFirebaseに同期
    /// - Parameters:
    ///   - entity: 同期するエンティティ
    ///   - isUpdate: 更新フラグ
    /// - Returns: Result
    func syncEntityToFirebase(_ entity: Note, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
        await syncEntityToFirebaseDefault(
            isUpdate: isUpdate,
            context: "NoteViewModel-syncEntityToFirebase",
            updateAction: { try await FirebaseManager.shared.updateNote(note: entity) },
            saveAction: { try await FirebaseManager.shared.saveNote(note: entity) }
        )
    }

    /// 全データをFirebaseに同期
    /// - Returns: Result
    func syncToFirebase() async -> Result<Void, SportsNoteError> {
        await syncToFirebaseDefault(context: "NoteViewModel-syncToFirebase")
    }

    /// ノートのインジケーター色を取得（練習: グループカラー、大会: オレンジ、フリー: ブルー）
    /// - Parameters:
    ///   - noteID: ノートID
    ///   - noteType: ノート種別
    /// - Returns: インジケーター色（UIColor）
    func getNoteIndicatorColor(noteID: String, noteType: NoteType) -> UIColor {
        switch noteType {
        case .free:
            return .systemGray
        case .practice:
            return realmManager.getNoteBackgroundColor(noteID: noteID)
        case .tournament:
            return .systemOrange
        }
    }

    /// ノートを文字列で検索
    /// - Parameter query: 検索文字列
    func searchNotes(query: String) {
        let searchResults = realmManager.searchNotesByQuery(query: query)
        notes = searchResults
    }

    /// ノートを日付でフィルタリング
    /// - Parameter date: 日付
    /// - Returns: [Note]
    func filterNotesByDate(_ date: Date) -> [Note] {
        return realmManager.getNotesByDate(selectedDate: date)
    }

    /// 指定した日付でノート一覧を更新
    /// - Parameter date: フィルタリングする日付
    func updateNotesByDate(_ date: Date) {
        notes = filterNotesByDate(date)
    }

    /// noteIDに紐づくメモ一覧を取得
    /// - Parameter noteID: ノートID
    /// - Returns: [Memo]
    func getMemosByNoteID(noteID: String) -> [Memo] {
        return realmManager.getMemosByNoteID(noteID: noteID)
    }

}
