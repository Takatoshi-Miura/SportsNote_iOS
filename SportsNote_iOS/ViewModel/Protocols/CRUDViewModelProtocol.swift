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
            // logicalDeleteはカスケードで論理削除された子エンティティ（TaskData/Measures/Memo）を返す（issue #181）
            let cascade = try RealmManager.shared.logicalDelete(id: id, type: EntityType.self)

            // Firebase同期はバックグラウンドで実行（削除前に取得したオブジェクトを使用）
            // performBackgroundSync自体が内部でTaskを生成しBackgroundSyncTrackerに追跡登録するため、
            // ここをさらにTaskでラップする必要はない
            if let entityToDelete = entityToDelete {
                performBackgroundSync(entityToDelete, isUpdate: true)
            }
            // カスケードで論理削除された子エンティティもFirebaseに同期する（issue #181）
            performCascadeBackgroundSync(cascade)

            // ローカルキャッシュからの除去はViewModelごとに異なるため呼び出し元に委譲
            try removeFromLocalCache()

            onSuccess?()
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: context)
            return .failure(sportsNoteError)
        }
    }

    /// カスケードで論理削除された子エンティティ（TaskData/Measures/Memo）をバックグラウンドでFirebaseに同期する
    ///
    /// Group/TaskData/Measures/Noteの削除時、RealmManager.logicalDeleteは同一トランザクション内で
    /// 子エンティティも再帰的に論理削除するが、削除対象本体のみをperformBackgroundSyncで同期していると
    /// カスケード分がFirebaseに反映されず孤立データが残ってしまう（issue #181）。
    /// performBackgroundSyncと同様、Task生成・BackgroundSyncTrackerへの追跡登録は
    /// オンライン状態に関わらず同期的に行い（issue #164の回帰パターンを踏襲）、
    /// 実際のFirebase呼び出しのみTask内でisOnlineAndLoggedInによりガードする。
    /// - Parameter cascade: logicalDeleteが返したカスケード削除対象
    private func performCascadeBackgroundSync(_ cascade: CascadeDeletedEntities) {
        guard !cascade.isEmpty else { return }

        let task = Task {
            guard isOnlineAndLoggedIn else { return }

            for taskData in cascade.tasks {
                do {
                    try await FirebaseManager.shared.updateTask(task: taskData)
                } catch {
                    print("Failed to sync cascade-deleted TaskData to Firebase: \(error)")
                }
            }
            for measures in cascade.measures {
                do {
                    try await FirebaseManager.shared.updateMeasures(measures: measures)
                } catch {
                    print("Failed to sync cascade-deleted Measures to Firebase: \(error)")
                }
            }
            for memo in cascade.memos {
                do {
                    try await FirebaseManager.shared.updateMemo(memo: memo)
                } catch {
                    print("Failed to sync cascade-deleted Memo to Firebase: \(error)")
                }
            }
        }
        BackgroundSyncTracker.shared.track(task)
    }
}
