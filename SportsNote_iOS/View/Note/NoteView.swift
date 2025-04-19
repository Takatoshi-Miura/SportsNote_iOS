import SwiftUI

struct NoteView: View {
    @Binding var isMenuOpen: Bool
    @StateObject private var viewModel = NoteViewModel()
    @State private var isPracticeNotePresented = false
    @State private var isTournamentNotePresented = false
    @State private var searchQuery = ""
    
    var body: some View {
        TabTopView(
            title: LocalizedStrings.note,
            isMenuOpen: $isMenuOpen,
            trailingItem: { EmptyView() },
            content: {
                ZStack {
                    Color(.secondarySystemBackground)
                        .edgesIgnoringSafeArea(.all)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            hideKeyboard()
                        }
                    
                    VStack(spacing: 0) {
                        SearchBarView(searchText: $searchQuery) {
                            viewModel.fetchNotes()
                        }
                        NoteListView(viewModel: viewModel)
                            .background(Color(.systemBackground))
                            .refreshable {
                                if !searchQuery.isEmpty {
                                    viewModel.searchNotes(query: searchQuery)
                                } else {
                                    viewModel.fetchNotes()
                                }
                            }
                    }
                    .onChange(of: searchQuery) { newValue in
                        if (!newValue.isEmpty) {
                            viewModel.searchNotes(query: newValue)
                        } else {
                            viewModel.fetchNotes()
                        }
                    }
                }
            },
            actionItems: [
                (LocalizedStrings.practiceNote, { isPracticeNotePresented = true }),
                (LocalizedStrings.tournamentNote, { isTournamentNotePresented = true })
            ]
        )
        .sheet(isPresented: $isPracticeNotePresented) {
            AddPracticeNoteView(onSave: {
                viewModel.fetchNotes()
            })
        }
        .sheet(isPresented: $isTournamentNotePresented) {
            AddTournamentNoteView(onSave: {
                viewModel.fetchNotes()
            })
        }
    }
    
    /// キーボードを閉じる
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

/// 検索バー
struct SearchBarView: View {
    @Binding var searchText: String
    var onClear: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading)
            
            TextField(LocalizedStrings.searchNotes, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.vertical, 8)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    onClear()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing)
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .padding()
    }
    
    /// キーボードを閉じる
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

/// ノート一覧
struct NoteListView: View {
    @ObservedObject var viewModel: NoteViewModel
    @State private var selectedNoteID: String? = nil
    
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
                    NavigationLink(
                        tag: note.noteID,
                        selection: $selectedNoteID,
                        destination: { 
                            noteType.destinationView(noteID: note.noteID)
                                .onDisappear {
                                    // 詳細画面から戻ったときに選択状態を解除
                                    DispatchQueue.main.async {
                                        selectedNoteID = nil
                                    }
                                }
                        }
                    ) {
                        NoteRow(note: note)
                    }
                    .if(noteType != .free) { view in
                        view.swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteNote(id: note.noteID)
                            } label: {
                                Label(LocalizedStrings.delete, systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

/// ノートセル
struct NoteRow: View {
    let note: Note
    
    var body: some View {
        HStack(spacing: 12) {
            noteTypeIndicator
                .padding(.vertical, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    let noteType = NoteType(rawValue: note.noteType) ?? .free
                    Text(noteType.displayTitle(from: note))
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()

                    Text(formatDate(note.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                let noteType = NoteType(rawValue: note.noteType) ?? .free
                Text(noteType.content(from: note))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
    
    // Note type indicator with color
    private var noteTypeIndicator: some View {
        let noteType = NoteType(rawValue: note.noteType) ?? .free
        return VStack(spacing: 0) {
            Image(systemName: noteType.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(noteType.color)
                .cornerRadius(8)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

extension View {
    /// 条件付きでビューを修飾する
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
