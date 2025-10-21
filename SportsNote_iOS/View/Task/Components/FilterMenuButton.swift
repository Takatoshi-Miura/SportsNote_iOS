import SwiftUI

/// フィルターメニューボタン
struct FilterMenuButton: View {
    @Binding var showCompletedTasks: Bool

    var body: some View {
        Menu {
            Toggle(isOn: $showCompletedTasks) {
                Text(LocalizedStrings.showCompletedTasks)
            }
        } label: {
            Image(
                systemName: showCompletedTasks
                    ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"
            )
            .imageScale(.large)
        }
    }
}
