import SwiftUI
import RealmSwift

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TaskViewModel()
    @State private var isEditingTask = false
    @State private var isAddingMeasure = false
    @State private var newMeasureTitle = ""
    
    let taskData: TaskData
    
    var body: some View {
        List {
            Section(header: Text("Task Info")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(taskData.title)
                        .font(.headline)
                    
                    if !taskData.cause.isEmpty {
                        Text("Cause: \(taskData.cause)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Status:")
                            .font(.subheadline)
                        
                        Text(taskData.isComplete ? "Completed" : "In Progress")
                            .font(.subheadline)
                            .foregroundColor(taskData.isComplete ? .green : .blue)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Measures")) {
                if let detail = viewModel.taskDetail {
                    if detail.measuresList.isEmpty {
                        Text("No measures yet")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(detail.measuresList, id: \.measuresID) { measure in
                            NavigationLink(destination: MeasureDetailView(measure: measure)) {
                                MeasureRow(measure: measure)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteMeasure(measuresID: measure.measuresID)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    
                    // Add measure field
                    HStack {
                        TextField("New measure", text: $newMeasureTitle)
                        
                        Button(action: {
                            addMeasure()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newMeasureTitle.isEmpty)
                    }
                }
            }
        }
        .navigationTitle("Task Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isEditingTask = true
                }) {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $isEditingTask) {
            EditTaskView(task: taskData, onSave: { updatedTask in
                // Refresh data after task update
                viewModel.fetchTaskDetail(taskID: taskData.taskID)
            })
        }
        .onAppear {
            viewModel.fetchTaskDetail(taskID: taskData.taskID)
        }
    }
    
    private func addMeasure() {
        guard !newMeasureTitle.isEmpty else { return }
        
        viewModel.addMeasure(
            title: newMeasureTitle,
            taskID: taskData.taskID
        )
        
        // Clear input field
        newMeasureTitle = ""
    }
}

struct MeasureRow: View {
    let measure: Measures
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(measure.title)
                .font(.body)
                .lineLimit(2)
                .padding(.vertical, 4)
        }
    }
}

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

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    let task: TaskData
    let onSave: (TaskData) -> Void
    
    @State private var title: String
    @State private var cause: String
    @State private var isComplete: Bool
    
    init(task: TaskData, onSave: @escaping (TaskData) -> Void) {
        self.task = task
        self.onSave = onSave
        _title = State(initialValue: task.title)
        _cause = State(initialValue: task.cause)
        _isComplete = State(initialValue: task.isComplete)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Information")) {
                    TextField("Title", text: $title)
                    TextField("Cause", text: $cause)
                    
                    Toggle("Completed", isOn: $isComplete)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateTask()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func updateTask() {
        do {
            let realm = try Realm()
            if let taskToUpdate = realm.object(ofType: TaskData.self, forPrimaryKey: task.taskID) {
                try realm.write {
                    taskToUpdate.title = title
                    taskToUpdate.cause = cause
                    taskToUpdate.isComplete = isComplete
                    taskToUpdate.updated_at = Date()
                }
                onSave(taskToUpdate)
            }
        } catch {
            print("Error updating task: \(error)")
        }
    }
}
