import SwiftUI

struct TabTopView<Content: View, Leading: View, Trailing: View>: View {
    @Binding var isMenuOpen: Bool
    let title: String
    let destination: Content
    let leadingItem: Leading
    let trailingItem: Trailing
    let content: () -> AnyView
    let actionItems: [(title: String, action: () -> Void)]
    
    @State private var showActionSheet = false
    
    init(
        isMenuOpen: Binding<Bool>,
        title: String,
        destination: Content,
        @ViewBuilder leadingItem: () -> Leading,
        @ViewBuilder trailingItem: () -> Trailing,
        @ViewBuilder content: @escaping () -> some View,
        actionItems: [(title: String, action: () -> Void)]
    ) {
        self._isMenuOpen = isMenuOpen
        self.title = title
        self.destination = destination
        self.leadingItem = leadingItem()
        self.trailingItem = trailingItem()
        self.content = { AnyView(content()) }
        self.actionItems = actionItems
    }
    
    var body: some View {
        ZStack {
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
            
            // ＋ボタン
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showActionSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                            .shadow(radius: 10)
                    }
                    .padding()
                }
            }
        }
        .confirmationDialog("何を追加しますか？", isPresented: $showActionSheet, titleVisibility: .visible) {
            ForEach(actionItems.indices, id: \.self) { index in
                Button(actionItems[index].title) {
                    actionItems[index].action()
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
    }
}
