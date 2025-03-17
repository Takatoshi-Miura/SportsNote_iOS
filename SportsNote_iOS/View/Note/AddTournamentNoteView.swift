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
                                    Image(systemName: weatherIcon(for: weather))
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
                    TextEditor(text: $target)
                        .frame(height: 100)
                }
                
                Section(header: Text("Consciousness")) {
                    TextEditor(text: $consciousness)
                        .frame(height: 120)
                }
                
                Section(header: Text("Condition")) {
                    TextEditor(text: $condition)
                        .frame(height: 80)
                }
                
                Section(header: Text("Result")) {
                    TextEditor(text: $result)
                        .frame(height: 120)
                }
                
                Section(header: Text("Reflection")) {
                    TextEditor(text: $reflection)
                        .frame(height: 150)
                }
            }
            .navigationTitle(LocalizedStrings.tournamentNote)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStrings.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.save) {
                        saveNote()
                    }
                }
            }
        }
    }
    
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
    
    private func weatherIcon(for weather: Weather) -> String {
        switch weather {
        case .sunny:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .rainy:
            return "cloud.rain.fill"
        }
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
                                    Image(systemName: weatherIcon(for: weather))
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
                    TextEditor(text: $target)
                        .frame(height: 100)
                }
                
                Section(header: Text("Consciousness")) {
                    TextEditor(text: $consciousness)
                        .frame(height: 120)
                }
                
                Section(header: Text("Condition")) {
                    TextEditor(text: $condition)
                        .frame(height: 80)
                }
                
                Section(header: Text("Result")) {
                    TextEditor(text: $result)
                        .frame(height: 120)
                }
                
                Section(header: Text("Reflection")) {
                    TextEditor(text: $reflection)
                        .frame(height: 150)
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
    
    private func weatherIcon(for weather: Weather) -> String {
        switch weather {
        case .sunny:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .rainy:
            return "cloud.rain.fill"
        }
    }
}
