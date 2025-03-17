import SwiftUI

struct FreeNoteView: View {
    let noteID: String
    @StateObject private var viewModel = NoteViewModel()
    @State private var isEditMode = false
    @State private var memo = ""
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                if let note = viewModel.selectedNote {
                    // Free note content
                    Text(note.title)
                        .font(.title)
                        .padding(.horizontal)
                    
                    // Memos section
                    Text("Memos")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    if viewModel.memos.isEmpty {
                        Text("No memos yet")
                            .foregroundColor(.gray)
                            .italic()
                            .padding(.horizontal)
                    } else {
                        ForEach(viewModel.memos, id: \.memoID) { memo in
                            MemoCardView(memo: memo)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Add memo
                    HStack {
                        TextField("Add a memo", text: $memo)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button {
                            addMemo()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .imageScale(.large)
                        }
                        .disabled(memo.isEmpty)
                    }
                    .padding(.horizontal)
                } else {
                    Text("Note not found")
                        .foregroundColor(.gray)
                        .italic()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Free Note")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("Edit") {
            isEditMode = true
        })
        .sheet(isPresented: $isEditMode) {
            if let note = viewModel.selectedNote {
                EditFreeNoteView(note: note) {
                    viewModel.loadNote()
                }
            }
        }
        .onAppear {
            viewModel.loadNote(id: noteID)
        }
    }
    
    private func addMemo() {
        guard !memo.isEmpty, let note = viewModel.selectedNote else { return }
        
        let newMemo = Memo(
            measuresID: "",
            noteID: note.noteID,
            detail: memo
        )
        newMemo.noteDate = note.date
        
        RealmManager.shared.saveItem(newMemo)
        viewModel.loadMemos()
        
        memo = ""
    }
}