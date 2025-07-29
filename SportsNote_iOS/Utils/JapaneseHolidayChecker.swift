import Foundation

class JapaneseHolidayChecker {
    private static let jpCalendar = Calendar(identifier: .gregorian)

    // 日本の祝日かどうかをチェック
    static func isJapaneseHoliday(_ date: Date) -> Bool {
        // 日付を年月日の形式に変換
        let year = jpCalendar.component(.year, from: date)
        let month = jpCalendar.component(.month, from: date)
        let day = jpCalendar.component(.day, from: date)

        // 固定の祝日をチェック
        if isFixedHoliday(month: month, day: day) {
            return true
        }

        // ハッピーマンデー制度の祝日をチェック
        if isHappyMondayHoliday(year: year, month: month, day: day) {
            return true
        }

        // 春分の日・秋分の日をチェック
        if isEquinoxDay(year: year, month: month, day: day) {
            return true
        }

        // 振替休日をチェック
        if isSubstituteHoliday(date) {
            return true
        }

        return false
    }

    // 固定祝日（毎年同じ月日の祝日）
    private static func isFixedHoliday(month: Int, day: Int) -> Bool {
        switch (month, day) {
        case (1, 1):  // 元日
            return true
        case (2, 11):  // 建国記念の日
            return true
        case (2, 23):  // 天皇誕生日
            return true
        case (4, 29):  // 昭和の日
            return true
        case (5, 3):  // 憲法記念日
            return true
        case (5, 4):  // みどりの日
            return true
        case (5, 5):  // こどもの日
            return true
        case (8, 11):  // 山の日
            return true
        case (11, 3):  // 文化の日
            return true
        case (11, 23):  // 勤労感謝の日
            return true
        default:
            return false
        }
    }

    // ハッピーマンデー制度の祝日（特定の月の第X月曜日）
    private static func isHappyMondayHoliday(year: Int, month: Int, day: Int) -> Bool {
        let date = dateFrom(year: year, month: month, day: day)
        let weekday = jpCalendar.component(.weekday, from: date)

        // 月曜日（2）かどうかチェック
        if weekday != 2 {
            return false
        }

        // 何週目の月曜日かを計算
        let weekOfMonth = jpCalendar.component(.weekOfMonth, from: date)

        switch (month, weekOfMonth) {
        case (1, 2):  // 成人の日（1月の第2月曜日）
            return true
        case (7, 3):  // 海の日（7月の第3月曜日）
            return true
        case (9, 3):  // 敬老の日（9月の第3月曜日）
            return true
        case (10, 2):  // スポーツの日（10月の第2月曜日）
            return true
        default:
            return false
        }
    }

    // 春分の日・秋分の日
    private static func isEquinoxDay(year: Int, month: Int, day: Int) -> Bool {
        if month == 3 {
            // 春分の日の計算式（おおよその計算）
            let springDay = Int(20.69115 + 0.2421904 * Double(year - 1900) - Double(Int((Double(year - 1900)) / 4.0)))
            return day == springDay
        } else if month == 9 {
            // 秋分の日の計算式（おおよその計算）
            let autumnDay = Int(23.09 + 0.2421904 * Double(year - 1900) - Double(Int((Double(year - 1900)) / 4.0)))
            return day == autumnDay
        }
        return false
    }

    // 振替休日（祝日が日曜日と重なった場合、次の平日が休日になる）
    private static func isSubstituteHoliday(_ date: Date) -> Bool {
        let weekday = jpCalendar.component(.weekday, from: date)

        // 月曜日でない場合は振替休日ではない
        if weekday != 2 {
            return false
        }

        // 前日（日曜日）が祝日かどうかチェック
        if let yesterday = jpCalendar.date(byAdding: .day, value: -1, to: date) {
            let isYesterdayHoliday =
                isFixedHoliday(
                    month: jpCalendar.component(.month, from: yesterday),
                    day: jpCalendar.component(.day, from: yesterday)
                )
                || isEquinoxDay(
                    year: jpCalendar.component(.year, from: yesterday),
                    month: jpCalendar.component(.month, from: yesterday),
                    day: jpCalendar.component(.day, from: yesterday)
                )

            if isYesterdayHoliday {
                return true
            }
        }

        return false
    }

    // 年月日からDate型を生成するヘルパーメソッド
    private static func dateFrom(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return jpCalendar.date(from: components) ?? Date()
    }
}
