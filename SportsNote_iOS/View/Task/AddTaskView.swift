import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskViewModel
    @State private var taskTitle: String = ""
    @State private var cause: String = ""
    @State private var selectedGroupIndex: Int = 0
    @State private var measuresTitle: String = ""
    let groups: [Group]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizedStrings.title)) {
                    TextField(LocalizedStrings.title, text: $taskTitle)
                }
                Section(header: Text(LocalizedStrings.cause)) {
                    TextEditor(text: $cause)
                        .frame(height: 80)
                        .cornerRadius(8)
                }
                Section(header: Text(LocalizedStrings.group)) {
                    Picker(LocalizedStrings.group, selection: $selectedGroupIndex) {
                        ForEach(0..<groups.count, id: \.self) { index in
                            HStack {
                                Circle()
                                    .fill(Color(GroupColor.allCases[Int(groups[index].color)].color))
                                    .frame(width: 12, height: 12)
                                Text(groups[index].title)
                            }
                        }
                    }
                }
                Section(header: Text(LocalizedStrings.measuresPriority)) {
                    TextField(LocalizedStrings.measures, text: $measuresTitle)
                }
            }
            .navigationTitle(String(format: LocalizedStrings.addTitle, LocalizedStrings.task))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStrings.cancel) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.save) {
                        saveTask()
                    }
                    .disabled(taskTitle.isEmpty || groups.isEmpty)
                }
            }
        }
    }
    
    private func saveTask() {
        guard !groups.isEmpty, !taskTitle.isEmpty else { return }
        
        let groupID = groups[selectedGroupIndex].groupID
        
        // Save Task
        viewModel.saveTask(
            title: taskTitle,
            cause: cause,
            groupID: groupID
        )
        
        // If measures title provided, add a measure
        if !measuresTitle.isEmpty {
            // Find the latest task (the one we just created)
            let tasks = RealmManager.shared.getDataList(clazz: TaskData.self)
            if let latestTask = tasks.last {
                viewModel.addMeasure(title: measuresTitle, taskID: latestTask.taskID)
            }
        }
        
        dismiss()
    }
}
