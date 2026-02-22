import Foundation

/// 日付フォーマット用のユーティリティクラス
final class DateFormatterUtil {
    // MARK: - Format Strings

    /// 日付のみ (例: "2025/01/15")
    static let formatDateOnly = "yyyy/MM/dd"
    /// 曜日付き日付 (例: "2025/3/15 (土)")
    static let formatDateWithDayOfWeek = "yyyy/M/d (E)"
    /// 曜日付き日付+時刻 (例: "2025/3/15 (土) 14:30")
    static let formatDateWithDayOfWeekAndTime = "yyyy/M/d (E) HH:mm"
    /// 日付+時刻 (例: "2025/3/15 14:30")
    static let formatDateAndTime = "yyyy/M/d HH:mm"

    // MARK: - Private Properties

    /// フォーマット文字列をキーにしたDateFormatterキャッシュ
    private nonisolated(unsafe) static var formatterCache: [String: DateFormatter] = [:]

    // MARK: - Private Methods

    /// フォーマット文字列に対応するキャッシュ済みDateFormatterを返す
    private static func formatter(for formatString: String) -> DateFormatter {
        if let cached = formatterCache[formatString] {
            return cached
        }
        let formatter = DateFormatter()
        formatter.dateFormat = formatString
        formatterCache[formatString] = formatter
        return formatter
    }

    // MARK: - Public Methods

    /// 日付を指定フォーマット文字列でフォーマットする
    /// - Parameters:
    ///   - date: フォーマットする日付
    ///   - formatString: フォーマット文字列（DateFormatterUtil.format* 定数を推奨）
    /// - Returns: フォーマットされた日付文字列
    static func format(_ date: Date, formatString: String) -> String {
        return formatter(for: formatString).string(from: date)
    }

    /// 日付を "yyyy/MM/dd" 形式でフォーマットする (例: "2025/01/15")
    static func formatDateOnly(_ date: Date) -> String {
        return format(date, formatString: formatDateOnly)
    }

    /// 日付を曜日付き形式でフォーマットする (例: "2025/3/15 (土)")
    static func formatDateWithDayOfWeek(_ date: Date) -> String {
        return format(date, formatString: formatDateWithDayOfWeek)
    }

    /// 日付を曜日付き日付+時刻形式でフォーマットする (例: "2025/3/15 (土) 14:30")
    static func formatDateWithDayOfWeekAndTime(_ date: Date) -> String {
        return format(date, formatString: formatDateWithDayOfWeekAndTime)
    }

    /// 日付を日付+時刻形式でフォーマットする (例: "2025/3/15 14:30")
    static func formatDateAndTime(_ date: Date) -> String {
        return format(date, formatString: formatDateAndTime)
    }
}
