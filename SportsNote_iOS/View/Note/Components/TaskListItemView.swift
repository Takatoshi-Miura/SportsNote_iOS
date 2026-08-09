import SwiftUI

struct TaskListSection: View {
    @StateObject private var memoViewModel = MemoViewModel()
    @State private var showingTaskSelection = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedTaskForDeletion: TaskListData?

    @Binding var taskReflections: [TaskListData: String]
    var unaddedTasks: [TaskListData]
    /// ノートID（新規作成画面ではまだノートが保存されていないためnil）
    var noteID: String? = nil

    /// taskReflections.keysをtask.order昇順にソートした配列。
    /// Dictionaryの列挙順は不定（アプリ再起動のたびに変わりうる）のため、描画順の
    /// 安定化にはこちらを使う（issue #137）。orderはグループ内スコープで採番されるため
    /// 異なるグループの課題間で同値になり得る。taskIDを副次キーにして同値時の順序も
    /// 決定的にする
    private var sortedTasks: [TaskListData] {
        taskReflections.keys.sorted {
            $0.order != $1.order ? $0.order < $1.order : $0.taskID < $1.taskID
        }
    }

    var body: some View {
        let sortedTasks = sortedTasks
        return VStack(spacing: 0) {
            if taskReflections.isEmpty {
                emptyStateView
                    .disabled(true)
            } else {
                ForEach(sortedTasks, id: \.taskID) { task in
                    if task.taskID != sortedTasks.first?.taskID {
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
                    .contentShape(Rectangle())

                    if task.taskID != sortedTasks.last?.taskID {
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
                    Task {
                        let result: Result<Void, SportsNoteError>
                        if let deleteMemoID = task.memoID {
                            result = await memoViewModel.deleteMemo(memoID: deleteMemoID)
                        } else if let noteID = noteID {
                            // 新規追加直後の課題はtaskReflectionsのキーにmemoIDが反映されないため、
                            // noteID+measuresIDでRealm上の実メモを検索してから削除する
                            result = await memoViewModel.deleteMemoByNoteAndMeasures(
                                noteID: noteID,
                                measuresID: task.measuresID
                            )
                        } else {
                            // 未保存のノート（新規作成画面）ではRealmにメモがまだ存在しない
                            result = .success(())
                        }
                        if case .failure(let error) = result {
                            memoViewModel.showErrorAlert(error)
                        }
                    }
                    taskReflections.removeValue(forKey: task)
                }
            }
        } message: {
        }
        .errorAlert(
            currentError: $memoViewModel.currentError,
            showingAlert: $memoViewModel.showingErrorAlert
        )
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
        .contentShape(Rectangle())
        .allowsHitTesting(true)
    }
}

struct TaskListItemView: View {
    let task: TaskListData
    @Binding var reflection: String
    var onOptionClick: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                TaskRow(taskList: task, isComplete: false)
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
                .contentShape(Rectangle())
                .allowsHitTesting(true)
                .onTapGesture {
                    onOptionClick()
                }
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
        .contentShape(Rectangle())
    }
}
