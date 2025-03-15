import SwiftUI

struct TaskView: View {
    var body: some View {
        TabTopView(
            title: LocalizedStrings.task,
            destination: TaskDetailView(),
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
