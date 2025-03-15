import SwiftUI

struct TaskView: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        TabTopView(
            isMenuOpen: $isMenuOpen,
            title: "Task",
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
            buttonAction: {}
        )
    }
}
