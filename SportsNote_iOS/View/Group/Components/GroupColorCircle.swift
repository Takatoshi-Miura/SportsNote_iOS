import SwiftUI

/// グループカラーサークルコンポーネント
struct GroupColorCircle: View {
    let color: Color
    let size: CGFloat

    init(color: Color, size: CGFloat = 16) {
        self.color = color
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }
}
