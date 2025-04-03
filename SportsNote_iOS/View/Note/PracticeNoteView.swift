import SwiftUI
import RealmSwift

struct PracticeNoteView: View {
    let noteID: String
    @StateObject private var viewModel = NoteViewModel()
    @StateObject private var taskViewModel = TaskViewModel()
    @State private var memo = ""
    @State private var taskReflections: [TaskListData: String] = [:]
    
    // 編集用の状態変数
    @State private var purpose: String = ""
    @State private var detail: String = ""
    @State private var reflection: String = ""
    @State private var condition: String = ""
    @State private var date: Date = Date()
    @State private var selectedWeather: Weather = .sunny
    @State private var temperature: Int = 20
    
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
                    // Basic Information Section
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
                        TaskListSection(
                            taskReflections: $taskReflections,
                            unaddedTasks: getUnaddedTasks()
                        )
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
        
        // ノートに関連するメモを取得して、taskReflectionsに設定
        let memos = viewModel.memos.filter { $0.noteID == note.noteID }
        for memo in memos {
            // measuresIDに課題IDが保存されている場合の処理
            if let task = taskViewModel.taskListData.first(where: { $0.taskID == memo.measuresID }) {
                taskReflections[task] = memo.detail
            }
        }
    }
    
    // ノート更新処理
    private func updateNote() {
        guard !viewModel.isLoadingNote, let note = viewModel.selectedNote else { return }
        
        do {
            let realm = try Realm()
            if let noteToUpdate = realm.object(ofType: Note.self, forPrimaryKey: note.noteID) {
                try realm.write {
                    noteToUpdate.purpose = purpose
                    noteToUpdate.detail = detail
                    noteToUpdate.reflection = reflection
                    noteToUpdate.condition = condition
                    noteToUpdate.date = date
                    noteToUpdate.weather = selectedWeather.rawValue
                    noteToUpdate.temperature = temperature
                    noteToUpdate.updated_at = Date()
                }
            }
            
            // タスクリフレクションを更新
            updateTaskReflections(noteID: note.noteID)
        } catch {
            print("Error updating note: \(error)")
        }
    }
    
    // タスクリフレクションを更新
    private func updateTaskReflections(noteID: String) {
        // 既存のメモを削除
        let memoViewModel = MemoViewModel()
        viewModel.memos
            .filter { $0.noteID == noteID && !$0.measuresID.isEmpty }
            .forEach { memoViewModel.deleteMemo(memoID: $0.memoID) }
        
        // 新しいメモを保存
        for (task, reflectionText) in taskReflections {
            if !reflectionText.isEmpty {
                _ = memoViewModel.saveMemo(
                    measuresID: task.taskID,
                    noteID: noteID,
                    detail: reflectionText
                )
            }
        }
        
        // メモを再読み込み
        viewModel.loadMemos()
    }
}
