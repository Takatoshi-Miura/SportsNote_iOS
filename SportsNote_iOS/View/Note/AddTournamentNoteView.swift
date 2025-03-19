import SwiftUI
import RealmSwift

struct AddTournamentNoteView: View {
    @Environment(\.dismiss) private var dismiss
    
    var onSave: () -> Void
    
    @State private var target: String = ""
    @State private var consciousness: String = ""
    @State private var result: String = ""
    @State private var reflection: String = ""
    @State private var condition: String = ""
    @State private var date: Date = Date()
    @State private var selectedWeather: Weather = .sunny
    @State private var temperature: Int = 20
    
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
                // 目標
                Section(header: Text(LocalizedStrings.target)) {
                    AutoResizingTextEditor(text: $target, placeholder: LocalizedStrings.target, minHeight: 50)
                }
                // 意識すること
                Section(header: Text(LocalizedStrings.consciousness)) {
                    AutoResizingTextEditor(text: $consciousness, placeholder: LocalizedStrings.consciousness, minHeight: 50)
                }
                // 結果
                Section(header: Text(LocalizedStrings.result)) {
                    AutoResizingTextEditor(text: $result, placeholder: LocalizedStrings.result, minHeight: 50)
                }
                // 反省
                Section(header: Text(LocalizedStrings.reflection)) {
                    AutoResizingTextEditor(text: $reflection, placeholder: LocalizedStrings.reflection, minHeight: 50)
                }
            }
            .navigationTitle(String(format: LocalizedStrings.addTitle, LocalizedStrings.tournamentNote))
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
        }
    }
    
    /// 保存処理
    private func saveNote() {
        let note = Note()
        note.noteType = NoteType.tournament.rawValue
        note.target = target
        note.consciousness = consciousness
        note.result = result
        note.reflection = reflection
        note.condition = condition
        note.date = date
        note.weather = selectedWeather.rawValue
        note.temperature = temperature
        
        // Save note to Realm
        RealmManager.shared.saveItem(note)
        
        // Callback and dismiss
        onSave()
        dismiss()
    }
}

struct EditTournamentNoteView: View {
    @Environment(\.dismiss) private var dismiss
    let note: Note
    var onSave: () -> Void
    
    @State private var target: String
    @State private var consciousness: String
    @State private var result: String
    @State private var reflection: String
    @State private var condition: String
    @State private var date: Date
    @State private var selectedWeather: Weather
    @State private var temperature: Int
    
    init(note: Note, onSave: @escaping () -> Void) {
        self.note = note
        self.onSave = onSave
        
        _target = State(initialValue: note.target)
        _consciousness = State(initialValue: note.consciousness)
        _result = State(initialValue: note.result)
        _reflection = State(initialValue: note.reflection)
        _condition = State(initialValue: note.condition)
        _date = State(initialValue: note.date)
        _selectedWeather = State(initialValue: Weather(rawValue: note.weather) ?? .sunny)
        _temperature = State(initialValue: note.temperature)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    DatePicker(
                        "Date",
                        selection: $date,
                        displayedComponents: [.date]
                    )
                    
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
                    
                    HStack {
                        Text(LocalizedStrings.temperature)
                        Spacer()
                        Stepper("\(temperature) °C", value: $temperature, in: -30...50)
                    }
                }
                
                Section(header: Text("Target")) {
                    AutoResizingTextEditor(text: $target, placeholder: "Target", minHeight: 100)
                }
                
                Section(header: Text("Consciousness")) {
                    AutoResizingTextEditor(text: $consciousness, placeholder: "Consciousness", minHeight: 120)
                }
                
                Section(header: Text("Condition")) {
                    AutoResizingTextEditor(text: $condition, placeholder: "Condition", minHeight: 80)
                }
                
                Section(header: Text("Result")) {
                    AutoResizingTextEditor(text: $result, placeholder: "Result", minHeight: 120)
                }
                
                Section(header: Text("Reflection")) {
                    AutoResizingTextEditor(text: $reflection, placeholder: "Reflection", minHeight: 150)
                }
            }
            .navigationTitle("Edit Tournament Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStrings.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.save) {
                        updateNote()
                    }
                }
            }
        }
    }
    
    private func updateNote() {
        do {
            let realm = try Realm()
            if let noteToUpdate = realm.object(ofType: Note.self, forPrimaryKey: note.noteID) {
                try realm.write {
                    noteToUpdate.target = target
                    noteToUpdate.consciousness = consciousness
                    noteToUpdate.result = result
                    noteToUpdate.reflection = reflection
                    noteToUpdate.condition = condition
                    noteToUpdate.date = date
                    noteToUpdate.weather = selectedWeather.rawValue
                    noteToUpdate.temperature = temperature
                    noteToUpdate.updated_at = Date()
                }
                onSave()
                dismiss()
            }
        } catch {
            print("Error updating note: \(error)")
        }
    }
}
