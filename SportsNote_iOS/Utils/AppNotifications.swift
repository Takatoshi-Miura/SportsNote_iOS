import Foundation

/// アプリケーション内で使用する通知名の定義
extension Notification.Name {
    /// データがクリアされた際の通知
    static let didClearAllData = Notification.Name("didClearAllData")

    /// アプリを再初期化する必要がある際の通知
    static let shouldReinitializeApp = Notification.Name("shouldReinitializeApp")

    /// 「今日」ボタンタップ時にカレンダーを今日の月へ移動させるための通知
    static let moveToToday = Notification.Name("MoveToToday")
}
