import SwiftUI
import RealmSwift

struct AddTournamentNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NoteViewModel()
    
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
        viewModel.saveTournamentNote(
            target: target,
            consciousness: consciousness,
            result: result,
            reflection: reflection,
            condition: condition,
            date: date,
            weather: selectedWeather,
            temperature: temperature
        )
        
        onSave()
        dismiss()
    }
}
