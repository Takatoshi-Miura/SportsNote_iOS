import Combine
import Foundation
import SwiftUI

/// すべてのViewModelが実装すべき基本プロトコル
protocol BaseViewModelProtocol: ObservableObject {
    /// ViewModelが扱うエンティティの型
    associatedtype EntityType

    /// ローディング状態を示すプロパティ
    var isLoading: Bool { get set }

    /// エラーメッセージを保持するプロパティ
    var errorMessage: String? { get set }

    /// データを取得する基本メソッド（非同期処理に対応）
    func fetchData() async

    /// エラーハンドリングの統一メソッド
    /// - Parameter error: 発生したエラー
    func handleError(_ error: Error)

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

    /// エラーメッセージをクリアしてデータを再取得する
    func refresh() async {
        self.errorMessage = nil
        await self.fetchData()
    }
}
