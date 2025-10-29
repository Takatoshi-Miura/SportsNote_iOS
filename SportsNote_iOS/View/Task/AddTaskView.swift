import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskViewModel
    @ObservedObject var groupViewModel: GroupViewModel
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
                            viewModel: groupViewModel
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
                KeyboardUtil.hideKeyboard()
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
                        Task {
                            let result = await viewModel.saveNewTaskWithMeasures(
                                title: taskTitle,
                                cause: cause,
                                groupID: groups[selectedGroupIndex].groupID,
                                measuresTitle: measuresTitle.isEmpty ? nil : measuresTitle
                            )

                            switch result {
                            case .success:
                                dismiss()
                            case .failure(let error):
                                viewModel.showErrorAlert(error)
                            }
                        }
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
}
