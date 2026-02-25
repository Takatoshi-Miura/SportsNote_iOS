import SwiftUI

/// 並び替えトグルボタン
struct ReorderButton: View {
    @Binding var isReorderMode: Bool

    var body: some View {
        Button {
            isReorderMode.toggle()
        } label: {
            Image(
                systemName: isReorderMode
                    ? "arrow.up.arrow.down.circle.fill"
                    : "arrow.up.arrow.down.circle"
            )
            .imageScale(.large)
        }
    }
}
