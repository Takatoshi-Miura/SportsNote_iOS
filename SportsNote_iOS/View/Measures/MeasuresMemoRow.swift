import SwiftUI

/// 対策メモ行の共通コンポーネント
struct MeasuresMemoRow: View {
    let measuresMemo: MeasuresMemo

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(measuresMemo.detail)
                .font(.body)
                .lineLimit(nil)

            Text(formatDate(measuresMemo.date))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
