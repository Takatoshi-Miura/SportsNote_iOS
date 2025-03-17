import SwiftUI
import RealmSwift

struct EditFreeNoteView: View {
    @Environment(\.dismiss) private var dismiss
    let note: Note
    var onSave: () -> Void
    
    @State private var title: String
    
    init(note: Note, onSave: @escaping () -> Void) {
        self.note = note
        self.onSave = onSave
        
        _title = State(initialValue: note.title)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("Title", text: $title)
                }
            }
            .navigationTitle("Edit Free Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStrings.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.save) {
                        updateNote()
                    }
                }
            }
        }
    }
    
    private func updateNote() {
        do {
            let realm = try Realm()
            if let noteToUpdate = realm.object(ofType: Note.self, forPrimaryKey: note.noteID) {
                try realm.write {
                    noteToUpdate.title = title
                    noteToUpdate.updated_at = Date()
                }
                onSave()
                dismiss()
            }
        } catch {
            print("Error updating free note: \(error)")
        }
    }
}
