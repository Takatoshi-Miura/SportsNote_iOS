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
        return Network.isOnline() && UserDefaultsManager.get(key: UserDefaultsManager.Keys.isLogin, defaultValue: false)
    }
}
