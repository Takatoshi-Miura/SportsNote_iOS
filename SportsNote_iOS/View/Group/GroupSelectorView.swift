import SwiftUI

struct GroupSelectorView: View {
    @Binding var selectedGroupIndex: Int
    @ObservedObject var viewModel: GroupViewModel
    let onSelectionChanged: (() -> Void)?

    init(selectedGroupIndex: Binding<Int>, viewModel: GroupViewModel, onSelectionChanged: (() -> Void)? = nil) {
        self._selectedGroupIndex = selectedGroupIndex
        self.viewModel = viewModel
        self.onSelectionChanged = onSelectionChanged
    }

    var body: some View {
        HStack {
            GroupColorCircle(color: getGroupColor(for: selectedGroupIndex))
            Text(viewModel.getTitleForGroupAtIndex(selectedGroupIndex))
            Spacer()
            Menu {
                ForEach(0..<viewModel.groups.count, id: \.self) { index in
                    Button(action: {
                        selectedGroupIndex = index
                        if let onSelectionChanged = onSelectionChanged {
                            onSelectionChanged()
                        }
                    }) {
                        HStack {
                            GroupColorCircle(color: getGroupColor(for: index))
                            Text(viewModel.getTitleForGroupAtIndex(index))
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

    /// グループの色を取得（ViewModelを使用）
    /// - Parameter index: Index
    /// - Returns: グループの色
    private func getGroupColor(for index: Int) -> Color {
        let groupColor = viewModel.getColorForGroupAtIndex(index)
        return Color(groupColor.color)
    }
}
