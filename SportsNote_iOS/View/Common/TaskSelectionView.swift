import SwiftUI
import RealmSwift

/// 取り組んだ課題の選択画面
struct TaskSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taskViewModel = TaskViewModel()
    
    var onTaskSelected: (TaskListData) -> Void
    var addedTaskIds: Set<String>
    private var incompleteTasks: [TaskListData] {
        return taskViewModel.taskListData.filter { !$0.isComplete }
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
                                // グループカラー
                                Rectangle()
                                    .fill(Color(task.groupColor.color))
                                    .frame(width: 10)
                                    .padding(.vertical, 4)
                                
                                VStack(alignment: .leading) {
                                    // タイトル
                                    Text(task.title)
                                        .font(.body)
                                        .foregroundColor(addedTaskIds.contains(task.taskID) ? .gray : .primary)
                                    
                                    // 対策
                                    if !task.measures.isEmpty {
                                        Text(LocalizedStrings.measures + ":" + task.measures)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.leading, 4)
                                
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
                        .listRowBackground(addedTaskIds.contains(task.taskID) ? Color(.systemGray5) : Color(.systemBackground))
                    }
                }
            }
            .onAppear {
                taskViewModel.fetchAllTasks()
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
