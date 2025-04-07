import SwiftUI
import RealmSwift

// 基本情報セクション
struct BasicInfoSection: View {
    @Binding var date: Date
    @Binding var selectedWeather: Weather
    @Binding var temperature: Int
    let onUpdate: () -> Void
    
    var body: some View {
        Section(header: Text(LocalizedStrings.basicInfo)) {
            // 日付
            DatePicker(
                LocalizedStrings.date,
                selection: $date,
                displayedComponents: [.date]
            )
            .onChange(of: date) { _ in
                onUpdate()
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
                    onUpdate()
                }
            }
            
            // 気温
            HStack {
                Text(LocalizedStrings.temperature)
                Spacer()
                Stepper("\(temperature) °C", value: $temperature, in: -30...50)
                    .onChange(of: temperature) { _ in
                        onUpdate()
                    }
            }
        }
    }
}

// テキストエディタセクション
struct TextEditorSection: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let onUpdate: () -> Void
    
    var body: some View {
        Section(header: Text(title)) {
            AutoResizingTextEditor(text: $text, placeholder: placeholder, minHeight: 50)
                .onChange(of: text) { _ in
                    onUpdate()
                }
        }
    }
}

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
        GeometryReader { geometry in
            ZStack {
                if viewModel.isLoadingNote {
                    VStack {
                        Text("Loading note...")
                            .foregroundColor(.gray)
                            .italic()
                        ProgressView()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    Form {
                        BasicInfoSection(
                            date: $date,
                            selectedWeather: $selectedWeather,
                            temperature: $temperature,
                            onUpdate: updateNote
                        )
                        
                        TextEditorSection(
                            title: LocalizedStrings.condition,
                            placeholder: LocalizedStrings.condition,
                            text: $condition,
                            onUpdate: updateNote
                        )
                        
                        TextEditorSection(
                            title: LocalizedStrings.target,
                            placeholder: LocalizedStrings.target,
                            text: $target,
                            onUpdate: updateNote
                        )
                        
                        TextEditorSection(
                            title: LocalizedStrings.consciousness,
                            placeholder: LocalizedStrings.consciousness,
                            text: $consciousness,
                            onUpdate: updateNote
                        )
                        
                        TextEditorSection(
                            title: LocalizedStrings.result,
                            placeholder: LocalizedStrings.result,
                            text: $result,
                            onUpdate: updateNote
                        )
                        
                        TextEditorSection(
                            title: LocalizedStrings.reflection,
                            placeholder: LocalizedStrings.reflection,
                            text: $reflection,
                            onUpdate: updateNote
                        )
                    }
                    .navigationTitle(LocalizedStrings.tournamentNote)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                if let note = viewModel.selectedNote {
                                    viewModel.deleteNote(id: note.noteID)
                                    // dismiss()
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
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
