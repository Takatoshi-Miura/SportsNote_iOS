import RealmSwift
import SwiftUI

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

    init() {
        // 初期化のみ実行、データ取得はView側で明示的に実行
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

    /// ノートを取得
    /// - Parameter id: noteID
    func loadNote(id: String) {
        Task {
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
        do {
            let note = try realmManager.getObjectById(id: id, type: Note.self)
            return .success(note)
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "NoteViewModel-fetchById")
            return .failure(sportsNoteError)
        }
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
            // Realm操作はMainActorで実行
            try realmManager.saveItem(entity)

            // Firebase同期はバックグラウンドで実行
            if isOnlineAndLoggedIn {
                Task {
                    let result = await syncEntityToFirebase(entity, isUpdate: isUpdate)
                    if case .failure(let error) = result, currentError == nil {
                        await MainActor.run {
                            showErrorAlert(error)
                        }
                    }
                }
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
            if reflectionText.isEmpty { continue }

            let memo = Memo()
            memo.memoID = task.memoID ?? UUID().uuidString
            memo.measuresID = task.measuresID
            memo.noteID = noteID
            memo.detail = reflectionText
            try? realmManager.saveItem(memo)
        }

        // メモを再読み込み
        loadMemos()
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
        isLoading = true
        defer { isLoading = false }

        do {
            // フリーノートの削除を防ぐ
            if let note = notes.first(where: { $0.noteID == id }),
                note.noteType == NoteType.free.rawValue
            {
                return .failure(.systemError("フリーノートは削除できません"))
            }

            // Realm操作はMainActorで実行
            try realmManager.logicalDelete(id: id, type: Note.self)

            // Firebase同期はバックグラウンドで実行
            if isOnlineAndLoggedIn {
                Task {
                    do {
                        if let deletedNote = try realmManager.getObjectById(id: id, type: Note.self) {
                            let result = await syncEntityToFirebase(deletedNote, isUpdate: true)
                            if case .failure(let error) = result, currentError == nil {
                                await MainActor.run {
                                    showErrorAlert(error)
                                }
                            }
                        }
                    } catch {
                        // ログのみ
                    }
                }
            }

            // UI更新
            notes.removeAll(where: { $0.noteID == id })
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "NoteViewModel-delete")
            return .failure(sportsNoteError)
        }
    }

    /// エンティティをFirebaseに同期
    /// - Parameters:
    ///   - entity: 同期するエンティティ
    ///   - isUpdate: 更新フラグ
    /// - Returns: Result
    func syncEntityToFirebase(_ entity: Note, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
        guard isOnlineAndLoggedIn else { return .success(()) }

        do {
            if isUpdate {
                try await FirebaseManager.shared.updateNote(note: entity)
            } else {
                try await FirebaseManager.shared.saveNote(note: entity)
            }
            return .success(())
        } catch {
            return .failure(ErrorMapper.mapFirebaseError(error, context: "NoteViewModel-syncEntityToFirebase"))
        }
    }

    /// 全データをFirebaseに同期
    /// - Returns: Result
    func syncToFirebase() async -> Result<Void, SportsNoteError> {
        guard isOnlineAndLoggedIn else { return .success(()) }

        do {
            let allNotes = try realmManager.getDataList(clazz: Note.self)
            for note in allNotes {
                let result = await syncEntityToFirebase(note)
                if case .failure = result {
                    // 1つでも失敗したら処理を続行するがエラーを返す
                    return result
                }
            }
            return .success(())
        } catch {
            return .failure(convertToSportsNoteError(error, context: "NoteViewModel-syncToFirebase"))
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

}
