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
                            // 空白のみのタイトルで即時保存されるのを防ぐ（issue #133）
                            guard !newValue.isBlank else { return }
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(LocalizedStrings.close) {
                    KeyboardUtil.hideKeyboard()
                }
            }
        }
        .deleteConfirmationAlert(
            isPresented: $showDeleteConfirmation,
            title: LocalizedStrings.delete,
            message: String(format: LocalizedStrings.deleteMeasures),
            onDelete: { await measuresViewModel.delete(id: measure.measuresID) },
            onFailure: { measuresViewModel.showErrorAlert($0) },
            onSuccess: { dismiss() }
        )
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
            noteDestinationView(noteType: noteType, noteID: noteID)
        } else {
            Text(LocalizedStrings.noteNotFound)
        }
    }
}
