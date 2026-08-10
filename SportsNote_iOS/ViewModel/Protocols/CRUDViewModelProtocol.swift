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

extension CRUDViewModelProtocol where Self: FirebaseSyncable {
    /// 指定されたIDのエンティティを削除する共通実装
    ///
    /// フロー: 削除前オブジェクト取得 → 論理削除 → Firebase同期をバックグラウンドで実行
    /// → ローカルキャッシュから除去 → 成功時追加処理 → Result返却
    /// - Parameters:
    ///   - id: 削除するエンティティのID
    ///   - context: エラー変換時のコンテキスト（メソッド名など）
    ///   - removeFromLocalCache: ローカルの@Publishedプロパティから対象を除去する処理。
    ///     配列構造・除去方法はViewModelごとに異なるため呼び出し元に委譲する
    ///   - onSuccess: 削除成功時に追加で実行する処理（例: hideErrorAlert、通知送信）
    /// - Returns: 成功時は.success(())、失敗時は.failure(SportsNoteError)
    func deleteDefault(
        id: String,
        context: String,
        removeFromLocalCache: () throws -> Void,
        onSuccess: (() -> Void)? = nil
    ) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // 削除前にオブジェクトを取得（論理削除後はisDeleted=trueで取得できなくなるため）
            let entityToDelete = try RealmManager.shared.getObjectById(id: id, type: EntityType.self)

            // Realm操作はMainActorで実行
            try RealmManager.shared.logicalDelete(id: id, type: EntityType.self)

            // Firebase同期はバックグラウンドで実行（削除前に取得したオブジェクトを使用）
            // performBackgroundSync自体が内部でTaskを生成しBackgroundSyncTrackerに追跡登録するため、
            // ここをさらにTaskでラップする必要はない
            if let entityToDelete = entityToDelete {
                performBackgroundSync(entityToDelete, isUpdate: true)
            }

            // ローカルキャッシュからの除去はViewModelごとに異なるため呼び出し元に委譲
            try removeFromLocalCache()

            onSuccess?()
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: context)
            return .failure(sportsNoteError)
        }
    }
}
