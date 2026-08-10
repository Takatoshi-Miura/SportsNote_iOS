import SwiftUI

/// グループ詳細画面
struct GroupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: GroupViewModel
    @State private var selectedGroup: Group
    @State private var title: String
    @State private var selectedColor: GroupColor
    @State private var showingDeleteConfirmation = false

    init(group: Group, viewModel: GroupViewModel) {
        self.viewModel = viewModel
        _selectedGroup = State(initialValue: group)
        _title = State(initialValue: group.title)
        _selectedColor = State(initialValue: group.groupColor)
    }

    var body: some View {
        GroupForm(
            title: $title,
            selectedColor: $selectedColor,
            onChange: { saveSelectedGroup() },
            groups: viewModel.groups,
            selectedGroupID: selectedGroup.groupID,
            onSelectGroup: { group in
                selectedGroup = group
                title = group.title
                selectedColor = group.groupColor
            },
            onMoveGroup: { source, destination in
                // 表示上の並び替えは同期的に即座に反映する（issue #169、issue #161と同パターン）。
                // Task{}でラップすると一瞬元の位置に戻る視覚的不整合が発生するため直接呼ぶ
                let reorderedGroups = viewModel.reorderGroups(from: source, to: destination)
                Task {
                    let result = await viewModel.persistGroupOrder(reorderedGroups)
                    if case .failure(let error) = result {
                        viewModel.showErrorAlert(error)
                    }
                }
            }
        )
        .environment(\.editMode, .constant(.active))
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
                    let result = await viewModel.delete(id: selectedGroup.groupID)
                    switch result {
                    case .success:
                        if let first = viewModel.groups.first {
                            selectedGroup = first
                            title = first.title
                            selectedColor = first.groupColor
                        } else {
                            dismiss()
                        }
                    case .failure(let error):
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
                Task {
                    await viewModel.refresh()
                }
            }
        )
    }

    private func saveSelectedGroup() {
        // 空白のみのタイトルで即時保存されるのを防ぐ（issue #133）
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        Task {
            let result = await viewModel.saveGroup(
                groupID: selectedGroup.groupID,
                title: title,
                color: selectedColor,
                order: selectedGroup.order,
                created_at: selectedGroup.created_at
            )
            if case .failure(let error) = result {
                viewModel.showErrorAlert(error)
            }
        }
    }
}
