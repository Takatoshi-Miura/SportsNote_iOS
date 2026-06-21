import SwiftUI

/// ノート一覧
struct NoteListView: View {
    @ObservedObject var viewModel: NoteViewModel

    var body: some View {
        List {
            if viewModel.notes.isEmpty {
                Text(LocalizedStrings.noNotesFound)
                    .foregroundColor(.gray)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.notes, id: \.noteID) { note in
                    let noteType = NoteType(rawValue: note.noteType) ?? .free
                    NavigationLink(value: note.noteID) {
                        NoteRow(note: note, viewModel: viewModel)
                    }
                    .if(noteType != .free) { view in
                        view.swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task {
                                    let result = await viewModel.delete(id: note.noteID)
                                    if case .failure(let error) = result {
                                        viewModel.showErrorAlert(error)
                                    }
                                }
                            } label: {
                                Label(LocalizedStrings.delete, systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: String.self) { noteID in
            // noteIDから該当するNoteを検索して適切な画面を表示
            if let note = viewModel.notes.first(where: { $0.noteID == noteID }) {
                let noteType = NoteType(rawValue: note.noteType) ?? .free
                destinationView(noteType: noteType, noteID: noteID)
            }
        }
    }

    /// ノート種別に応じた遷移先Viewを返す
    @ViewBuilder
    private func destinationView(noteType: NoteType, noteID: String) -> some View {
        switch noteType {
        case .free:
            FreeNoteView(noteID: noteID)
        case .practice:
            PracticeNoteView(noteID: noteID)
        case .tournament:
            TournamentNoteView(noteID: noteID)
        }
    }
}
