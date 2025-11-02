import SwiftUI

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

                // 目標
                TextEditorSection(
                    title: LocalizedStrings.target,
                    placeholder: LocalizedStrings.target,
                    text: $target,
                    onUpdate: {}
                )

                // 意識すること
                TextEditorSection(
                    title: LocalizedStrings.consciousness,
                    placeholder: LocalizedStrings.consciousness,
                    text: $consciousness,
                    onUpdate: {}
                )

                // 結果
                TextEditorSection(
                    title: LocalizedStrings.result,
                    placeholder: LocalizedStrings.result,
                    text: $result,
                    onUpdate: {}
                )

                // 反省
                TextEditorSection(
                    title: LocalizedStrings.reflection,
                    placeholder: LocalizedStrings.reflection,
                    text: $reflection,
                    onUpdate: {}
                )
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
            .dismissKeyboardOnTap()
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
