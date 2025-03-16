import SwiftUI

struct TaskView: View {
    @Binding var isMenuOpen: Bool

    var body: some View {
        TabTopView(
            title: LocalizedStrings.task,
            isMenuOpen: $isMenuOpen,
            trailingItem: {},
            content: {
                VStack {
                    NavigationLink(destination: TaskDetailView()) {
                        Text("Go to Task Detail")
                    }
                    Text("Custom Content for Task View")
                    Text("Additional Content")
                }
            },
            actionItems: [
                (LocalizedStrings.group, {}),
                (LocalizedStrings.task, { TermsManager.showDialog() })
            ]
        )
        .overlay(TermsDialogView())
    }
}
