import Foundation

/// アプリケーション内で使用する通知名の定義
extension Notification.Name {
    /// ログアウト時にViewModelをクリーンアップするための通知
    static let didLogout = Notification.Name("didLogout")

    /// データがクリアされた際の通知
    static let didClearAllData = Notification.Name("didClearAllData")

    /// アプリを再初期化する必要がある際の通知
    static let shouldReinitializeApp = Notification.Name("shouldReinitializeApp")
}
