import Foundation

/// アプリケーション内で使用する通知名の定義
extension Notification.Name {
    /// データがクリアされた際の通知
    static let didClearAllData = Notification.Name("didClearAllData")

    /// アプリを再初期化する必要がある際の通知
    static let shouldReinitializeApp = Notification.Name("shouldReinitializeApp")

    /// ノート編集画面から戻った際に選択中日付のノート一覧を再取得するための通知
    static let refreshSelectedDateNotes = Notification.Name("RefreshSelectedDateNotes")
}
