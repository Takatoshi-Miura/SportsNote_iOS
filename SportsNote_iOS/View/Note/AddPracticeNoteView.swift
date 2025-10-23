import RealmSwift
import SwiftUI

struct AddPracticeNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var noteViewModel = NoteViewModel()

    var onSave: () -> Void

    @State private var purpose: String = ""
    @State private var detail: String = ""
    @State private var reflection: String = ""
    @State private var condition: String = ""
    @State private var date: Date = Date()
    @State private var selectedWeather: Weather = .sunny
    @State private var temperature: Int = 20
    @State private var taskReflections: [TaskListData: String] = [:]

    var body: some View {
        NavigationView {
            Form {
                // 基本情報
                BasicInfoSection(
                    date: $date,
                    selectedWeather: $selectedWeather,
                    temperature: $temperature,
                    onUpdate: {}
                )

                // 体調
                TextEditorSection(
                    title: LocalizedStrings.condition,
                    placeholder: LocalizedStrings.condition,
                    text: $condition,
                    onUpdate: {}
                )

                // 目的
                TextEditorSection(
                    title: LocalizedStrings.purpose,
                    placeholder: LocalizedStrings.purpose,
                    text: $purpose,
                    onUpdate: {}
                )

                // 内容
                TextEditorSection(
                    title: LocalizedStrings.practiceDetail,
                    placeholder: LocalizedStrings.practiceDetail,
                    text: $detail,
                    onUpdate: {}
                )

                // 取り組んだ課題
                Section(header: Text(LocalizedStrings.taskReflection)) {
                    TaskListSection(
                        taskReflections: $taskReflections,
                        unaddedTasks: getUnaddedTasks()
                    )
                }

                // 反省
                TextEditorSection(
                    title: LocalizedStrings.reflection,
                    placeholder: LocalizedStrings.reflection,
                    text: $reflection,
                    onUpdate: {}
                )
            }
            .navigationTitle(String(format: LocalizedStrings.addTitle, LocalizedStrings.practiceNote))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // キャンセル
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStrings.cancel) {
                        dismiss()
                    }
                }
                // 保存
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.save) {
                        saveNote()
                    }
                }
            }
            .onAppear {
                Task {
                    _ = await taskViewModel.fetchData()
                    // 未完了かつmeasuresIDが空でないタスクを追加
                    taskViewModel.taskListData.forEach { task in
                        if !task.isComplete && task.measuresID != "" {
                            taskReflections[task] = ""
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            .allowsHitTesting(true)
        }
    }

    /// 未追加のタスクを取得
    private func getUnaddedTasks() -> [TaskListData] {
        let addedTaskIds = Set(taskReflections.keys.map { $0.taskID })
        return taskViewModel.getUnaddedTasks(excludingTaskIds: addedTaskIds)
    }

    /// 保存処理
    private func saveNote() {
        noteViewModel.savePracticeNoteWithReflections(
            purpose: purpose,
            detail: detail,
            reflection: reflection,
            condition: condition,
            date: date,
            weather: selectedWeather,
            temperature: temperature,
            taskReflections: taskReflections
        )

        onSave()
        dismiss()
    }

    /// キーボードを閉じる
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
