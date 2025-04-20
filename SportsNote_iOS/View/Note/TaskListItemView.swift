import SwiftUI

struct TaskListSection: View {
    @State private var showingTaskSelection = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedTaskForDeletion: TaskListData?

    @Binding var taskReflections: [TaskListData: String]
    var unaddedTasks: [TaskListData]

    var body: some View {
        VStack(spacing: 0) {
            if taskReflections.isEmpty {
                emptyStateView
                    .disabled(true)
            } else {
                ForEach(Array(taskReflections.keys), id: \.taskID) { task in
                    if task.taskID != Array(taskReflections.keys).first?.taskID {
                        Divider()
                    }

                    TaskListItemView(
                        task: task,
                        reflection: .init(
                            get: { taskReflections[task] ?? "" },
                            set: { taskReflections[task] = $0 }
                        ),
                        onOptionClick: {
                            selectedTaskForDeletion = task
                            showingDeleteConfirmation = true
                        }
                    )

                    if task.taskID != Array(taskReflections.keys).last?.taskID {
                        Divider()
                    }
                }
            }
            // 課題追加ボタン
            addTaskButton
        }
        .background(Color.clear)
        .sheet(isPresented: $showingTaskSelection) {
            TaskSelectionView(
                onTaskSelected: { selectedTask in
                    taskReflections[selectedTask] = ""
                },
                addedTaskIds: Set(taskReflections.keys.map { $0.taskID })
            )
        }
        .alert(LocalizedStrings.deleteTaskFromNote, isPresented: $showingDeleteConfirmation) {
            Button(LocalizedStrings.cancel, role: .cancel) {}
            Button(LocalizedStrings.delete, role: .destructive) {
                if let task = selectedTaskForDeletion {
                    taskReflections.removeValue(forKey: task)
                }
            }
        } message: {}
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text(LocalizedStrings.noTasksWorkedOn)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
    }

    private var addTaskButton: some View {
        Button(action: {
            showingTaskSelection = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text(LocalizedStrings.addTask)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minWidth: 120)
            .background(unaddedTasks.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
            .foregroundColor(unaddedTasks.isEmpty ? .gray : .white)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(unaddedTasks.isEmpty)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
    }
}

struct TaskListItemView: View {
    let task: TaskListData
    @Binding var reflection: String
    var onOptionClick: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // グループカラー
                Rectangle()
                    .fill(Color(task.groupColor.color))
                    .frame(width: 10)
                    .frame(height: 50)
                    .disabled(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    // 課題タイトル
                    Text(task.title)
                        .font(.body)
                        .lineLimit(1)
                        .disabled(true)
                    
                    // 最優先の対策
                    if !task.measures.isEmpty {
                        Text(LocalizedStrings.measures + ":" + task.measures)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .disabled(true)
                    }
                }
                .padding(.leading, 4)
                .padding(.top, 2)
                .disabled(true)
                
                Spacer()
                
                // オプションボタン（削除）
                Button(action: onOptionClick) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .padding(8)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 44, height: 44)
            }
            
            // メモ入力欄
            AutoResizingTextEditor(
                text: $reflection,
                placeholder: String(format: LocalizedStrings.inputTitle, LocalizedStrings.reflection),
                minHeight: 50
            )
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.001))
    }
}
