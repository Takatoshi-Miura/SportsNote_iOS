import SwiftUI

/// グループ詳細画面
struct GroupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: GroupViewModel
    @State private var title: String
    @State private var selectedColor: GroupColor
    @State private var showingDeleteConfirmation = false
    private let group: Group

    init(group: Group, viewModel: GroupViewModel) {
        self.group = group
        self.viewModel = viewModel
        _title = State(initialValue: group.title)
        _selectedColor = State(initialValue: GroupColor.allCases[Int(group.color)])
    }

    var body: some View {
        GroupForm(title: $title, selectedColor: $selectedColor) {
            // グループ情報更新
            Task {
                let result = await viewModel.saveGroup(
                    groupID: group.groupID,
                    title: title,
                    color: selectedColor,
                    order: group.order,
                    created_at: group.created_at
                )
                if case .failure(let error) = result {
                    viewModel.showErrorAlert(error)
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(String(format: LocalizedStrings.detailTitle, LocalizedStrings.group))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(viewModel.canDelete ? .red : .gray)
                }
                .disabled(!viewModel.canDelete)
            }
        }
        .alert(LocalizedStrings.delete, isPresented: $showingDeleteConfirmation) {
            Button(LocalizedStrings.cancel, role: .cancel) {}
            Button(LocalizedStrings.delete, role: .destructive) {
                Task {
                    let result = await viewModel.delete(id: group.groupID)
                    switch result {
                    case .success:
                        dismiss()
                    case .failure(let error):
                        // エラーをView側で明示的に処理
                        viewModel.showErrorAlert(error)
                    }
                }
            }
        } message: {
            Text(LocalizedStrings.deleteGroup)
        }
        .errorAlert(
            currentError: $viewModel.currentError,
            showingAlert: $viewModel.showingErrorAlert,
            onRetry: {
                // データ再取得で回復を試行
                Task {
                    let result = await viewModel.fetchData()
                    if case .failure(let error) = result {
                        viewModel.showErrorAlert(error)
                    }
                }
            }
        )
    }
}
