import SwiftUI
import RealmSwift

/// 取り組んだ課題の選択画面
struct TaskSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taskViewModel = TaskViewModel()
    
    var onTaskSelected: (TaskListData) -> Void
    var addedTaskIds: Set<String> // 追加済みの課題IDを保持
    
    // 未完了のタスクをフィルタリングするコンピューテッドプロパティを追加
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
                    // 複雑なフィルタリング条件をコンピューテッドプロパティに移動
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
                            }
                        }
                        .disabled(addedTaskIds.contains(task.taskID))
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
