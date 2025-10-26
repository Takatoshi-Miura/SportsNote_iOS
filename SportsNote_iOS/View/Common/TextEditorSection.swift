import SwiftUI

// テキストエディタセクション
struct TextEditorSection: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let onUpdate: () -> Void

    var body: some View {
        Section(header: Text(title)) {
            AutoResizingTextEditor(text: $text, placeholder: placeholder, minHeight: 50)
                .onChange(of: text) { _ in
                    onUpdate()
                }
        }
    }
}
