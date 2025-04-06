import SwiftUI
import RealmSwift

struct TournamentNoteView: View {
    let noteID: String
    @StateObject private var viewModel = NoteViewModel()
    @State private var memo = ""
    
    // 編集用の状態変数
    @State private var target: String = ""
    @State private var consciousness: String = ""
    @State private var result: String = ""
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
                    
                    // 目標
                    Section(header: Text(LocalizedStrings.target)) {
                        AutoResizingTextEditor(text: $target, placeholder: LocalizedStrings.target, minHeight: 50)
                            .onChange(of: target) { _ in
                                updateNote()
                            }
                    }
                    
                    // 意識すること
                    Section(header: Text(LocalizedStrings.consciousness)) {
                        AutoResizingTextEditor(text: $consciousness, placeholder: LocalizedStrings.consciousness, minHeight: 50)
                            .onChange(of: consciousness) { _ in
                                updateNote()
                            }
                    }
                    
                    // 結果
                    Section(header: Text(LocalizedStrings.result)) {
                        AutoResizingTextEditor(text: $result, placeholder: LocalizedStrings.result, minHeight: 50)
                            .onChange(of: result) { _ in
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
        .navigationTitle(LocalizedStrings.tournamentNote)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadData()
        }
        .onChange(of: viewModel.selectedNote) { newNote in
            if let note = newNote {
                self.target = note.target
                self.consciousness = note.consciousness
                self.result = note.result
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
    
    // ノート更新処理
    private func updateNote() {
        guard !viewModel.isLoadingNote, let note = viewModel.selectedNote else { return }
        
        viewModel.saveTournamentNote(
            noteID: note.noteID,
            target: target,
            consciousness: consciousness,
            result: result,
            reflection: reflection,
            condition: condition,
            date: date,
            weather: selectedWeather,
            temperature: temperature,
            created_at: note.created_at
        )
    }
}
