import UIKit

/// キーボード制御のためのユーティリティクラス
struct KeyboardUtil {
    /// キーボードを閉じる
    static func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
