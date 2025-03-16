import SwiftUI

struct TabTopView<Trailing: View, Content: View>: View {
    @Binding var isMenuOpen: Bool
    @State private var showActionSheet = false
    
    let title: String
    let trailingItem: Trailing
    let content: () -> Content
    let actionItems: [(title: String, action: () -> Void)]
    
    init(
        title: String,
        isMenuOpen: Binding<Bool>,
        @ViewBuilder trailingItem: () -> Trailing,
        @ViewBuilder content: @escaping () -> Content,
        actionItems: [(title: String, action: () -> Void)]
    ) {
        self.title = title
        self._isMenuOpen = isMenuOpen
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
                // 設定メニューをオーバーレイ
                EmptyView()
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
