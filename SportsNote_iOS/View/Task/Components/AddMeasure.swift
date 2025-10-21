import SwiftUI

/// 対策追加コンポーネント
struct AddMeasureView: View {
    @Binding var newMeasureTitle: String
    let onAddAction: () -> Void

    var body: some View {
        HStack {
            TextField(String(format: LocalizedStrings.inputTitle, LocalizedStrings.measures), text: $newMeasureTitle)
            Button(action: onAddAction) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
            }
            .disabled(newMeasureTitle.isEmpty)
        }
    }
}
