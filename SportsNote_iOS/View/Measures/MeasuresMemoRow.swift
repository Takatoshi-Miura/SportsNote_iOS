import SwiftUI

/// 対策メモ行の共通コンポーネント
struct MeasuresMemoRow: View {
    let measuresMemo: MeasuresMemo

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(measuresMemo.detail)
                .font(.body)
                .lineLimit(nil)

            Text(DateFormatterUtil.formatDateAndTime(measuresMemo.date))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}
