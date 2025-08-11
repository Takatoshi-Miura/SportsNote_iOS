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
    /// - Returns: 成功時は.success(())、失敗時は.failure(SportsNoteError)
    func fetchData() async -> Result<Void, SportsNoteError>



    /// データをリフレッシュする統一メソッド
    func refresh() async
}

/// BaseViewModelProtocolのデフォルト実装
extension BaseViewModelProtocol {


    /// エラーメッセージをクリアしてデータを再取得する
    func refresh() async {
        self.errorMessage = nil
        self.currentError = nil
        self.showingErrorAlert = false
        let result = await self.fetchData()
        if case .failure(let error) = result {
            // 再取得に失敗した場合はエラー状態を再設定
            self.currentError = error
            self.showingErrorAlert = true
        }
    }

    /// エラーをSportsNoteErrorに変換する共通処理
    /// - Parameters:
    ///   - error: 発生したエラー
    ///   - context: エラーが発生したコンテキスト（メソッド名など）
    /// - Returns: 変換されたSportsNoteError
    func convertToSportsNoteError(_ error: Error, context: String) -> SportsNoteError {
        if let existingSportsNoteError = error as? SportsNoteError {
            return existingSportsNoteError
        } else {
            return ErrorMapper.mapRealmError(error, context: context)
        }
    }
}
