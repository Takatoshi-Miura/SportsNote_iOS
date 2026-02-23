import SwiftUI

/// グループの共通フォーム
struct GroupForm: View {
    @Binding var title: String
    @Binding var selectedColor: GroupColor
    var onChange: (() -> Void)? = nil

    // 並び替えセクション用（nilの場合はセクションを非表示）
    var groups: [Group]? = nil
    var selectedGroupID: String? = nil
    var onSelectGroup: ((Group) -> Void)? = nil
    var onMoveGroup: ((IndexSet, Int) -> Void)? = nil

    var body: some View {
        Form {
            // タイトル
            Section(header: Text(LocalizedStrings.title)) {
                TextField(LocalizedStrings.title, text: $title)
                    .onChange(of: title) { _ in
                        onChange?()
                    }
            }
            // カラー
            Section(header: Text(LocalizedStrings.color)) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 10) {
                    ForEach(GroupColor.allCases, id: \.self) { color in
                        ZStack {
                            GroupColorCircle(color: Color(color.color), size: 30)
                            if selectedColor == color {
                                Circle()
                                    .stroke(Color.primary, lineWidth: 3)
                                    .frame(width: 32, height: 32)
                            }
                        }
                        .onTapGesture {
                            selectedColor = color
                            onChange?()
                        }
                    }
                }
            }
            // 並び替えセクション（groupsが渡された場合のみ表示）
            if let groups = groups {
                Section(header: Text(LocalizedStrings.sort)) {
                    ForEach(groups, id: \.groupID) { group in
                        HStack(spacing: 12) {
                            GroupColorCircle(
                                color: Color(GroupColor.allCases[Int(group.color)].color),
                                size: 16
                            )
                            Text(group.title)
                                .font(.body)
                            Spacer()
                            if selectedGroupID == group.groupID {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectGroup?(group)
                        }
                        .listRowBackground(
                            selectedGroupID == group.groupID
                                ? Color(.systemGray5) : Color(.systemBackground)
                        )
                    }
                    .onMove { source, destination in
                        onMoveGroup?(source, destination)
                    }
                }
            }
        }
        .dismissKeyboardOnTap()
    }
}
