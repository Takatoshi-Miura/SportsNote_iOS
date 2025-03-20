import UIKit
import SwiftUI

struct GroupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String
    @State private var selectedColor: GroupColor
    @ObservedObject var viewModel: GroupViewModel
    let group: Group
    
    init(group: Group, viewModel: GroupViewModel) {
        self.group = group
        self.viewModel = viewModel
        // 初期値を設定
        _title = State(initialValue: group.title)
        _selectedColor = State(initialValue: GroupColor.allCases[Int(group.color)])
    }
    
    var body: some View {
        Form {
            Section(header: Text(LocalizedStrings.title)) {
                TextField(LocalizedStrings.title, text: $title)
            }
            Section(header: Text(LocalizedStrings.color)) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 10) {
                    ForEach(GroupColor.allCases, id: \.self) { color in
                        Circle()
                            .fill(Color(color.color))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                    .padding(1)
                            )
                            .onTapGesture {
                                selectedColor = color
                            }
                    }
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle(String(format: LocalizedStrings.addTitle, LocalizedStrings.group))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(LocalizedStrings.save) {
                    // グループオブジェクトを更新
                    let updatedGroup = group
                    updatedGroup.title = title
                    updatedGroup.color = selectedColor.rawValue
                    updatedGroup.updated_at = Date()
                    
                    viewModel.updateGroup(group: updatedGroup)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty)
            }
        }
    }
}
