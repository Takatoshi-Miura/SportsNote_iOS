import SwiftUI

struct TaskView: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        TabTopView(
            isMenuOpen: $isMenuOpen,
            title: LocalizedStrings.task,
            destination: TaskDetailView(),
            leadingItem: {
                MenuButton(isMenuOpen: $isMenuOpen)
            },
            trailingItem: {},
            content: {
                VStack {
                    Text("Custom Content for Task View")
                    Text("Additional Content")
                }
            },
            actionItems: [
                (LocalizedStrings.group, {}),
                (LocalizedStrings.task, {})
            ]
        )
    }
}
