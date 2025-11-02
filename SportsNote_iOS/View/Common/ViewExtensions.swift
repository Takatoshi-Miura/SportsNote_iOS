import SwiftUI

/// View拡張 - 共通の修飾子
extension View {
    /// タップ時にキーボードを非表示にする修飾子
    /// - Returns: キーボード非表示機能を持つView
    func dismissKeyboardOnTap() -> some View {
        self
            .contentShape(Rectangle())
            .onTapGesture {
                KeyboardUtil.hideKeyboard()
            }
    }
}
