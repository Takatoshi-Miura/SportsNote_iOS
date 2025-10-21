import SwiftUI

/// グループセクション
struct GroupListSection: View {
    let groups: [Group]
    let selectedGroupID: String?
    let onGroupSelected: (String?) -> Void
    let onGroupEdit: (Group) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(groups, id: \.groupID) { group in
                    GroupChip(
                        group: group,
                        isSelected: selectedGroupID == group.groupID,
                        onTap: {
                            if selectedGroupID == group.groupID {
                                onGroupSelected(nil)
                            } else {
                                onGroupSelected(group.groupID)
                            }
                        },
                        onEditTap: { onGroupEdit(group) }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
    }
}

/// グループチップコンポーネント
private struct GroupChip: View {
    let group: Group
    let isSelected: Bool
    let onTap: () -> Void
    let onEditTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                GroupColorCircle(color: Color(GroupColor.allCases[Int(group.color)].color))

                Text(group.title)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(chipBackgroundColor())
            )
            .overlay(
                Capsule()
                    .stroke(chipStrokeColor(), lineWidth: 1)
            )
        }
        .contextMenu {
            Button(action: onEditTap) {
                Label(LocalizedStrings.edit, systemImage: "pencil")
            }
        }
    }

    private func chipBackgroundColor() -> Color {
        if isSelected {
            return Color(GroupColor.allCases[Int(group.color)].color).opacity(0.2)
        } else {
            return Color(.tertiarySystemBackground)
        }
    }

    private func chipStrokeColor() -> Color {
        if isSelected {
            return Color(GroupColor.allCases[Int(group.color)].color)
        } else {
            return Color(.systemGray4)
        }
    }
}
