import Combine
import Foundation
import SwiftUI

/// 対策詳細画面
struct MeasureDetailView: View {
    let measure: Measures
    @State private var title: String
    @State private var memo: String = ""
    @ObservedObject var measuresViewModel: MeasuresViewModel
    @ObservedObject var memoViewModel: MemoViewModel
    @ObservedObject var noteViewModel: NoteViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    init(
        measure: Measures,
        measuresViewModel: MeasuresViewModel,
        memoViewModel: MemoViewModel,
        noteViewModel: NoteViewModel
    ) {
        self.measure = measure
        _title = State(initialValue: measure.title)
        self.measuresViewModel = measuresViewModel
        self.memoViewModel = memoViewModel
        self.noteViewModel = noteViewModel
    }

    var body: some View {
        VStack {
            List {
                Section(header: Text(LocalizedStrings.title)) {
                    TextField(LocalizedStrings.title, text: $title)
                        .onChange(of: title) { newValue in
                            Task {
                                let result = await measuresViewModel.saveMeasures(
                                    measuresID: measure.measuresID,
                                    taskID: measure.taskID,
                                    title: newValue,
                                    order: measure.order,
                                    created_at: measure.created_at
                                )
                                if case .failure(let error) = result {
                                    measuresViewModel.showErrorAlert(error)
                                }
                            }
                        }
                }
                .dismissKeyboardOnTap()

                Section(header: Text(LocalizedStrings.note)) {
                    if memoViewModel.measuresMemoList.isEmpty {
                        Text(LocalizedStrings.noNotesYet)
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(memoViewModel.measuresMemoList, id: \.memoID) { measuresMemo in
                            NavigationLink(destination: destinationView(for: measuresMemo.noteID)) {
                                MeasuresMemoRow(measuresMemo: measuresMemo)
                            }
                        }
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
                        let result = await measuresViewModel.delete(id: measure.measuresID)
                        if case .failure(let error) = result {
                            measuresViewModel.showErrorAlert(error)
                        } else {
                            dismiss()
                        }
                    }
                },
                secondaryButton: .cancel(Text(LocalizedStrings.cancel))
            )
        }
        .errorAlert(
            currentError: $measuresViewModel.currentError,
            showingAlert: $measuresViewModel.showingErrorAlert
        )
        .onAppear {
            Task {
                _ = await memoViewModel.fetchMemosByMeasuresID(measuresID: measure.measuresID)
            }
        }
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
