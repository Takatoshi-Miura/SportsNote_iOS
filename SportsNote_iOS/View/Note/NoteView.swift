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
                    // 背景色をsecondarySystemBackgroundに設定
                    Color(.secondarySystemBackground)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 0) {
                        // SearchBarViewは既存の背景色を維持
                        SearchBarView(searchText: $searchQuery) {
                            viewModel.fetchNotes()
                        }
                        
                        // NoteListViewは既存の背景色を維持
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
        .onAppear {
            viewModel.fetchNotes()
        }
    }
}

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
                    NavigationLink(destination: destinationView(for: note)) {
                        NoteRow(note: note)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteNote(id: note.noteID)
                        } label: {
                            Label(LocalizedStrings.delete, systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    private func destinationView(for note: Note) -> some View {
        switch NoteType(rawValue: note.noteType) {
        case .free:
            FreeNoteView(noteID: note.noteID)
        case .practice:
            PracticeNoteView(noteID: note.noteID)
        case .tournament:
            TournamentNoteView(noteID: note.noteID)
        case .none:
            Text("Unknown note type")
        }
    }
}

struct NoteRow: View {
    let note: Note
    
    var body: some View {
        HStack(spacing: 12) {
            // Note type indicator
            noteTypeIndicator
                .padding(.vertical, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                // Note type and date on top row
                HStack {
                    noteTypeLabel
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Date
                    Text(formatDate(note.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Content preview
                Text(noteContent)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
    
    // Note type indicator with color
    private var noteTypeIndicator: some View {
        VStack(spacing: 0) {
            noteTypeIcon
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(noteTypeColor)
                .cornerRadius(8)
        }
    }
    
    // Note type label with specific styling based on note type
    private var noteTypeLabel: some View {
        Text(noteTypeName)
            .font(.headline)
            .lineLimit(1)
    }
    
    // Icon for each note type
    private var noteTypeIcon: some View {
        switch NoteType(rawValue: note.noteType) {
        case .free:
            return Image(systemName: "pin.fill")
        case .practice:
            return Image(systemName: "figure.run")
        case .tournament:
            return Image(systemName: "trophy")
        case .none:
            return Image(systemName: "questionmark")
        }
    }
    
    // Color for each note type
    private var noteTypeColor: Color {
        switch NoteType(rawValue: note.noteType) {
        case .free:
            return Color.blue
        case .practice:
            return Color.green
        case .tournament:
            return Color.orange
        case .none:
            return Color.gray
        }
    }
    
    // Name for each note type
    private var noteTypeName: String {
        switch NoteType(rawValue: note.noteType) {
        case .free:
            return note.title.isEmpty ? LocalizedStrings.freeNote : note.title
        case .practice:
            return LocalizedStrings.practiceNote
        case .tournament:
            return LocalizedStrings.tournamentNote
        case .none:
            return ""
        }
    }
    
    // Formatted note content based on type
    private var noteContent: String {
        switch NoteType(rawValue: note.noteType) {
        case .free:
            return note.detail
        case .practice:
            return note.detail.isEmpty ? note.purpose : note.detail
        case .tournament:
            return note.result.isEmpty ? note.target : note.result
        case .none:
            return ""
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

struct NoteSectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            
            if content.isEmpty {
                Text("No content")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                Text(content)
                    .font(.body)
            }
        }
        .padding(.horizontal)
    }
}

struct WeatherView: View {
    let weatherType: Weather
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: weatherIcon())
                .foregroundColor(weatherColor())
            
            Text(weatherType.title)
                .font(.subheadline)
        }
    }
    
    private func weatherIcon() -> String {
        switch weatherType {
        case .sunny:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .rainy:
            return "cloud.rain.fill"
        }
    }
    
    private func weatherColor() -> Color {
        switch weatherType {
        case .sunny:
            return .yellow
        case .cloudy:
            return .gray
        case .rainy:
            return .blue
        }
    }
}

struct MemoCardView: View {
    let memo: Memo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(memo.detail)
                .font(.body)
                .lineLimit(nil)
            
            HStack {
                Spacer()
                Text(formatDate(memo.created_at))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
