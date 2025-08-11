import Foundation

/// CRUD操作を行うViewModelのプロトコル
protocol CRUDViewModelProtocol: BaseViewModelProtocol {
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
