import Foundation

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
}

extension FirebaseSyncable where Self: BaseViewModelProtocol {
    /// Firebase同期をバックグラウンドで実行する共通メソッド
    /// エラー発生時は既存のエラーがない場合のみshowErrorAlertを呼び出す
    /// - Parameters:
    ///   - entity: 同期するエンティティ
    ///   - isUpdate: 更新かどうか（デフォルトはfalse）
    func performBackgroundSync(_ entity: EntityType, isUpdate: Bool = false) {
        Task {
            let result = await syncEntityToFirebase(entity, isUpdate: isUpdate)
            if case .failure(let error) = result, currentError == nil {
                showErrorAlert(error)
            }
        }
    }
}
