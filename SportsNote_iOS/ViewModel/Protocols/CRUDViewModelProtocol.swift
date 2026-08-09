import Foundation
import RealmSwift

/// CRUD操作を行うViewModelのプロトコル
@MainActor
protocol CRUDViewModelProtocol: BaseViewModelProtocol where EntityType: Object {
    /// エンティティを保存（新規作成・更新）する
    /// - Parameter entity: 保存するエンティティ
    /// - Parameter isUpdate: 更新かどうか（デフォルトはfalse）
    /// - Returns: 成功時は.success(())、失敗時は.failure(SportsNoteError)
    func save(_ entity: EntityType, isUpdate: Bool) async -> Result<Void, SportsNoteError>

    /// 指定されたIDのエンティティを削除する
    /// - Parameter id: 削除するエンティティのID
    /// - Returns: 成功時は.success(())、失敗時は.failure(SportsNoteError)
    func delete(id: String) async -> Result<Void, SportsNoteError>

    /// 指定されたIDのエンティティを取得する
    /// - Parameter id: 取得するエンティティのID
    /// - Returns: 成功時は.success(entity)、失敗時は.failure(SportsNoteError)
    func fetchById(id: String) async -> Result<EntityType?, SportsNoteError>
}

extension CRUDViewModelProtocol {
    /// 指定されたIDのエンティティを取得する共通実装
    /// - Parameters:
    ///   - id: 取得するエンティティのID
    ///   - context: エラー変換時のコンテキスト（メソッド名など）
    ///   - onSuccess: 取得成功時に追加で実行する処理（例: hideErrorAlert）
    /// - Returns: 成功時は.success(entity)、失敗時は.failure(SportsNoteError)
    func fetchByIdDefault(
        id: String,
        context: String,
        onSuccess: (() -> Void)? = nil
    ) async -> Result<EntityType?, SportsNoteError> {
        do {
            let entity = try RealmManager.shared.getObjectById(id: id, type: EntityType.self)
            onSuccess?()
            return .success(entity)
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: context)
            return .failure(sportsNoteError)
        }
    }
}
