import SwiftUI

struct AutoResizingTextEditor: View {
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 50
    @State private var textHeight: CGFloat
    @State private var textEditorWidth: CGFloat = 0
    
    init(text: Binding<String>, placeholder: String = "", minHeight: CGFloat = 50) {
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
        self._textHeight = State(initialValue: minHeight)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // プレースホルダー表示
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color.gray.opacity(0.6))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            }
            
            // TextEditor
            TextEditor(text: $text)
                .frame(height: max(minHeight, textHeight))
                .cornerRadius(8)
                .onChange(of: text) { _ in
                    calculateTextHeight()
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear.onAppear {
                            textEditorWidth = geometry.size.width
                            calculateTextHeight()
                        }
                        .onChange(of: geometry.size.width) { newWidth in
                            textEditorWidth = newWidth
                            calculateTextHeight()
                        }
                    }
                )
        }
    }
    
    // TextEditorの高さを計算する
    private func calculateTextHeight() {
        guard !text.isEmpty else {
            textHeight = minHeight // 空の場合はデフォルト高さ
            return
        }
        
        // 1文字あたりの平均幅（ポイント単位）
        let averageCharWidth: CGFloat = 8.0
        
        // 1行あたりの高さ（ポイント単位）
        let lineHeight: CGFloat = 25.0
        
        // TextEditorの内部パディング
        let padding: CGFloat = 16.0
        
        // 利用可能な幅（TextEditor内でテキストが表示される実際の幅）
        let availableWidth = max(textEditorWidth - 10, 1) // 0除算を避けるため最小値を1とする
        
        var totalLines = 0
        
        // 各段落（改行で区切られたテキスト）を処理
        let paragraphs = text.components(separatedBy: "\n")
        for paragraph in paragraphs {
            if paragraph.isEmpty {
                // 空の段落は1行としてカウント
                totalLines += 1
            } else {
                // 段落内の文字数から推定される行数を計算
                let charactersPerLine = availableWidth / averageCharWidth
                let estimatedLines = max(1, ceil(CGFloat(paragraph.count) / charactersPerLine))
                totalLines += Int(estimatedLines)
            }
        }
        
        // 最終的な高さを計算（最低1行分を確保）
        textHeight = CGFloat(max(1, totalLines)) * lineHeight + padding
    }
}