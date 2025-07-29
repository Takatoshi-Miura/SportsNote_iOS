import SwiftUI

struct GroupSelectorView: View {
    @Binding var selectedGroupIndex: Int
    let groups: [Group]
    let onSelectionChanged: (() -> Void)?

    init(selectedGroupIndex: Binding<Int>, groups: [Group], onSelectionChanged: (() -> Void)? = nil) {
        self._selectedGroupIndex = selectedGroupIndex
        self.groups = groups
        self.onSelectionChanged = onSelectionChanged
    }

    var body: some View {
        HStack {
            GroupColorCircle(color: getGroupColor(for: selectedGroupIndex))
            Text(groups.indices.contains(selectedGroupIndex) ? groups[selectedGroupIndex].title : "")
            Spacer()
            Menu {
                ForEach(0..<groups.count, id: \.self) { index in
                    Button(action: {
                        selectedGroupIndex = index
                        if let onSelectionChanged = onSelectionChanged {
                            onSelectionChanged()
                        }
                    }) {
                        HStack {
                            GroupColorCircle(color: getGroupColor(for: index))
                            Text(groups[index].title)
                            if selectedGroupIndex == index {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Text(LocalizedStrings.select)
                    .foregroundColor(.blue)
            }
        }
    }

    /// グループの色を取得
    /// - Parameter index: Index
    /// - Returns: グループの色
    private func getGroupColor(for index: Int) -> Color {
        guard groups.indices.contains(index) else { return Color.gray }
        let colorIndex = Int(groups[index].color)

        if GroupColor.allCases.indices.contains(colorIndex) {
            return Color(GroupColor.allCases[colorIndex].color)
        } else {
            return Color.gray
        }
    }
}
