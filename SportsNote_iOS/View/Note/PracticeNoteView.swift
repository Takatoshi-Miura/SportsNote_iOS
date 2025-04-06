import SwiftUI
import RealmSwift

struct PracticeNoteView: View {
    let noteID: String
    @StateObject private var viewModel = NoteViewModel()
    @StateObject private var taskViewModel = TaskViewModel()
    
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
                    Text("Loading note...")
                        .foregroundColor(.gray)
                        .italic()
                    ProgressView()
                }
            } else {
                Form {
                    // 基本情報
                    Section(header: Text(LocalizedStrings.basicInfo)) {
                        // 日付
                        DatePicker(
                            LocalizedStrings.date,
                            selection: $date,
                            displayedComponents: [.date]
                        )
                        .onChange(of: date) { _ in
                            updateNote()
                        }
                        
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
                            .onChange(of: selectedWeather) { _ in
                                updateNote()
                            }
                        }
                        
                        // 気温
                        HStack {
                            Text(LocalizedStrings.temperature)
                            Spacer()
                            Stepper("\(temperature) °C", value: $temperature, in: -30...50)
                                .onChange(of: temperature) { _ in
                                    updateNote()
                                }
                        }
                    }
                    
                    // 体調
                    Section(header: Text(LocalizedStrings.condition)) {
                        AutoResizingTextEditor(text: $condition, placeholder: LocalizedStrings.condition, minHeight: 50)
                            .onChange(of: condition) { _ in
                                updateNote()
                            }
                    }
                    
                    // 目的
                    Section(header: Text(LocalizedStrings.purpose)) {
                        AutoResizingTextEditor(text: $purpose, placeholder: LocalizedStrings.purpose, minHeight: 50)
                            .onChange(of: purpose) { _ in
                                updateNote()
                            }
                    }
                    
                    // 内容
                    Section(header: Text(LocalizedStrings.practiceDetail)) {
                        AutoResizingTextEditor(text: $detail, placeholder: LocalizedStrings.practiceDetail, minHeight: 50)
                            .onChange(of: detail) { _ in
                                updateNote()
                            }
                    }
                    
                    // 取り組んだ課題
                    Section(header: Text(LocalizedStrings.taskReflection)) {
                        TaskListSection(taskReflections: $taskReflections, unaddedTasks: getUnaddedTasks())
                            .onChange(of: taskReflections) { _ in
                                updateNote()
                            }
                    }
                    
                    // 反省
                    Section(header: Text(LocalizedStrings.reflection)) {
                        AutoResizingTextEditor(text: $reflection, placeholder: LocalizedStrings.reflection, minHeight: 50)
                            .onChange(of: reflection) { _ in
                                updateNote()
                            }
                    }
                }
            }
        }
        .navigationTitle(LocalizedStrings.practiceNote)
        .navigationBarTitleDisplayMode(.inline)
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
        return taskViewModel.taskListData.filter { !$0.isComplete && !addedTaskIds.contains($0.taskID) }
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
}
