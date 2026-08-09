import SwiftUI

/// 取り組んだ課題の選択画面
struct TaskSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taskViewModel = TaskViewModel()

    var onTaskSelected: (TaskListData) -> Void
    var addedTaskIds: Set<String>
    private var incompleteTasks: [TaskListData] {
        return taskViewModel.getUnaddedTasks(excludingTaskIds: addedTaskIds)
    }

    var body: some View {
        NavigationView {
            List {
                if taskViewModel.taskListData.isEmpty {
                    Text(LocalizedStrings.noTasksAvailable)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(incompleteTasks, id: \.taskID) { task in
                        Button(action: {
                            onTaskSelected(task)
                            dismiss()
                        }) {
                            TaskRow(taskList: task, isComplete: false)
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    _ = await taskViewModel.fetchData()
                }
            }
            .navigationTitle(LocalizedStrings.selectTask)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}
