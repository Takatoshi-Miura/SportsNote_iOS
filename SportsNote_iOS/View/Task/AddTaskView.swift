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
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
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
        .errorAlert(
            currentError: $viewModel.currentError,
            showingAlert: $viewModel.showingErrorAlert
        )
    }

    /// 保存処理（新Resultパターン対応）
    private func saveTask() {
        guard !groups.isEmpty, !taskTitle.isEmpty else { return }

        let groupID = groups[selectedGroupIndex].groupID

        Task {
            // 課題を保存
            let result = await viewModel.saveNewTask(
                title: taskTitle,
                cause: cause,
                groupID: groupID
            )
            
            switch result {
            case .success(let newTask):
                // 対策を保存
                if !measuresTitle.isEmpty {
                    let measuresViewModel = MeasuresViewModel()
                    measuresViewModel.saveMeasures(
                        taskID: newTask.taskID,
                        title: measuresTitle
                    )
                }
                
                await MainActor.run {
                    dismiss()
                }
            case .failure(let error):
                // エラーをViewModelに設定（ViewModelがUIでエラー表示）
                await MainActor.run {
                    viewModel.showErrorAlert(error)
                }
            }
        }
    }

    /// キーボードを閉じる
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
