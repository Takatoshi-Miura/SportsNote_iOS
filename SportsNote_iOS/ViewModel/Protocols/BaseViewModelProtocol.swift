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
    
    /// データを取得する基本メソッド
    func fetchData()
    
    /// エラーハンドリングの統一メソッド
    /// - Parameter error: 発生したエラー
    func handleError(_ error: Error)
    
    /// データをリフレッシュする統一メソッド
    func refresh()
}

/// BaseViewModelProtocolのデフォルト実装
extension BaseViewModelProtocol {
    /// エラーメッセージを設定し、必要に応じてログ出力やクラッシュ解析への送信を行う
    @MainActor
    func handleError(_ error: Error) {
        self.errorMessage = error.localizedDescription
        
        // ログ出力
        print("ViewModel Error: \(error.localizedDescription)")
        
        // 将来的にはクラッシュ解析サービス（Crashlytics等）への送信も追加可能
        // CrashlyticsManager.shared.recordError(error)
    }
    
    /// エラーメッセージをクリアしてデータを再取得する
    @MainActor
    func refresh() {
        self.errorMessage = nil
        self.fetchData()
    }
}
