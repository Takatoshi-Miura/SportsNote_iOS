import SwiftUI

struct SectionData: Identifiable {
    let id = UUID()
    let title: String
    let items: [ItemData]
}

struct ItemData: Identifiable {
    let id = UUID()
    let title: String
    let subTitle: String
    let iconRes: String
    let isEnabled: Bool
    let onClick: () -> Void

    init(title: String, subTitle: String, iconRes: String, isEnabled: Bool = true, onClick: @escaping () -> Void) {
        self.title = title
        self.subTitle = subTitle
        self.iconRes = iconRes
        self.isEnabled = isEnabled
        self.onClick = onClick
    }
}
