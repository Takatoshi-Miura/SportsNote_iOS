import RealmSwift
import SwiftUI
import UIKit

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
            viewModel.saveGroup(
                groupID: group.groupID,
                title: title,
                color: selectedColor,
                order: group.order,
                created_at: group.created_at
            )
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle(String(format: LocalizedStrings.detailTitle, LocalizedStrings.group))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .alert(LocalizedStrings.delete, isPresented: $showingDeleteConfirmation) {
            Button(LocalizedStrings.cancel, role: .cancel) {}
            Button(LocalizedStrings.delete, role: .destructive) {
                viewModel.deleteGroup(id: group.groupID)
                dismiss()
            }
        } message: {
            Text(LocalizedStrings.deleteGroup)
        }
    }
}
