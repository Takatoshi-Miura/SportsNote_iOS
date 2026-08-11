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

    /// fetchData()の共通実装（isLoadingトグル・エラーハンドリングを一元化）
    /// - Parameters:
    ///   - context: エラー変換時のコンテキスト（メソッド名など）
    ///   - operation: Realm取得と@Publishedプロパティへの代入を行うクロージャ
    ///   - onSuccess: 取得成功時に追加で実行する処理（例: hideErrorAlert）
    /// - Returns: 成功時は.success(())、失敗時は.failure(SportsNoteError)
    func fetchDataDefault(
        context: String,
        operation: () throws -> Void,
        onSuccess: (() -> Void)? = nil
    ) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            try operation()
            onSuccess?()
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: context)
            return .failure(sportsNoteError)
        }
    }
}

extension CRUDViewModelProtocol where EntityType: UserOwnedEntity {
    /// save(_:isUpdate:)の共通実装（isLoadingトグル・userID巻き戻し・Realm保存・エラーハンドリングを一元化）
    ///
    /// Firebase同期・ローカル配列の再取得・ViewModel固有の追加処理（通知送信やhideErrorAlert呼び出しの
    /// 有無など）はafterSaveクロージャに委譲することで、ViewModelごとに異なる挙動をそのまま維持する。
    /// - Parameters:
    ///   - entity: 保存するエンティティ
    ///   - isUpdate: 更新かどうか
    ///   - context: エラー変換時のコンテキスト（メソッド名など）
    ///   - afterSave: Realm保存成功後に実行する処理（Firebase同期・UI更新等をまとめて渡す）
    /// - Returns: 成功時は.success(())、失敗時は.failure(SportsNoteError)
    func saveDefault(
        _ entity: EntityType,
        isUpdate: Bool,
        context: String,
        afterSave: () throws -> Void
    ) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // 更新時は、エンティティ再構築時にUserDefaultsの現在値で上書きされてしまったuserIDを、
            // Realmに永続化済みの値に戻す（アカウント作成直後のuserID切替タイミングでも
            // Firebase更新が正しいドキュメントIDに対して行われるようにするため。issue #74）
            if isUpdate,
                let existing = try RealmManager.shared.getObjectById(id: entity.entityID, type: EntityType.self)
            {
                entity.userID = existing.userID
            }

            // Realm操作はMainActorで実行
            try RealmManager.shared.saveItem(entity)

            // Firebase同期・UI更新・追加処理は呼び出し側に委譲
            try afterSave()

            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: context)
            return .failure(sportsNoteError)
        }
    }
}
