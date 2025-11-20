//
//  DateFormatterUtilTests.swift
//  SportsNote_iOSTests
//
//  Created by Claude on 2025/11/17.
//

import Foundation
import Testing

@testable import SportsNote_iOS

@Suite("DateFormatterUtil Tests")
struct DateFormatterUtilTests {

    // MARK: - Helper Methods

    /// テスト用の特定日付を生成
    private func createDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return Calendar.current.date(from: components)!
    }

    // MARK: - 正常系テスト (Normal Cases)

    @Test("日付のみフォーマット - 通常の日付")
    func formatDateOnly_normalDate() {
        let date = createDate(year: 2025, month: 1, day: 15)
        let result = DateFormatterUtil.format(date, style: .dateOnly)
        #expect(result == "2025/01/15")
    }

    @Test("日付のみフォーマット - 互換性メソッド")
    func formatDateOnly_compatibilityMethod() {
        let date = createDate(year: 2025, month: 3, day: 20)
        let result = DateFormatterUtil.formatDateOnly(date)
        #expect(result == "2025/03/20")
    }

    @Test("日付と時刻フォーマット - デフォルトスタイル")
    func formatDateAndTime_defaultStyle() {
        let date = createDate(year: 2025, month: 1, day: 15, hour: 14, minute: 30)
        let result = DateFormatterUtil.format(date)
        // 日付部分が含まれていることを確認（ロケール依存のため厳密な比較は避ける）
        #expect(result.contains("2025") || result.contains("25"))
    }

    @Test("カスタムフォーマット - ISO8601形式")
    func formatCustom_iso8601() {
        let date = createDate(year: 2025, month: 6, day: 15, hour: 10, minute: 30, second: 45)
        let result = DateFormatterUtil.format(date, style: .custom("yyyy-MM-dd'T'HH:mm:ss"))
        #expect(result == "2025-06-15T10:30:45")
    }

    @Test("カスタムフォーマット - 年月のみ")
    func formatCustom_yearMonth() {
        let date = createDate(year: 2025, month: 12, day: 25)
        let result = DateFormatterUtil.format(date, style: .custom("yyyy年MM月"))
        #expect(result == "2025年12月")
    }

    @Test("カスタムフォーマット - 曜日付き")
    func formatCustom_withWeekday() {
        let date = createDate(year: 2025, month: 1, day: 1)  // 2025/1/1は水曜日
        let result = DateFormatterUtil.format(date, style: .custom("yyyy/MM/dd (E)"))
        #expect(result.contains("2025/01/01"))
    }

    // MARK: - 境界値テスト (Boundary Cases)

    @Test("年の境界値 - 年初")
    func formatDateOnly_startOfYear() {
        let date = createDate(year: 2025, month: 1, day: 1)
        let result = DateFormatterUtil.format(date, style: .dateOnly)
        #expect(result == "2025/01/01")
    }

    @Test("年の境界値 - 年末")
    func formatDateOnly_endOfYear() {
        let date = createDate(year: 2025, month: 12, day: 31)
        let result = DateFormatterUtil.format(date, style: .dateOnly)
        #expect(result == "2025/12/31")
    }

    @Test("うるう年 - 2月29日")
    func formatDateOnly_leapYear() {
        let date = createDate(year: 2024, month: 2, day: 29)
        let result = DateFormatterUtil.format(date, style: .dateOnly)
        #expect(result == "2024/02/29")
    }

    @Test("非うるう年 - 2月末日")
    func formatDateOnly_nonLeapYear() {
        let date = createDate(year: 2025, month: 2, day: 28)
        let result = DateFormatterUtil.format(date, style: .dateOnly)
        #expect(result == "2025/02/28")
    }

    @Test("月末日 - 30日の月")
    func formatDateOnly_thirtyDayMonth() {
        let date = createDate(year: 2025, month: 4, day: 30)
        let result = DateFormatterUtil.format(date, style: .dateOnly)
        #expect(result == "2025/04/30")
    }

    @Test("月末日 - 31日の月")
    func formatDateOnly_thirtyOneDayMonth() {
        let date = createDate(year: 2025, month: 7, day: 31)
        let result = DateFormatterUtil.format(date, style: .dateOnly)
        #expect(result == "2025/07/31")
    }

    @Test("時刻の境界値 - 深夜0時")
    func formatCustom_midnight() {
        let date = createDate(year: 2025, month: 1, day: 15, hour: 0, minute: 0, second: 0)
        let result = DateFormatterUtil.format(date, style: .custom("HH:mm:ss"))
        #expect(result == "00:00:00")
    }

    @Test("時刻の境界値 - 23時59分59秒")
    func formatCustom_endOfDay() {
        let date = createDate(year: 2025, month: 1, day: 15, hour: 23, minute: 59, second: 59)
        let result = DateFormatterUtil.format(date, style: .custom("HH:mm:ss"))
        #expect(result == "23:59:59")
    }

    @Test("過去の年 - 2000年")
    func formatDateOnly_year2000() {
        let date = createDate(year: 2000, month: 1, day: 1)
        let result = DateFormatterUtil.format(date, style: .dateOnly)
        #expect(result == "2000/01/01")
    }

    @Test("未来の年 - 2100年")
    func formatDateOnly_year2100() {
        let date = createDate(year: 2100, month: 12, day: 31)
        let result = DateFormatterUtil.format(date, style: .dateOnly)
        #expect(result == "2100/12/31")
    }

    // MARK: - 異常系テスト (Error Cases)

    @Test("空のカスタムフォーマット")
    func formatCustom_emptyFormat() {
        let date = createDate(year: 2025, month: 1, day: 15)
        let result = DateFormatterUtil.format(date, style: .custom(""))
        #expect(result == "")
    }

    @Test("無効なフォーマット文字を含むカスタムフォーマット")
    func formatCustom_invalidCharacters() {
        let date = createDate(year: 2025, month: 1, day: 15)
        // 無効なパターンでもDateFormatterはエラーを出さず、そのまま出力するか空文字列を返す
        let result = DateFormatterUtil.format(date, style: .custom("invalid"))
        #expect(result == "invalid" || result.isEmpty)
    }

    @Test("非常に長いカスタムフォーマット")
    func formatCustom_veryLongFormat() {
        let date = createDate(year: 2025, month: 1, day: 15)
        let longFormat = String(repeating: "yyyy/MM/dd ", count: 10)
        let result = DateFormatterUtil.format(date, style: .custom(longFormat))
        let expectedRepeated = String(repeating: "2025/01/15 ", count: 10)
        #expect(result == expectedRepeated)
    }

    // MARK: - パフォーマンステスト

    @Test("キャッシュされたフォーマッターの再利用確認")
    func formatDateOnly_cacheConsistency() {
        let date1 = createDate(year: 2025, month: 1, day: 15)
        let date2 = createDate(year: 2025, month: 6, day: 30)

        let result1 = DateFormatterUtil.formatDateOnly(date1)
        let result2 = DateFormatterUtil.formatDateOnly(date2)

        #expect(result1 == "2025/01/15")
        #expect(result2 == "2025/06/30")
    }

    @Test("複数回呼び出しで一貫した結果")
    func format_multipleCallsConsistent() {
        let date = createDate(year: 2025, month: 3, day: 15)

        let results = (1...10).map { _ in
            DateFormatterUtil.format(date, style: .dateOnly)
        }

        #expect(results.allSatisfy { $0 == "2025/03/15" })
    }
}
