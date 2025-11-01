import SwiftUI

// ノートリストセクション
struct NoteListSection: View {
    let notes: [Note]
    let date: Date

    var body: some View {
        VStack(alignment: .leading) {
            // ノート数を表示
            Text("\(LocalizedStrings.note) (\(notes.count))")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)
                .frame(maxWidth: .infinity, alignment: .leading)

            if notes.isEmpty {
                Text("ノートがありません")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(notes, id: \.noteID) { note in
                        NavigationLink(destination: noteDestination(for: note)) {
                            NoteRow(note: note)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .frame(minHeight: 200)
                .padding(.horizontal, 8)
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func noteDestination(for note: Note) -> some View {
        switch NoteType(rawValue: note.noteType) {
        case .free:
            FreeNoteView(noteID: note.noteID)
                .onDisappear {
                    // 詳細画面から戻ったときに日付で再フィルタリング
                    NotificationCenter.default.post(
                        name: NSNotification.Name("RefreshSelectedDateNotes"),
                        object: nil,
                        userInfo: ["date": date]
                    )
                }
        case .practice:
            PracticeNoteView(noteID: note.noteID)
                .onDisappear {
                    // 詳細画面から戻ったときに日付で再フィルタリング
                    NotificationCenter.default.post(
                        name: NSNotification.Name("RefreshSelectedDateNotes"),
                        object: nil,
                        userInfo: ["date": date]
                    )
                }
        case .tournament:
            TournamentNoteView(noteID: note.noteID)
                .onDisappear {
                    // 詳細画面から戻ったときに日付で再フィルタリング
                    NotificationCenter.default.post(
                        name: NSNotification.Name("RefreshSelectedDateNotes"),
                        object: nil,
                        userInfo: ["date": date]
                    )
                }
        case .none:
            Text("なし")
        }
    }
}
