import Combine
import Foundation
import RealmSwift
import SwiftUI

struct MeasureDetailView: View {
    let measure: Measures
    @State private var title: String
    @State private var memo: String = ""
    @StateObject private var viewModel: MeasuresViewModel
    @StateObject private var memoViewModel = MemoViewModel()
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
                            viewModel.saveMeasures(
                                measuresID: measure.measuresID,
                                taskID: measure.taskID,
                                title: newValue,
                                order: measure.order,
                                created_at: measure.created_at
                            )
                        }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }

                Section(header: Text(LocalizedStrings.note)) {
                    let measuresMemos = memoViewModel.getMemosByMeasuresID(measuresID: measure.measuresID)
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
                }
            }
        }
        .navigationTitle(String(format: LocalizedStrings.detailTitle, LocalizedStrings.measures))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text(LocalizedStrings.delete),
                message: Text(String(format: LocalizedStrings.deleteMeasures)),
                primaryButton: .destructive(Text(LocalizedStrings.delete)) {
                    viewModel.deleteMeasures(id: measure.measuresID)
                    dismiss()
                },
                secondaryButton: .cancel(Text(LocalizedStrings.cancel))
            )
        }
    }

    /// ノートIDに基づいて適切な遷移先を返す
    @ViewBuilder
    private func destinationView(for noteID: String) -> some View {
        if let note = RealmManager.shared.getObjectById(id: noteID, type: Note.self),
            let noteType = NoteType(rawValue: note.noteType)
        {
            noteType.destinationView(noteID: noteID)
        } else {
            Text(LocalizedStrings.noteNotFound)
        }
    }

    /// キーボードを閉じる
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct MeasuresMemoRow: View {
    let measuresMemo: MeasuresMemo

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(measuresMemo.detail)
                .font(.body)
                .lineLimit(nil)

            Text(formatDate(measuresMemo.date))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
