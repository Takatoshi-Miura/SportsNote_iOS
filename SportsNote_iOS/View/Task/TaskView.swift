import SwiftUI

struct TaskView: View {
    var body: some View {
        TabTopView(
            title: LocalizedStrings.task,
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
                (LocalizedStrings.task, {})
            ]
        )
    }
}
