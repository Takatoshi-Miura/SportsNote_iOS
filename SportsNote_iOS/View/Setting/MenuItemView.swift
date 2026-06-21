import SwiftUI

/// メニュー項目のビュー
struct MenuItemView: View {
    let item: ItemData

    var body: some View {
        HStack {
            Image(systemName: item.iconRes)
            VStack(alignment: .leading) {
                Text(item.title)
            }
            Spacer()
            if !item.subTitle.isEmpty {
                Text(item.subTitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard item.isEnabled else { return }
            item.onClick()
        }
        .opacity(item.isEnabled ? 1.0 : 0.4)
    }
}
