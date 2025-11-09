import UIKit

/// キーボード制御のためのユーティリティクラス
struct KeyboardUtil {
    /// キーボードを閉じる
    @MainActor
    static func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
