import SwiftUI
import RealmSwift

@MainActor
class NoteViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var selectedNote: Note?
    @Published var practiceNotes: [Note] = []
    @Published var tournamentNotes: [Note] = []
    @Published var freeNotes: [Note] = []
    @Published var memos: [Memo] = []
    @Published var isLoadingNote: Bool = false
    
    private let realmManager = RealmManager.shared
    
    init() {
        fetchNotes()
    }
    
    // MARK: - Fetch Methods
    
    func fetchNotes() {
        let allNotes = realmManager.getNotes()
        if let freeNote = realmManager.getFreeNote() {
            if !allNotes.contains(where: { $0.noteID == freeNote.noteID }) {
                notes = [freeNote] + allNotes
                return
            }
        }
        notes = allNotes
        updateFilteredNotes()
    }
    
    private func updateFilteredNotes() {
        practiceNotes = notes.filter { $0.noteType == NoteType.practice.rawValue }
        tournamentNotes = notes.filter { $0.noteType == NoteType.tournament.rawValue }
        freeNotes = notes.filter { $0.noteType == NoteType.free.rawValue }
    }
    
    // MARK: - Search Methods
    
    func searchNotes(query: String) {
        let searchResults = realmManager.searchNotesByQuery(query: query)
        notes = searchResults
    }
    
    // MARK: - CRUD Operations
    
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
    ) {
        // 新しいNoteオブジェクトを作成または既存のIDを再利用
        let note = Note()
        
        if let id = noteID {
            // 既存ノートの更新の場合、IDを設定
            note.noteID = id
        }
        
        // ノートタイプの設定
        note.noteType = noteType.rawValue
        
        // 既存のノートからデータを取得
        if let id = noteID, let existingNote = realmManager.getObjectById(id: id, type: Note.self) {
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
        
        // Realmに保存
        realmManager.saveItem(note)
        
        // データの再取得
        if noteID == nil {
            fetchNotes()
        } else {
            loadNote(id: note.noteID)
        }
    }
    
    func deleteNote(id: String) {
        // Don't allow deleting free note
        if let note = notes.first(where: { $0.noteID == id }),
           note.noteType == NoteType.free.rawValue {
            return
        }
        
        realmManager.logicalDelete(id: id, type: Note.self)
        notes.removeAll(where: { $0.noteID == id })
        updateFilteredNotes()
    }
    
    /// 練習ノートの保存処理
    func savePracticeNote(
        noteID: String? = nil,
        purpose: String,
        detail: String,
        reflection: String? = nil,
        condition: String? = nil,
        date: Date = Date(),
        weather: Weather = .sunny,
        temperature: Int = 0,
        created_at: Date? = nil
    ) {
        saveNote(
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
    
    /// 大会ノートの保存処理
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
    ) {
        saveNote(
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
    func saveFreeNote(
        noteID: String? = nil,
        title: String,
        detail: String,
        created_at: Date? = nil
    ) {
        saveNote(
            noteID: noteID,
            noteType: .free,
            title: title,
            detail: detail,
            created_at: created_at
        )
    }
    
    // MARK: - Filter Methods
    
    func filterNotesByGroup(_ groupId: String) -> [Note] {
        return notes.filter { $0.noteID == groupId }
    }
    
    func filterNotesByDate(_ date: Date) -> [Note] {
        // RealmManagerに処理を委譲し、日付でのフィルタリングを確実に行う
        return realmManager.getNotesByDate(selectedDate: date)
    }
    
    // MARK: - Note Detail Methods
    
    func loadNote(id: String) {
        isLoadingNote = true
        selectedNote = realmManager.getObjectById(id: id, type: Note.self)
        loadMemos()
        isLoadingNote = false
    }
    
    func loadNote() {
        isLoadingNote = true
        if let id = selectedNote?.noteID {
            selectedNote = realmManager.getObjectById(id: id, type: Note.self)
            loadMemos()
        }
        isLoadingNote = false
    }
    
    func loadMemos() {
        if let noteID = selectedNote?.noteID {
            memos = realmManager.getMemosByNoteID(noteID: noteID)
        }
    }
    
}
