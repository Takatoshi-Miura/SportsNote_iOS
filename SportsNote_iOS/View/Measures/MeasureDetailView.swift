import Combine
import Foundation
import SwiftUI

struct MeasureDetailView: View {
    let measure: Measures
    @State private var title: String
    @State private var memo: String = ""
    @StateObject private var viewModel: MeasuresViewModel
    @StateObject private var memoViewModel = MemoViewModel()
    @StateObject private var noteViewModel = NoteViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    init(measure: Measures) {
        self.measure = measure
        _title = State(initialValue: measure.title)
        _viewModel = StateObject(wrappedValue: MeasuresViewModel())
    }

    var body: some View {
        VStack {
            List {
                Section(header: Text(LocalizedStrings.title)) {
                    TextField(LocalizedStrings.title, text: $title)
                        .onChange(of: title) { newValue in
                            Task {
                                let result = await viewModel.saveMeasures(
                                    measuresID: measure.measuresID,
                                    taskID: measure.taskID,
                                    title: newValue,
                                    order: measure.order,
                                    created_at: measure.created_at
                                )
                                if case .failure(let error) = result {
                                    viewModel.showErrorAlert(error)
                                }
                            }
                        }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    KeyboardUtil.hideKeyboard()
                }

                Section(header: Text(LocalizedStrings.note)) {
                    switch memoViewModel.getMemosByMeasuresID(measuresID: measure.measuresID) {
                    case .success(let measuresMemos):
                        if measuresMemos.isEmpty {
                            Text(LocalizedStrings.noNotesYet)
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            ForEach(measuresMemos, id: \.memoID) { measuresMemo in
                                NavigationLink(destination: destinationView(for: measuresMemo.noteID)) {
                                    MeasuresMemoRow(measuresMemo: measuresMemo)
                                }
                            }
                        }
                    case .failure:
                        Text(LocalizedStrings.noNotesYet)
                            .foregroundColor(.gray)
                            .italic()
                    }
                }
            }
        }
        .navigationTitle(String(format: LocalizedStrings.detailTitle, LocalizedStrings.measures))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing:
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
        )
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text(LocalizedStrings.delete),
                message: Text(String(format: LocalizedStrings.deleteMeasures)),
                primaryButton: .destructive(Text(LocalizedStrings.delete)) {
                    Task {
                        let result = await viewModel.delete(id: measure.measuresID)
                        if case .failure(let error) = result {
                            viewModel.showErrorAlert(error)
                        } else {
                            dismiss()
                        }
                    }
                },
                secondaryButton: .cancel(Text(LocalizedStrings.cancel))
            )
        }
        .errorAlert(
            currentError: $viewModel.currentError,
            showingAlert: $viewModel.showingErrorAlert
        )
    }

    /// ノートIDに基づいて適切な遷移先を返す
    @ViewBuilder
    private func destinationView(for noteID: String) -> some View {
        if let noteType = noteViewModel.getNoteType(noteID: noteID) {
            switch noteType {
            case .free:
                FreeNoteView(noteID: noteID)
            case .practice:
                PracticeNoteView(noteID: noteID)
            case .tournament:
                TournamentNoteView(noteID: noteID)
            }
        } else {
            Text(LocalizedStrings.noteNotFound)
        }
    }
}
