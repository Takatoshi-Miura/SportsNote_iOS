import Foundation

/// 一意なID生成を提供するユーティリティクラス
///
/// アプリケーション全体で統一されたID生成を行うためのユーティリティ。
/// UUID v4形式の文字列を生成し、将来的な変更（ULID、Snowflake ID等）にも対応可能な設計。
///
/// # 使用例
/// ```swift
/// // 基本的な使用
/// let taskID = UUIDGenerator.generateID()
///
/// // デバッグ用のプレフィックス付きID（開発時のみ推奨）
/// #if DEBUG
/// let debugID = UUIDGenerator.generateID(withPrefix: "debug_task")
/// #endif
/// ```
final class UUIDGenerator {

    // MARK: - Public Methods

    /// UUID形式の一意な文字列IDを生成
    ///
    /// 標準的なUUID v4（ランダム生成）を使用してIDを生成します。
    /// 生成されるIDの形式: "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
    ///
    /// - Returns: UUID文字列（36文字、ハイフン区切り）
    ///
    /// # 使用例
    /// ```swift
    /// let newTaskID = UUIDGenerator.generateID()
    /// // 例: "123e4567-e89b-12d3-a456-426614174000"
    /// ```
    static func generateID() -> String {
        return UUID().uuidString
    }

    /// プレフィックス付きのIDを生成
    ///
    /// デバッグやテスト時に、IDの種別を識別しやすくするためのメソッド。
    /// 本番環境では使用せず、開発時のログ追跡やテストデータ生成に使用することを推奨。
    ///
    /// - Parameter prefix: IDの接頭辞（例: "test", "debug", "temp"）
    /// - Returns: プレフィックス付きUUID文字列
    ///
    /// # 使用例
    /// ```swift
    /// #if DEBUG
    /// let testID = UUIDGenerator.generateID(withPrefix: "test_user")
    /// // 例: "test_user_123e4567-e89b-12d3-a456-426614174000"
    /// #endif
    /// ```
    ///
    /// - Note: プレフィックスを付けることでIDが長くなるため、本番環境での使用は推奨しません
    static func generateID(withPrefix prefix: String) -> String {
        return "\(prefix)_\(UUID().uuidString)"
    }

    /// UUIDからハイフンを除去した短縮形式のIDを生成
    ///
    /// URLやファイル名などでハイフンが望ましくない場合に使用。
    /// 生成されるIDの形式: 32文字の英数字文字列
    ///
    /// - Returns: ハイフンなしのUUID文字列（32文字）
    ///
    /// # 使用例
    /// ```swift
    /// let compactID = UUIDGenerator.generateCompactID()
    /// // 例: "123e4567e89b12d3a456426614174000"
    /// ```
    static func generateCompactID() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    /// 既存のUUID文字列の検証
    ///
    /// 文字列が有効なUUID形式かどうかを検証します。
    ///
    /// - Parameter id: 検証するID文字列
    /// - Returns: 有効なUUID形式の場合はtrue
    ///
    /// # 使用例
    /// ```swift
    /// let isValid = UUIDGenerator.isValidUUID("123e4567-e89b-12d3-a456-426614174000")
    /// // true
    ///
    /// let isInvalid = UUIDGenerator.isValidUUID("invalid-id")
    /// // false
    /// ```
    static func isValidUUID(_ id: String) -> Bool {
        return UUID(uuidString: id) != nil
    }
}
