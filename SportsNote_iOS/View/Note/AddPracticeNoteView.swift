import SwiftUI
import RealmSwift

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
                Section(header: Text(LocalizedStrings.basicInfo)) {
                    // 日付
                    DatePicker(
                        LocalizedStrings.date,
                        selection: $date,
                        displayedComponents: [.date]
                    )
                    // 天気
                    HStack {
                        Text(LocalizedStrings.weather)
                        Spacer()
                        Picker("", selection: $selectedWeather) {
                            ForEach(Weather.allCases, id: \.self) { weather in
                                HStack {
                                    Image(systemName: weather.icon)
                                    Text(weather.title)
                                }
                                .tag(weather)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    // 気温
                    HStack {
                        Text(LocalizedStrings.temperature)
                        Spacer()
                        Stepper("\(temperature) °C", value: $temperature, in: -30...50)
                    }
                }
                // 体調
                Section(header: Text(LocalizedStrings.condition)) {
                    AutoResizingTextEditor(text: $condition, placeholder: LocalizedStrings.condition, minHeight: 50)
                }
                // 練習の目的
                Section(header: Text(LocalizedStrings.purpose)) {
                    AutoResizingTextEditor(text: $purpose, placeholder: LocalizedStrings.purpose, minHeight: 50)
                }
                // 練習内容
                Section(header: Text(LocalizedStrings.practiceDetail)) {
                    AutoResizingTextEditor(text: $detail, placeholder: LocalizedStrings.practiceDetail, minHeight: 50)
                }
                // 取り組んだ課題
                Section(header: Text(LocalizedStrings.taskReflection)) {
                    TaskListSection(
                        taskReflections: $taskReflections,
                        unaddedTasks: getUnaddedTasks()
                    )
                }
                // 反省
                Section(header: Text(LocalizedStrings.reflection)) {
                    AutoResizingTextEditor(text: $reflection, placeholder: LocalizedStrings.reflection, minHeight: 50)
                }
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
                taskViewModel.fetchAllTasks()
                // 未完了の課題を全て追加
                taskViewModel.taskListData.forEach { task in
                    if !task.isComplete {
                        taskReflections[task] = ""
                    }
                }
            }
        }
    }
    
    /// 未追加のタスクを取得
    private func getUnaddedTasks() -> [TaskListData] {
        let addedTaskIds = Set(taskReflections.keys.map { $0.taskID })
        return taskViewModel.taskListData.filter { !$0.isComplete && !addedTaskIds.contains($0.taskID) }
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
}
