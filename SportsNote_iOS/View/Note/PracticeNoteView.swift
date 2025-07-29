import RealmSwift
import SwiftUI

struct PracticeNoteView: View {
    let noteID: String
    @StateObject private var viewModel = NoteViewModel()
    @StateObject private var taskViewModel = TaskViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false

    // 編集用の状態変数
    @State private var date: Date = Date()
    @State private var selectedWeather: Weather = .sunny
    @State private var temperature: Int = 20
    @State private var condition: String = ""
    @State private var purpose: String = ""
    @State private var detail: String = ""
    @State private var reflection: String = ""
    @State private var taskReflections: [TaskListData: String] = [:]

    var body: some View {
        ZStack {
            if viewModel.isLoadingNote {
                VStack {
                    Text(LocalizedStrings.loading)
                        .foregroundColor(.gray)
                        .italic()
                    ProgressView()
                }
            } else {
                Form {
                    // 基本情報
                    BasicInfoSection(
                        date: $date,
                        selectedWeather: $selectedWeather,
                        temperature: $temperature,
                        onUpdate: updateNote
                    )

                    // 体調
                    TextEditorSection(
                        title: LocalizedStrings.condition,
                        placeholder: LocalizedStrings.condition,
                        text: $condition,
                        onUpdate: updateNote
                    )

                    // 目的
                    TextEditorSection(
                        title: LocalizedStrings.purpose,
                        placeholder: LocalizedStrings.purpose,
                        text: $purpose,
                        onUpdate: updateNote
                    )

                    // 内容
                    TextEditorSection(
                        title: LocalizedStrings.practiceDetail,
                        placeholder: LocalizedStrings.practiceDetail,
                        text: $detail,
                        onUpdate: updateNote
                    )

                    // 取り組んだ課題
                    Section(header: Text(LocalizedStrings.taskReflection)) {
                        TaskListSection(taskReflections: $taskReflections, unaddedTasks: getUnaddedTasks())
                            .onChange(of: taskReflections) { _ in
                                updateNote()
                            }
                    }

                    // 反省
                    TextEditorSection(
                        title: LocalizedStrings.reflection,
                        placeholder: LocalizedStrings.reflection,
                        text: $reflection,
                        onUpdate: updateNote
                    )
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            }
        }
        .navigationTitle(LocalizedStrings.practiceNote)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text(LocalizedStrings.deleteNote),
                message: Text(LocalizedStrings.deleteNoteConfirmation),
                primaryButton: .destructive(Text(LocalizedStrings.delete)) {
                    if let note = viewModel.selectedNote {
                        viewModel.deleteNote(id: note.noteID)
                        dismiss()
                    }
                },
                secondaryButton: .cancel(Text(LocalizedStrings.cancel))
            )
        }
        .onAppear {
            loadData()
        }
        .onChange(of: viewModel.selectedNote) { newNote in
            if let note = newNote {
                self.purpose = note.purpose
                self.detail = note.detail
                self.reflection = note.reflection
                self.condition = note.condition
                self.date = note.date
                self.selectedWeather = Weather(rawValue: note.weather) ?? .sunny
                self.temperature = note.temperature
                loadTaskReflections(note: note)
            }
        }
    }

    private func loadData() {
        viewModel.loadNote(id: noteID)
        viewModel.loadMemos()
        taskViewModel.fetchAllTasks()
    }

    /// 未追加のタスクを取得
    private func getUnaddedTasks() -> [TaskListData] {
        let addedTaskIds = Set(taskReflections.keys.map { $0.taskID })
        return taskViewModel.taskListData.filter {
            !$0.isComplete && !addedTaskIds.contains($0.taskID) && $0.measuresID != ""
        }
    }

    // タスクのリフレクションをロードする
    private func loadTaskReflections(note: Note) {
        taskReflections.removeAll()

        // ノートに関連するメモを取得
        let noteMemos = viewModel.memos.filter { $0.noteID == note.noteID }

        // 各メモをタスクに関連付け
        for memo in noteMemos {
            // TaskListDataをmeasuresIDで検索
            if let taskIndex = taskViewModel.taskListData.firstIndex(where: { $0.measuresID == memo.measuresID }) {
                // 元のタスクを取得
                let task = taskViewModel.taskListData[taskIndex]

                // TaskListDataを変更するためにカスタムTaskListDataを作成
                let taskWithMemo = TaskListData(
                    taskID: task.taskID,
                    groupID: task.groupID,
                    groupColor: task.groupColor,
                    title: task.title,
                    measuresID: task.measuresID,
                    measures: task.measures,
                    memoID: memo.memoID,
                    order: task.order,
                    isComplete: task.isComplete
                )
                taskReflections[taskWithMemo] = memo.detail
            } else {
                print("No matching task found for memo.measuresID: \(memo.measuresID)")
            }
        }
    }

    // ノート更新処理
    private func updateNote() {
        guard !viewModel.isLoadingNote, let note = viewModel.selectedNote else { return }

        viewModel.savePracticeNoteWithReflections(
            noteID: note.noteID,
            purpose: purpose,
            detail: detail,
            reflection: reflection,
            condition: condition,
            date: date,
            weather: selectedWeather,
            temperature: temperature,
            taskReflections: taskReflections
        )
    }

    /// キーボードを閉じる
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
