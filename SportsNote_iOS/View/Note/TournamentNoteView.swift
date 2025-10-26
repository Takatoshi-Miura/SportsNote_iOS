import SwiftUI

/// 大会ノート詳細画面
struct TournamentNoteView: View {
    let noteID: String
    @StateObject private var viewModel = NoteViewModel()
    @State private var memo = ""
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false

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
                if viewModel.isLoading {
                    VStack {
                        Text(LocalizedStrings.loading)
                            .foregroundColor(.gray)
                            .italic()
                        ProgressView()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    Form {
                        // 基本情報
                        BasicInfoSection(
                            date: $date,
                            selectedWeather: $selectedWeather,
                            temperature: $temperature,
                            onUpdate: updateNote
                        )

                        // 体調
                        TextEditorSection(
                            title: LocalizedStrings.condition,
                            placeholder: LocalizedStrings.condition,
                            text: $condition,
                            onUpdate: updateNote
                        )

                        // 目標
                        TextEditorSection(
                            title: LocalizedStrings.target,
                            placeholder: LocalizedStrings.target,
                            text: $target,
                            onUpdate: updateNote
                        )

                        // 意識すること
                        TextEditorSection(
                            title: LocalizedStrings.consciousness,
                            placeholder: LocalizedStrings.consciousness,
                            text: $consciousness,
                            onUpdate: updateNote
                        )

                        // 結果
                        TextEditorSection(
                            title: LocalizedStrings.result,
                            placeholder: LocalizedStrings.result,
                            text: $result,
                            onUpdate: updateNote
                        )

                        // 反省
                        TextEditorSection(
                            title: LocalizedStrings.reflection,
                            placeholder: LocalizedStrings.reflection,
                            text: $reflection,
                            onUpdate: updateNote
                        )
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                    .navigationTitle(LocalizedStrings.tournamentNote)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showingDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .alert(isPresented: $showingDeleteConfirmation) {
                        Alert(
                            title: Text(LocalizedStrings.deleteNote),
                            message: Text(LocalizedStrings.deleteNoteConfirmation),
                            primaryButton: .destructive(Text(LocalizedStrings.delete)) {
                                if let note = viewModel.selectedNote {
                                    Task {
                                        let result = await viewModel.delete(id: note.noteID)
                                        if case .failure(let error) = result {
                                            viewModel.showErrorAlert(error)
                                        } else {
                                            dismiss()
                                        }
                                    }
                                }
                            },
                            secondaryButton: .cancel(Text(LocalizedStrings.cancel))
                        )
                    }
                }
            }
        }
        .onAppear {
            loadData()
        }
        .errorAlert(
            currentError: $viewModel.currentError,
            showingAlert: $viewModel.showingErrorAlert
        )
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
    }

    private func updateNote() {
        guard !viewModel.isLoading, let note = viewModel.selectedNote else { return }

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

    /// キーボードを閉じる
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
