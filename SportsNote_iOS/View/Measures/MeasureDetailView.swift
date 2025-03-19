import SwiftUI
import Foundation
import Combine
import RealmSwift

struct MeasureDetailView: View {
    let measure: Measures
    @State private var title: String
    @State private var memo: String = ""
    @ObservedObject private var viewModel: MeasureDetailViewModel
    
    init(measure: Measures) {
        self.measure = measure
        _title = State(initialValue: measure.title)
        self.viewModel = MeasureDetailViewModel(measure: measure)
    }
    
    var body: some View {
        VStack {
            List {
                Section(header: Text(LocalizedStrings.title)) {
                    TextField(LocalizedStrings.title, text: $title)
                        .onChange(of: title) { newValue in
                            viewModel.updateTitle(newValue)
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
        }
        .navigationTitle(LocalizedStrings.measuresDetail)
        .navigationBarTitleDisplayMode(.inline)
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

class MeasureDetailViewModel: ObservableObject {
    @Published var memos: [Memo] = []
    private let measure: Measures
    private var autoSaveTimer: Timer?
    
    init(measure: Measures) {
        self.measure = measure
        fetchMemosByMeasuresID()
    }
    
    func updateTitle(_ newTitle: String) {
        // Cancel previous timer if it exists
        autoSaveTimer?.invalidate()
        
        // Set new timer for auto-save with 0.5 second delay
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.saveTitle(newTitle)
        }
    }
    
    private func saveTitle(_ title: String) {
        do {
            let realm = try Realm()
            if let measures = realm.object(ofType: Measures.self, forPrimaryKey: measure.measuresID) {
                try realm.write {
                    measures.title = title
                    measures.updated_at = Date()
                }
            }
        } catch {
            print("Error updating title: \(error)")
        }
    }
    
    func fetchMemosByMeasuresID() {
        memos = RealmManager.shared.getMemosByMeasuresID(measuresID: measure.measuresID)
    }
    
    func addMemo(detail: String, noteID: String) {
        let memo = Memo(
            measuresID: measure.measuresID,
            noteID: noteID,
            detail: detail
        )
        
        RealmManager.shared.saveItem(memo)
        fetchMemosByMeasuresID()
    }
    
    func deleteMemo(id: String) {
        RealmManager.shared.logicalDelete(id: id, type: Memo.self)
        fetchMemosByMeasuresID()
    }
    
    deinit {
        autoSaveTimer?.invalidate()
    }
}
