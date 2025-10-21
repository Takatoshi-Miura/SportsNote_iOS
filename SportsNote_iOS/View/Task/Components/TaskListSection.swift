import SwiftUI

/// 課題セクション
struct MainTaskList: View {
    let taskListData: [TaskListData]
    let tasks: [TaskData]
    let onDelete: (String) -> Void
    let onToggleCompletion: (String) -> Void
    let refreshAction: () async -> Void
    // TaskViewModelを受け取るように追加
    let taskViewModel: TaskViewModel
    @State private var showDeleteConfirmation = false
    @State private var taskToDelete: String? = nil

    var body: some View {
        List {
            ForEach(taskListData, id: \.taskID) { taskList in
                NavigationLink(destination: getTaskDetailView(for: taskList)) {
                    TaskRow(
                        taskList: taskList,
                        isComplete: isTaskComplete(taskID: taskList.taskID)
                    )
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        taskToDelete = taskList.taskID
                        showDeleteConfirmation = true
                    } label: {
                        Label(LocalizedStrings.delete, systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        onToggleCompletion(taskList.taskID)
                    } label: {
                        let isComplete = isTaskComplete(taskID: taskList.taskID)
                        Label(
                            isComplete ? "Incomplete" : "Complete",
                            systemImage: isComplete ? "xmark.circle" : "checkmark.circle"
                        )
                    }
                    .tint(isTaskComplete(taskID: taskList.taskID) ? .orange : .green)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await refreshAction()
        }
        .alert(
            LocalizedStrings.delete,
            isPresented: $showDeleteConfirmation,
            actions: {
                Button(LocalizedStrings.cancel, role: .cancel) {}
                Button(LocalizedStrings.delete, role: .destructive) {
                    if let taskID = taskToDelete {
                        onDelete(taskID)
                    }
                }
            },
            message: {
                Text(LocalizedStrings.deleteTask)
            }
        )
    }

    private func isTaskComplete(taskID: String) -> Bool {
        return tasks.first(where: { $0.taskID == taskID })?.isComplete ?? false
    }

    private func getTaskDetailView(for taskList: TaskListData) -> AnyView {
        if let task = tasks.first(where: { $0.taskID == taskList.taskID }) {
            // シンプルに共有ViewModelを渡すのみで良い
            return TaskDetailView(viewModel: taskViewModel, taskData: task).eraseToAnyView()
        } else {
            return Text("Task not found").eraseToAnyView()
        }
    }
}
