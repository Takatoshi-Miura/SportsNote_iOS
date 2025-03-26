import SwiftUI
import RealmSwift

struct PracticeNoteView: View {
    let noteID: String
    @StateObject private var viewModel = NoteViewModel()
    @State private var memo = ""
    
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
            }
        }
    }
    
    private func loadData() {
        viewModel.loadNote(id: noteID)
        viewModel.loadMemos()
    }
    
    // メモ追加機能
    private func addMemo() {
        guard !memo.isEmpty, let note = viewModel.selectedNote else { return }
        
        let newMemo = Memo(
            measuresID: "",
            noteID: note.noteID,
            detail: memo
        )
        newMemo.noteDate = note.date
        
        RealmManager.shared.saveItem(newMemo)
        viewModel.loadMemos()
        
        memo = ""
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
        } catch {
            print("Error updating note: \(error)")
        }
    }
}
