import SwiftUI
import UIKit

/// グループ追加画面
struct AddGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GroupViewModel
    @State private var title: String
    @State private var selectedColor: GroupColor

    init(
        title: String = "",
        selectedColor: GroupColor = .red,
        viewModel: GroupViewModel
    ) {
        self.viewModel = viewModel
        _title = State(initialValue: title)
        _selectedColor = State(initialValue: selectedColor)
    }

    var body: some View {
        NavigationView {
            GroupForm(title: $title, selectedColor: $selectedColor)
                .background(Color(UIColor.systemBackground))
                .navigationTitle(String(format: LocalizedStrings.addTitle, LocalizedStrings.group))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // キャンセル
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(LocalizedStrings.cancel) { dismiss() }
                    }
                    // 保存
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(LocalizedStrings.save) {
                            viewModel.saveGroup(title: title, color: selectedColor)
                            dismiss()
                        }
                        .disabled(title.isEmpty)
                    }
                }
        }
    }
}
