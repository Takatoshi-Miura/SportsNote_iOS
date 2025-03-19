import SwiftUI

struct MeasureDetailView: View {
    let measure: Measures
    @State private var memo: String = ""
    @StateObject private var viewModel = MeasureViewModel()
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Details")) {
                    Text(measure.title)
                        .font(.headline)
                        .padding(.vertical, 4)
                }
                
                Section(header: Text("Memos")) {
                    if viewModel.memos.isEmpty {
                        Text("No memos yet")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(viewModel.memos, id: \.memoID) { memo in
                            MemoRow(memo: memo)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.deleteMemo(id: memo.memoID)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            
            // Add memo input
            VStack {
                TextField("Add a memo", text: $memo)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                Button(action: {
                    addMemo()
                }) {
                    Text("Add Memo")
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.bottom)
                .disabled(memo.isEmpty)
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Measure Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchMemosByMeasuresID(measuresID: measure.measuresID)
        }
    }
    
    private func addMemo() {
        guard !memo.isEmpty else { return }
        
        viewModel.addMemo(
            detail: memo,
            measuresID: measure.measuresID,
            noteID: ""
        )
        
        memo = ""
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

class MeasureViewModel: ObservableObject {
    @Published var memos: [Memo] = []
    
    func fetchMemosByMeasuresID(measuresID: String) {
        memos = RealmManager.shared.getMemosByMeasuresID(measuresID: measuresID)
    }
    
    func addMemo(detail: String, measuresID: String, noteID: String) {
        let memo = Memo(
            measuresID: measuresID,
            noteID: noteID,
            detail: detail
        )
        
        RealmManager.shared.saveItem(memo)
        fetchMemosByMeasuresID(measuresID: measuresID)
    }
    
    func deleteMemo(id: String) {
        if let memo = memos.first(where: { $0.memoID == id }) {
            let measuresID = memo.measuresID
            RealmManager.shared.logicalDelete(id: id, type: Memo.self)
            fetchMemosByMeasuresID(measuresID: measuresID)
        }
    }
}
