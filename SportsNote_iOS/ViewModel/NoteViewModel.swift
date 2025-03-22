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
    
    func createNote(title: String, type: NoteType, date: Date, content: String, groupId: String) {
        let note = Note()
        note.title = title
        note.noteType = type.rawValue
        note.date = date
        note.detail = content
        
        realmManager.saveItem(note)
        fetchNotes()
    }
    
    func updateNote(_ note: Note, title: String, content: String) {
        realmManager.saveItem(note)
        fetchNotes()
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
    
    // MARK: - Note Type Specific Operations
    
    func createPracticeNote(title: String, date: Date, content: String, groupId: String) {
        createNote(title: title, type: .practice, date: date, content: content, groupId: groupId)
    }
    
    func createTournamentNote(title: String, date: Date, content: String, groupId: String) {
        createNote(title: title, type: .tournament, date: date, content: content, groupId: groupId)
    }
    
    func createFreeNote(title: String, date: Date, content: String, groupId: String) {
        createNote(title: title, type: .free, date: date, content: content, groupId: groupId)
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
        selectedNote = realmManager.getObjectById(id: id, type: Note.self)
        loadMemos()
    }
    
    func loadNote() {
        if let id = selectedNote?.noteID {
            selectedNote = realmManager.getObjectById(id: id, type: Note.self)
            loadMemos()
        }
    }
    
    func loadMemos() {
        if let noteID = selectedNote?.noteID {
            memos = realmManager.getMemosByNoteID(noteID: noteID)
        }
    }
    
    func getNavigationTitle() -> String {
        guard let note = selectedNote else { return "Note" }
        
        switch NoteType(rawValue: note.noteType) {
        case .free:
            return "Free Note"
        case .practice:
            return "Practice Note"
        case .tournament:
            return "Tournament Note"
        case .none:
            return "Note"
        }
    }
}
