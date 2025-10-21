import SwiftUI

/// 対策セクションのヘッダーコンポーネント
struct MeasuresSectionHeaderView: View {
    @Binding var isReorderingMeasures: Bool

    var body: some View {
        HStack {
            Text(LocalizedStrings.measuresPriority)
            Spacer()
            Button(action: {
                isReorderingMeasures.toggle()
            }) {
                Text(isReorderingMeasures ? LocalizedStrings.complete : LocalizedStrings.sort)
                    .foregroundColor(.blue)
            }
        }
    }
}
