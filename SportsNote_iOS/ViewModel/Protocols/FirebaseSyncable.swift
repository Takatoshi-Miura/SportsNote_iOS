import Foundation

/// Firebase同期機能を持つViewModelのプロトコル
protocol FirebaseSyncable {
    /// ViewModelが扱うエンティティの型
    associatedtype EntityType
    
    /// Firebaseへの同期処理を実行する
    /// - Throws: 同期処理でエラーが発生した場合
    func syncToFirebase() async throws
    
    /// オンライン状態かつログイン済みかを判定する
    /// Firebase同期が可能な状態かを確認するために使用
    var isOnlineAndLoggedIn: Bool { get }
    
    /// 指定されたエンティティをFirebaseに同期する
    /// - Parameter entity: 同期するエンティティ
    /// - Throws: 同期処理でエラーが発生した場合
    func syncEntityToFirebase(_ entity: EntityType) async throws
}

extension FirebaseSyncable {
    /// デフォルトのオンライン・ログイン状態判定
    /// Network.isOnline()とUserDefaultsのログイン状態をチェック
    var isOnlineAndLoggedIn: Bool {
        return Network.isOnline() && 
               UserDefaultsManager.get(key: UserDefaultsManager.Keys.isLogin, defaultValue: false)
    }
}
