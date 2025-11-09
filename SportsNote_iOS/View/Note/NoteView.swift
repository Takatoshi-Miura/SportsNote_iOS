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
                        .dismissKeyboardOnTap()

                    VStack(spacing: 0) {
                        SearchBarView(searchText: $searchQuery) {
                            Task {
                                let result = await viewModel.fetchData()
                                if case .failure(let error) = result {
                                    viewModel.showErrorAlert(error)
                                }
                            }
                        }
                        NoteListView(viewModel: viewModel)
                            .background(Color(.systemBackground))
                            .refreshable {
                                if !searchQuery.isEmpty {
                                    viewModel.searchNotes(query: searchQuery)
                                } else {
                                    Task {
                                        let result = await viewModel.fetchData()
                                        if case .failure(let error) = result {
                                            viewModel.showErrorAlert(error)
                                        }
                                    }
                                }
                            }

                        // AdMobバナー広告
                        AdMobBannerView()
                            .frame(height: 50)
                            .background(Color(.systemBackground))
                    }
                    .onChange(of: searchQuery) { newValue in
                        if !newValue.isEmpty {
                            viewModel.searchNotes(query: newValue)
                        } else {
                            Task {
                                let result = await viewModel.fetchData()
                                if case .failure(let error) = result {
                                    viewModel.showErrorAlert(error)
                                }
                            }
                        }
                    }
                }
            },
            actionItems: [
                (LocalizedStrings.practiceNote, { isPracticeNotePresented = true }),
                (LocalizedStrings.tournamentNote, { isTournamentNotePresented = true }),
            ]
        )
        .sheet(isPresented: $isPracticeNotePresented) {
            AddPracticeNoteView(onSave: {
                Task {
                    let result = await viewModel.fetchData()
                    if case .failure(let error) = result {
                        viewModel.showErrorAlert(error)
                    }
                }
            })
        }
        .sheet(isPresented: $isTournamentNotePresented) {
            AddTournamentNoteView(onSave: {
                Task {
                    let result = await viewModel.fetchData()
                    if case .failure(let error) = result {
                        viewModel.showErrorAlert(error)
                    }
                }
            })
        }
        .task {
            let result = await viewModel.fetchData()
            if case .failure(let error) = result {
                viewModel.showErrorAlert(error)
            }
        }
        .errorAlert(
            currentError: $viewModel.currentError,
            showingAlert: $viewModel.showingErrorAlert
        )
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
}

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
                        NoteRow(note: note)
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

                    // フリーノート以外は日付を表示
                    if noteType != .free {
                        Text(DateFormatterUtil.formatDateOnly(note.date))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
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
                .background(colorForNoteType(noteType))
                .cornerRadius(8)
        }
    }

    /// ノート種別に対応する色を返す
    private func colorForNoteType(_ noteType: NoteType) -> Color {
        switch noteType {
        case .free: return .blue
        case .practice: return .green
        case .tournament: return .orange
        }
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
