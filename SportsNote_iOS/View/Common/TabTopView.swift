import SwiftUI

struct TabTopView<Trailing: View, Content: View>: View {
    @State private var isMenuOpen: Bool = false
    @State private var showActionSheet = false
    
    let title: String
    let trailingItem: Trailing
    let content: () -> Content
    let actionItems: [(title: String, action: () -> Void)]
    
    init(
        title: String,
        @ViewBuilder trailingItem: () -> Trailing,
        @ViewBuilder content: @escaping () -> Content,
        actionItems: [(title: String, action: () -> Void)]
    ) {
        self.title = title
        self.trailingItem = trailingItem()
        self.content = content
        self.actionItems = actionItems
    }
    
    var body: some View {
        ZStack {
            VStack {
                content()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    MenuButton(isMenuOpen: $isMenuOpen)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    trailingItem
                }
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
                    }
                    .padding()
                }
            }
        }
        .confirmationDialog(LocalizedStrings.addPrompt, isPresented: $showActionSheet, titleVisibility: .visible) {
            ForEach(actionItems.indices, id: \.self) { index in
                Button(actionItems[index].title) {
                    actionItems[index].action()
                }
            }
            Button(LocalizedStrings.cancel, role: .cancel) {}
        }
    }
}
