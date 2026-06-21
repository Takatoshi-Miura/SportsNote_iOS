import SwiftUI

struct MenuButton: View {
    @Binding var isMenuOpen: Bool

    var body: some View {
        Button(action: {
            withAnimation {
                isMenuOpen.toggle()
            }
        }) {
            Image(systemName: "line.horizontal.3")
                .imageScale(.large)
        }
    }
}
