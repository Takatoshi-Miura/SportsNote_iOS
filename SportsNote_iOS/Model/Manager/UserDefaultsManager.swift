import Foundation

class UserDefaultsManager {
    /// キー一覧
    struct Keys {
        static let firstLaunch = "firstLaunch" // 初回起動判定
        static let userID = "userID" // アカウント持ちならFirebaseID、なければ端末のUID
        static let address = "address" // アカウントのメールアドレス
        static let password = "password" // アカウントのパスワード
        static let isLogin = "isLogin" // ログイン状態
        static let agree = "agree" // 利用規約への同意状況
    }
    
    nonisolated(unsafe) private static let userDefaults = UserDefaults.standard
    nonisolated(unsafe) private static var cachedUserID: String?
    
    private static func getEditor() -> UserDefaults {
        return userDefaults
    }
    
    /// 保存処理
    /// - Parameters:
    ///   - key: キー
    ///   - value: 値
    static func set<T>(key: String, value: T) {
        if key == Keys.userID {
            cachedUserID = value as? String
        }
        
        switch value {
        case let value as Int:
            userDefaults.set(value, forKey: key)
        case let value as Float:
            userDefaults.set(value, forKey: key)
        case let value as Double:
            userDefaults.set(value, forKey: key)
        case let value as Bool:
            userDefaults.set(value, forKey: key)
        case let value as String:
            userDefaults.set(value, forKey: key)
        default:
            fatalError("Unsupported type")
        }
    }
    
    /// 取得処理
    /// - Parameters:
    ///   - key: キー
    ///   - defaultValue: デフォルト値
    /// - Returns: 保存データ(存在しない場合はデフォルト値)
    static func get<T>(key: String, defaultValue: T) -> T {
        // ユーザーIDの特別な処理
        if key == Keys.userID {
            if let cachedID = cachedUserID as? T {
                return cachedID
            }
            if let savedID = userDefaults.string(forKey: key) {
                cachedUserID = savedID
                return savedID as! T
            }
            let newID = UUID().uuidString
            set(key: key, value: newID)
            return newID as! T
        }
        
        // 通常の処理
        if let value = userDefaults.value(forKey: key) as? T {
            return value
        } else {
            return defaultValue
        }
    }
    
    /// 削除処理
    /// - Parameter key: キー
    static func remove(key: String) {
        if key == Keys.userID {
            cachedUserID = nil
        }
        userDefaults.removeObject(forKey: key)
    }
    
    /// UserDefaultsの全データを削除
    static func clearAll() {
        cachedUserID = nil
        for key in userDefaults.dictionaryRepresentation().keys {
            userDefaults.removeObject(forKey: key)
        }
    }
    
    /// ユーザIDを再生成
    static func resetUserInfo(userID: String = UUID().uuidString) {
        set(key: Keys.userID, value: userID)
    }
}
