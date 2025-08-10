import Combine
import Foundation
import SwiftUI

/// すべてのViewModelが実装すべき基本プロトコル
protocol BaseViewModelProtocol: ObservableObject {
    /// ViewModelが扱うエンティティの型
    associatedtype EntityType

    /// ローディング状態を示すプロパティ
    var isLoading: Bool { get set }

    /// エラーメッセージを保持するプロパティ（既存の互換性のため保持）
    var errorMessage: String? { get set }

    /// 現在発生しているSportsNoteError
    var currentError: SportsNoteError? { get set }

    /// エラーダイアログの表示状態
    var showingErrorAlert: Bool { get set }

    /// データを取得する基本メソッド（非同期処理に対応）
    func fetchData() async

    /// エラーハンドリングの統一メソッド（従来版）
    /// - Parameter error: 発生したエラー
    func handleError(_ error: Error)

    /// SportsNoteError専用のエラーハンドリング
    /// - Parameter error: 発生したSportsNoteError
    func handleSportsNoteError(_ error: SportsNoteError)

    /// データをリフレッシュする統一メソッド
    func refresh() async
}

/// BaseViewModelProtocolのデフォルト実装
extension BaseViewModelProtocol {
    /// エラーメッセージを設定し、必要に応じてログ出力やクラッシュ解析への送信を行う
    func handleError(_ error: Error) {
        self.errorMessage = error.localizedDescription

        // ログ出力
        print("ViewModel Error: \(error.localizedDescription)")

        // 将来的にはクラッシュ解析サービス（Crashlytics等）への送信も追加可能
        // CrashlyticsManager.shared.recordError(error)
    }

    /// SportsNoteError専用のエラーハンドリング（重要度に応じた処理分岐）
    func handleSportsNoteError(_ error: SportsNoteError) {
        // エラー情報を設定
        self.currentError = error
        self.errorMessage = error.errorDescription

        // エラーの重要度に応じた処理
        switch error {
        // 重大なエラー - 即座にアラート表示
        case .criticalError(_, _):
            self.showingErrorAlert = true
            print("🚨 Critical Error: \(error.errorDescription ?? "Unknown critical error")")

        // システムエラー - アラート表示
        case .systemError(_):
            self.showingErrorAlert = true
            print("⚠️ System Error: \(error.errorDescription ?? "Unknown system error")")

        // 初期化失敗 - アラート表示
        case .realmInitializationFailed, .realmMigrationFailed:
            self.showingErrorAlert = true
            print("⚠️ Database Error: \(error.errorDescription ?? "Database error")")

        // Firebase認証・権限エラー - アラート表示
        case .firebaseAuthenticationFailed, .firebasePermissionDenied:
            self.showingErrorAlert = true
            print("🔐 Auth Error: \(error.errorDescription ?? "Authentication error")")

        // ネットワーク・接続エラー - ログのみ（ユーザーが頻繁に経験する可能性）
        case .networkUnavailable, .networkTimeout, .firebaseNetworkError, .firebaseNotConnected:
            self.showingErrorAlert = false
            print("🌐 Network Error: \(error.errorDescription ?? "Network error")")

        // 一般的な操作エラー - ログのみ
        case .realmWriteFailed(_), .realmReadFailed(_), .realmDeleteFailed(_),
            .firebaseDocumentNotFound, .firebaseQuotaExceeded, .firebaseServerError:
            self.showingErrorAlert = false
            print("⚠️ Operation Error: \(error.errorDescription ?? "Operation error")")

        // 予期しないエラー - アラート表示
        case .unexpectedError(_), .unknownError(_):
            self.showingErrorAlert = true
            print("❓ Unexpected Error: \(error.errorDescription ?? "Unexpected error")")
        }

        // 将来的にはクラッシュ解析サービスへの送信も追加可能
        // CrashlyticsManager.shared.recordSportsNoteError(error)
    }

    /// エラーメッセージをクリアしてデータを再取得する
    func refresh() async {
        self.errorMessage = nil
        self.currentError = nil
        self.showingErrorAlert = false
        await self.fetchData()
    }
}
