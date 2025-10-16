import Foundation

/// Date型の拡張ユーティリティ
///
/// 日付操作を簡潔に記述するためのヘルパーメソッド群。
/// カレンダー操作のパフォーマンス最適化とコードの可読性向上を目的とする。
extension Date {

    // MARK: - Calendar Component Access

    /// 指定したカレンダーコンポーネントの値を取得
    /// - Parameter component: 取得したいカレンダーコンポーネント（年、月、日など）
    /// - Returns: コンポーネントの整数値
    func get(_ component: Calendar.Component) -> Int {
        return Calendar.current.component(component, from: self)
    }

    // MARK: - Day Boundaries

    /// 日付の開始時刻（00:00:00）を取得
    /// - Returns: 同じ日の0時0分0秒の日付
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    /// 日付の終了時刻（23:59:59）を取得
    /// - Returns: 同じ日の23時59分59秒の日付
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    // MARK: - Month and Year Boundaries

    /// 月の開始日（その月の1日の00:00:00）を取得
    /// - Returns: 同じ月の1日0時0分0秒の日付
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    /// 月の終了日（その月の最終日の23:59:59）を取得
    /// - Returns: 同じ月の最終日23時59分59秒の日付
    var endOfMonth: Date {
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth),
            let lastDayOfMonth = Calendar.current.date(byAdding: .second, value: -1, to: nextMonth)
        else {
            return self
        }
        return lastDayOfMonth
    }

    /// 年の開始日（その年の1月1日の00:00:00）を取得
    /// - Returns: 同じ年の1月1日0時0分0秒の日付
    var startOfYear: Date {
        let components = Calendar.current.dateComponents([.year], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    // MARK: - Date Comparison

    /// 指定した日付と同じ日かどうかを判定
    /// - Parameter date: 比較対象の日付
    /// - Returns: 同じ日の場合はtrue
    func isSameDay(as date: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: date)
    }

    /// 今日かどうかを判定
    /// - Returns: 今日の場合はtrue
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }

    /// 明日かどうかを判定
    /// - Returns: 明日の場合はtrue
    var isTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(self)
    }

    /// 昨日かどうかを判定
    /// - Returns: 昨日の場合はtrue
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }

    // MARK: - Date Arithmetic

    /// 指定した日数を加算した日付を取得
    /// - Parameter days: 加算する日数（負の値で減算）
    /// - Returns: 計算後の日付
    func adding(days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// 指定した月数を加算した日付を取得
    /// - Parameter months: 加算する月数（負の値で減算）
    /// - Returns: 計算後の日付
    func adding(months: Int) -> Date {
        return Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    /// 指定した年数を加算した日付を取得
    /// - Parameter years: 加算する年数（負の値で減算）
    /// - Returns: 計算後の日付
    func adding(years: Int) -> Date {
        return Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }
}
