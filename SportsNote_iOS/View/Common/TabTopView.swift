import SwiftUI

struct TabTopView<Content: View, Leading: View, Trailing: View>: View {
    @Binding var isMenuOpen: Bool
    let title: String
    let destination: Content
    let leadingItem: Leading
    let trailingItem: Trailing
    let content: () -> AnyView
    
    init(
        isMenuOpen: Binding<Bool>,
        title: String,
        destination: Content,
        @ViewBuilder leadingItem: () -> Leading,
        @ViewBuilder trailingItem: () -> Trailing,
        @ViewBuilder content: @escaping () -> some View
    ) {
        self._isMenuOpen = isMenuOpen
        self.title = title
        self.destination = destination
        self.leadingItem = leadingItem()
        self.trailingItem = trailingItem()
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        VStack {
            content()
            NavigationLink(destination: destination) {
                Text("Go to \(title) Detail")
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { leadingItem }
            ToolbarItem(placement: .navigationBarTrailing) { trailingItem }
        }
        .overlay(
            MenuView(isMenuOpen: $isMenuOpen)
                .offset(x: isMenuOpen ? 0 : -UIScreen.main.bounds.width)
                .animation(.easeInOut(duration: 0.3), value: isMenuOpen)
        )
    }
}
