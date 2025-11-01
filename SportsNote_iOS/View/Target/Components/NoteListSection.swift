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
                            TargetNoteRow(note: note)
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

/// ターゲット画面用ノート行の表示
private struct TargetNoteRow: View {
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

                    Text(DateFormatterUtil.formatDateOnly(note.date))
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
