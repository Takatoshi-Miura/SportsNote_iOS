import Foundation


/// CRUD操作を行うViewModelのプロトコル
protocol CRUDViewModelProtocol: BaseViewModelProtocol {
    /// エンティティを保存（新規作成・更新）する
    /// - Parameter entity: 保存するエンティティ
    /// - Throws: 保存処理でエラーが発生した場合
    func save(_ entity: EntityType) async throws
    
    /// 指定されたIDのエンティティを削除する
    /// - Parameter id: 削除するエンティティのID
    /// - Throws: 削除処理でエラーが発生した場合
    func delete(id: String) async throws
    
    /// 指定されたIDのエンティティを取得する
    /// - Parameter id: 取得するエンティティのID
    /// - Returns: 取得したエンティティ（存在しない場合はnil）
    func fetchById(id: String) -> EntityType?
}
