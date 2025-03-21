import UIKit
import SwiftUI
import RealmSwift

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
                    .onChange(of: title) { _ in
                        updateGroup()
                    }
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
                                updateGroup()
                            }
                    }
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle(String(format: LocalizedStrings.detailTitle, LocalizedStrings.group))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func updateGroup() {
        viewModel.updateExistingGroup(
            id: group.groupID,
            title: title,
            color: selectedColor.rawValue
        )
    }
}
