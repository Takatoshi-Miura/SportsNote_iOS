import Foundation

/// 日付フォーマット用のユーティリティクラス
final class DateFormatterUtil {
    /// 日付フォーマットスタイル
    enum FormatStyle {
        /// 日付のみ (例: "2025/01/15")
        case dateOnly
        /// 日付と時刻 (例: "2025年1月15日 14:30")
        case dateAndTime
        /// カスタムフォーマット
        case custom(String)
    }

    // MARK: - Private Properties

    /// キャッシュされたDateFormatterインスタンス（パフォーマンス最適化）
    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    private static let dateAndTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Public Methods

    /// 日付を指定されたスタイルでフォーマットする
    /// - Parameters:
    ///   - date: フォーマットする日付
    ///   - style: フォーマットスタイル（デフォルト: .dateAndTime）
    /// - Returns: フォーマットされた日付文字列
    static func format(_ date: Date, style: FormatStyle = .dateAndTime) -> String {
        switch style {
        case .dateOnly:
            return dateOnlyFormatter.string(from: date)
        case .dateAndTime:
            return dateAndTimeFormatter.string(from: date)
        case .custom(let formatString):
            let formatter = DateFormatter()
            formatter.dateFormat = formatString
            return formatter.string(from: date)
        }
    }

    /// 日付を "yyyy/MM/dd" 形式でフォーマットする（互換性用）
    /// - Parameter date: フォーマットする日付
    /// - Returns: フォーマットされた日付文字列
    static func formatDateOnly(_ date: Date) -> String {
        return format(date, style: .dateOnly)
    }

    /// 日付を日付+時刻形式でフォーマットする（互換性用）
    /// - Parameter date: フォーマットする日付
    /// - Returns: フォーマットされた日付文字列
    static func formatDateAndTime(_ date: Date) -> String {
        return format(date, style: .dateAndTime)
    }
}
