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
                // タイトル
                Section(header: Text(LocalizedStrings.title)) {
                    TextField(LocalizedStrings.title, text: $taskTitle)
                }
                // 原因
                Section(header: Text(LocalizedStrings.cause)) {
                    AutoResizingTextEditor(
                        text: $cause, 
                        placeholder: LocalizedStrings.cause,
                        minHeight: 50
                    )
                }
                // グループ
                Section(header: Text(LocalizedStrings.group)) {
                    if !groups.isEmpty {
                        GroupSelectorView(
                            selectedGroupIndex: $selectedGroupIndex,
                            groups: groups
                        )
                    }
                }
                // 対策
                Section(header: Text(LocalizedStrings.measures)) {
                    TextField(LocalizedStrings.measures, text: $measuresTitle)
                }
            }
            .navigationTitle(String(format: LocalizedStrings.addTitle, LocalizedStrings.task))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // キャンセル
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStrings.cancel) { dismiss() }
                }
                // 保存
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.save) {
                        saveTask()
                    }
                    .disabled(taskTitle.isEmpty || groups.isEmpty)
                }
            }
        }
    }
    
    /// 保存処理
    private func saveTask() {
        guard !groups.isEmpty, !taskTitle.isEmpty else { return }
        
        let groupID = groups[selectedGroupIndex].groupID
        
        viewModel.saveTask(
            title: taskTitle,
            cause: cause,
            groupID: groupID
        )
        
        if !measuresTitle.isEmpty {
            let tasks = RealmManager.shared.getDataList(clazz: TaskData.self)
            if let latestTask = tasks.last {
                viewModel.addMeasure(title: measuresTitle, taskID: latestTask.taskID)
            }
        }
        
        dismiss()
    }
}
