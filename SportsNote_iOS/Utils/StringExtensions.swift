import Foundation

/// String型の拡張ユーティリティ
///
/// 文字列操作を簡潔に記述するためのヘルパーメソッド群。
/// 空白判定などの共通ロジックを集約し、コードの重複を防ぐことを目的とする。
extension String {

    // MARK: - Blank Check

    /// 空文字列、または空白・改行のみで構成されているかどうかを判定
    /// - Returns: 空白のみ（または空文字列）の場合はtrue
    var isBlank: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
