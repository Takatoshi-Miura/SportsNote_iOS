import Foundation
import RealmSwift

/// Firebase同期機能を持つViewModelのプロトコル
@MainActor
protocol FirebaseSyncable {
    /// ViewModelが扱うエンティティの型
    associatedtype EntityType

    /// Firebaseへの同期処理を実行する
    /// - Returns: 同期処理の結果
    func syncToFirebase() async -> Result<Void, SportsNoteError>

    /// オンライン状態かつログイン済みかを判定する
    /// Firebase同期が可能な状態かを確認するために使用
    var isOnlineAndLoggedIn: Bool { get }

    /// 指定されたエンティティをFirebaseに同期する
    /// - Parameter entity: 同期するエンティティ
    /// - Parameter isUpdate: 更新かどうか（デフォルトはfalse）
    /// - Returns: 同期処理の結果
    func syncEntityToFirebase(_ entity: EntityType, isUpdate: Bool) async -> Result<Void, SportsNoteError>
}

extension FirebaseSyncable {
    /// デフォルトのオンライン・ログイン状態判定
    /// Network.isOnline()とUserDefaultsのログイン状態をチェック
    var isOnlineAndLoggedIn: Bool {
        #if DEBUG
            // テスト用インメモリRealm使用時はFirebase同期を行わない
            // （バックグラウンドTaskが保持するRealmオブジェクトが、後続テストの
            //   Realm切り替えによりinvalidateされてクラッシュするのを防ぐ）
            if RealmManager.shared.testConfiguration != nil {
                return false
            }
        #endif
        return Network.isOnline() && UserDefaultsManager.get(key: UserDefaultsManager.Keys.isLogin, defaultValue: false)
    }

    /// Firebase同期処理で発生したエラーをSportsNoteErrorに変換する共通処理
    /// FirebaseManager内部（saveDocument等）で既にErrorMapper.mapFirebaseErrorにより
    /// 変換済みのSportsNoteErrorが伝播してきた場合は再変換せずそのまま返す。
    /// SportsNoteErrorはCustomNSErrorに準拠していないため、NSErrorへブリッジされる際に
    /// codeへenum宣言順のオーディナルが入り、再度mapFirebaseErrorにかけると
    /// 全く異なるエラー種別に化けてしまう問題を防ぐ（issue #36）。
    /// - Parameters:
    ///   - error: 発生したエラー
    ///   - context: エラーが発生したコンテキスト（メソッド名など）
    /// - Returns: 変換されたSportsNoteError
    func convertFirebaseSyncError(_ error: Error, context: String) -> SportsNoteError {
        if let existingSportsNoteError = error as? SportsNoteError {
            return existingSportsNoteError
        }
        return ErrorMapper.mapFirebaseError(error, context: context)
    }

    /// エンティティをFirebaseに同期する共通実装
    /// - Parameters:
    ///   - isUpdate: 更新かどうか
    ///   - context: エラー変換時のコンテキスト（メソッド名など）
    ///   - updateAction: 更新時に呼び出すFirebaseManagerの処理
    ///   - saveAction: 新規作成時に呼び出すFirebaseManagerの処理
    /// - Returns: 同期処理の結果
    func syncEntityToFirebaseDefault(
        isUpdate: Bool,
        context: String,
        updateAction: () async throws -> Void,
        saveAction: () async throws -> Void
    ) async -> Result<Void, SportsNoteError> {
        guard isOnlineAndLoggedIn else { return .success(()) }

        do {
            if isUpdate {
                try await updateAction()
            } else {
                try await saveAction()
            }
            return .success(())
        } catch {
            let sportsNoteError = convertFirebaseSyncError(error, context: context)
            return .failure(sportsNoteError)
        }
    }
}

extension FirebaseSyncable where Self: BaseViewModelProtocol {
    /// Firebase同期をバックグラウンドで実行する共通メソッド
    /// エラー発生時は既存のエラーがない場合のみshowErrorAlertを呼び出す
    /// - Parameters:
    ///   - entity: 同期するエンティティ
    ///   - isUpdate: 更新かどうか（デフォルトはfalse）
    func performBackgroundSync(_ entity: EntityType, isUpdate: Bool = false) {
        let task = Task {
            let result = await syncEntityToFirebase(entity, isUpdate: isUpdate)
            if case .failure(let error) = result, currentError == nil {
                showErrorAlert(error)
            }
        }
        // ログアウト/アカウント削除等でのRealm全削除前に完了を待機できるよう追跡登録する（Issue #84対応）
        BackgroundSyncTracker.shared.track(task)
    }
}

extension FirebaseSyncable where Self: BaseViewModelProtocol, EntityType: Object {
    /// 全エンティティをFirebaseに同期する共通実装
    /// - Parameter context: エラー変換時のコンテキスト（メソッド名など）
    /// - Returns: 同期処理の結果
    func syncToFirebaseDefault(context: String) async -> Result<Void, SportsNoteError> {
        guard isOnlineAndLoggedIn else { return .success(()) }

        do {
            let allEntities = try RealmManager.shared.getDataList(clazz: EntityType.self)
            for entity in allEntities {
                let result = await syncEntityToFirebase(entity, isUpdate: false)
                if case .failure(let error) = result {
                    return .failure(error)
                }
            }
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: context)
            return .failure(sportsNoteError)
        }
    }
}
