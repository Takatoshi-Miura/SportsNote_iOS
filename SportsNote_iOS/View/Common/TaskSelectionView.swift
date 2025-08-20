import RealmSwift
import SwiftUI

/// 取り組んだ課題の選択画面
struct TaskSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taskViewModel = TaskViewModel()

    var onTaskSelected: (TaskListData) -> Void
    var addedTaskIds: Set<String>
    private var incompleteTasks: [TaskListData] {
        return taskViewModel.taskListData.filter { !$0.isComplete && $0.measuresID != "" }
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
                            HStack {
                                TaskRow(taskList: task, isComplete: false)

                                Spacer()

                                // 追加済みの課題にはラベル表示
                                if addedTaskIds.contains(task.taskID) {
                                    Text(LocalizedStrings.added)
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .disabled(addedTaskIds.contains(task.taskID))
                        .listRowBackground(
                            addedTaskIds.contains(task.taskID) ? Color(.systemGray5) : Color(.systemBackground))
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
