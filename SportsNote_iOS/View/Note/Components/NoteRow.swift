import SwiftUI

/// ノートセル
struct NoteRow: View {
    let note: Note
    let viewModel: NoteViewModel

    /// ノートのインジケーター色
    private var indicatorColor: Color {
        let noteType = NoteType(rawValue: note.noteType) ?? .free
        return Color(viewModel.getNoteIndicatorColor(noteID: note.noteID, noteType: noteType))
    }

    var body: some View {
        let noteType = NoteType(rawValue: note.noteType) ?? .free

        HStack(spacing: 12) {
            noteTypeIndicator
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 4) {
                if noteType == .free {
                    // フリーノート: タイトル + 詳細
                    Text(noteType.displayTitle(from: note))
                        .font(.headline)
                        .lineLimit(1)

                    Text(noteType.content(from: note))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    // 練習・大会ノート: 内容 + 日付
                    Text(noteType.content(from: note))
                        .font(.headline)
                        .lineLimit(1)

                    Text(DateFormatterUtil.formatDateWithDayOfWeek(note.date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                .background(indicatorColor)
                .cornerRadius(8)
        }
    }
}
