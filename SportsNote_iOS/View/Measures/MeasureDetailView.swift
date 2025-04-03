import SwiftUI
import Foundation
import Combine
import RealmSwift

struct MeasureDetailView: View {
    let measure: Measures
    @State private var title: String
    @State private var memo: String = ""
    @StateObject private var viewModel: MeasuresViewModel
    
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
                
                Section(header: Text(LocalizedStrings.note)) {
                    if viewModel.memos.isEmpty {
                        Text("No notes yet")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(viewModel.memos, id: \.memoID) { memo in
                            MemoRow(memo: memo)
                        }
                    }
                }
            }
        }
        .navigationTitle(String(format: LocalizedStrings.detailTitle, LocalizedStrings.measures))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchMemosByMeasuresID(measuresID: measure.measuresID)
        }
    }
}

struct MemoRow: View {
    let memo: Memo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(memo.detail)
                .font(.body)
                .lineLimit(nil)
            
            Text(formatDate(memo.created_at))
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
