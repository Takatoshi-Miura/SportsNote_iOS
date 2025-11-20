//
//  DateExtensionsTests.swift
//  SportsNote_iOSTests
//
//  Created by Claude on 2025/11/17.
//

import Foundation
import Testing

@testable import SportsNote_iOS

@Suite("DateExtensions Tests")
struct DateExtensionsTests {

    // MARK: - Helper Methods

    /// テスト用の特定日付を生成
    private func createDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        minute: Int = 30,
        second: Int = 45
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

    // MARK: - Calendar Component Access Tests

    @Test("年コンポーネント取得 - 正常値")
    func getYear_normalValue() {
        let date = createDate(year: 2025, month: 6, day: 15)
        #expect(date.get(.year) == 2025)
    }

    @Test("月コンポーネント取得 - 正常値")
    func getMonth_normalValue() {
        let date = createDate(year: 2025, month: 6, day: 15)
        #expect(date.get(.month) == 6)
    }

    @Test("日コンポーネント取得 - 正常値")
    func getDay_normalValue() {
        let date = createDate(year: 2025, month: 6, day: 15)
        #expect(date.get(.day) == 15)
    }

    @Test("時コンポーネント取得 - 正常値")
    func getHour_normalValue() {
        let date = createDate(year: 2025, month: 6, day: 15, hour: 14)
        #expect(date.get(.hour) == 14)
    }

    @Test("分コンポーネント取得 - 正常値")
    func getMinute_normalValue() {
        let date = createDate(year: 2025, month: 6, day: 15, hour: 14, minute: 30)
        #expect(date.get(.minute) == 30)
    }

    @Test("秒コンポーネント取得 - 正常値")
    func getSecond_normalValue() {
        let date = createDate(year: 2025, month: 6, day: 15, hour: 14, minute: 30, second: 45)
        #expect(date.get(.second) == 45)
    }

    @Test("曜日コンポーネント取得")
    func getWeekday() {
        let date = createDate(year: 2025, month: 1, day: 1)  // 水曜日
        let weekday = date.get(.weekday)
        #expect(weekday >= 1 && weekday <= 7)
    }

    // MARK: - Day Boundaries Tests

    @Test("日の開始時刻 - 通常の日付")
    func startOfDay_normalDate() {
        let date = createDate(year: 2025, month: 6, day: 15, hour: 14, minute: 30, second: 45)
        let result = date.startOfDay

        #expect(result.get(.year) == 2025)
        #expect(result.get(.month) == 6)
        #expect(result.get(.day) == 15)
        #expect(result.get(.hour) == 0)
        #expect(result.get(.minute) == 0)
        #expect(result.get(.second) == 0)
    }

    @Test("日の終了時刻 - 通常の日付")
    func endOfDay_normalDate() {
        let date = createDate(year: 2025, month: 6, day: 15, hour: 14, minute: 30, second: 45)
        let result = date.endOfDay

        #expect(result.get(.year) == 2025)
        #expect(result.get(.month) == 6)
        #expect(result.get(.day) == 15)
        #expect(result.get(.hour) == 23)
        #expect(result.get(.minute) == 59)
        #expect(result.get(.second) == 59)
    }

    @Test("日の終了時刻 - 月末境界")
    func endOfDay_endOfMonth() {
        let date = createDate(year: 2025, month: 1, day: 31)
        let result = date.endOfDay

        #expect(result.get(.day) == 31)
        #expect(result.get(.hour) == 23)
        #expect(result.get(.minute) == 59)
    }

    // MARK: - Month Boundaries Tests

    @Test("月の開始日 - 月中の日付")
    func startOfMonth_midMonth() {
        let date = createDate(year: 2025, month: 6, day: 15)
        let result = date.startOfMonth

        #expect(result.get(.year) == 2025)
        #expect(result.get(.month) == 6)
        #expect(result.get(.day) == 1)
        #expect(result.get(.hour) == 0)
    }

    @Test("月の開始日 - すでに1日の場合")
    func startOfMonth_alreadyFirst() {
        let date = createDate(year: 2025, month: 6, day: 1)
        let result = date.startOfMonth

        #expect(result.get(.day) == 1)
    }

    @Test("月の終了日 - 31日の月")
    func endOfMonth_thirtyOneDays() {
        let date = createDate(year: 2025, month: 1, day: 15)
        let result = date.endOfMonth

        #expect(result.get(.year) == 2025)
        #expect(result.get(.month) == 1)
        #expect(result.get(.day) == 31)
        #expect(result.get(.hour) == 23)
        #expect(result.get(.minute) == 59)
        #expect(result.get(.second) == 59)
    }

    @Test("月の終了日 - 30日の月")
    func endOfMonth_thirtyDays() {
        let date = createDate(year: 2025, month: 4, day: 10)
        let result = date.endOfMonth

        #expect(result.get(.day) == 30)
    }

    @Test("月の終了日 - うるう年の2月")
    func endOfMonth_februaryLeapYear() {
        let date = createDate(year: 2024, month: 2, day: 10)
        let result = date.endOfMonth

        #expect(result.get(.day) == 29)
    }

    @Test("月の終了日 - 非うるう年の2月")
    func endOfMonth_februaryNonLeapYear() {
        let date = createDate(year: 2025, month: 2, day: 10)
        let result = date.endOfMonth

        #expect(result.get(.day) == 28)
    }

    // MARK: - Year Boundaries Tests

    @Test("年の開始日 - 年中の日付")
    func startOfYear_midYear() {
        let date = createDate(year: 2025, month: 6, day: 15)
        let result = date.startOfYear

        #expect(result.get(.year) == 2025)
        #expect(result.get(.month) == 1)
        #expect(result.get(.day) == 1)
        #expect(result.get(.hour) == 0)
    }

    @Test("年の開始日 - すでに1月1日の場合")
    func startOfYear_alreadyFirstDay() {
        let date = createDate(year: 2025, month: 1, day: 1)
        let result = date.startOfYear

        #expect(result.get(.year) == 2025)
        #expect(result.get(.month) == 1)
        #expect(result.get(.day) == 1)
    }

    // MARK: - Date Comparison Tests

    @Test("同じ日の比較 - true")
    func isSameDay_sameDay() {
        let date1 = createDate(year: 2025, month: 6, day: 15, hour: 10, minute: 0)
        let date2 = createDate(year: 2025, month: 6, day: 15, hour: 20, minute: 30)

        #expect(date1.isSameDay(as: date2))
    }

    @Test("同じ日の比較 - false（異なる日）")
    func isSameDay_differentDay() {
        let date1 = createDate(year: 2025, month: 6, day: 15)
        let date2 = createDate(year: 2025, month: 6, day: 16)

        #expect(!date1.isSameDay(as: date2))
    }

    @Test("同じ日の比較 - false（異なる月）")
    func isSameDay_differentMonth() {
        let date1 = createDate(year: 2025, month: 6, day: 15)
        let date2 = createDate(year: 2025, month: 7, day: 15)

        #expect(!date1.isSameDay(as: date2))
    }

    @Test("同じ日の比較 - false（異なる年）")
    func isSameDay_differentYear() {
        let date1 = createDate(year: 2025, month: 6, day: 15)
        let date2 = createDate(year: 2024, month: 6, day: 15)

        #expect(!date1.isSameDay(as: date2))
    }

    @Test("今日かどうか - Date()は今日")
    func isToday_currentDate() {
        let today = Date()
        #expect(today.isToday)
    }

    @Test("今日かどうか - 昨日はfalse")
    func isToday_yesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        #expect(!yesterday.isToday)
    }

    @Test("明日かどうか - 明日の日付")
    func isTomorrow_tomorrowDate() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        #expect(tomorrow.isTomorrow)
    }

    @Test("明日かどうか - 今日はfalse")
    func isTomorrow_today() {
        let today = Date()
        #expect(!today.isTomorrow)
    }

    @Test("昨日かどうか - 昨日の日付")
    func isYesterday_yesterdayDate() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        #expect(yesterday.isYesterday)
    }

    @Test("昨日かどうか - 今日はfalse")
    func isYesterday_today() {
        let today = Date()
        #expect(!today.isYesterday)
    }

    // MARK: - Date Arithmetic Tests

    @Test("日数加算 - 正の値")
    func addingDays_positive() {
        let date = createDate(year: 2025, month: 6, day: 15)
        let result = date.adding(days: 10)

        #expect(result.get(.day) == 25)
    }

    @Test("日数加算 - 負の値（減算）")
    func addingDays_negative() {
        let date = createDate(year: 2025, month: 6, day: 15)
        let result = date.adding(days: -10)

        #expect(result.get(.day) == 5)
    }

    @Test("日数加算 - 月をまたぐ")
    func addingDays_crossMonth() {
        let date = createDate(year: 2025, month: 1, day: 31)
        let result = date.adding(days: 1)

        #expect(result.get(.month) == 2)
        #expect(result.get(.day) == 1)
    }

    @Test("日数加算 - 年をまたぐ")
    func addingDays_crossYear() {
        let date = createDate(year: 2025, month: 12, day: 31)
        let result = date.adding(days: 1)

        #expect(result.get(.year) == 2026)
        #expect(result.get(.month) == 1)
        #expect(result.get(.day) == 1)
    }

    @Test("月数加算 - 正の値")
    func addingMonths_positive() {
        let date = createDate(year: 2025, month: 6, day: 15)
        let result = date.adding(months: 3)

        #expect(result.get(.month) == 9)
        #expect(result.get(.day) == 15)
    }

    @Test("月数加算 - 負の値（減算）")
    func addingMonths_negative() {
        let date = createDate(year: 2025, month: 6, day: 15)
        let result = date.adding(months: -3)

        #expect(result.get(.month) == 3)
    }

    @Test("月数加算 - 年をまたぐ")
    func addingMonths_crossYear() {
        let date = createDate(year: 2025, month: 11, day: 15)
        let result = date.adding(months: 3)

        #expect(result.get(.year) == 2026)
        #expect(result.get(.month) == 2)
    }

    @Test("月数加算 - 日数が存在しない場合")
    func addingMonths_dayDoesNotExist() {
        let date = createDate(year: 2025, month: 1, day: 31)
        let result = date.adding(months: 1)

        // 2月31日は存在しないため、調整される
        #expect(result.get(.month) == 2 || result.get(.month) == 3)
    }

    @Test("年数加算 - 正の値")
    func addingYears_positive() {
        let date = createDate(year: 2025, month: 6, day: 15)
        let result = date.adding(years: 5)

        #expect(result.get(.year) == 2030)
        #expect(result.get(.month) == 6)
        #expect(result.get(.day) == 15)
    }

    @Test("年数加算 - 負の値（減算）")
    func addingYears_negative() {
        let date = createDate(year: 2025, month: 6, day: 15)
        let result = date.adding(years: -5)

        #expect(result.get(.year) == 2020)
    }

    @Test("年数加算 - うるう年の2月29日")
    func addingYears_leapYearDate() {
        let date = createDate(year: 2024, month: 2, day: 29)
        let result = date.adding(years: 1)

        // 2025年2月29日は存在しないため、調整される
        #expect(result.get(.year) == 2025)
        #expect(result.get(.month) == 2 || result.get(.month) == 3)
    }

    // MARK: - 境界値テスト

    @Test("境界値 - ゼロ日数加算")
    func addingDays_zero() {
        let date = createDate(year: 2025, month: 6, day: 15)
        let result = date.adding(days: 0)

        #expect(date.isSameDay(as: result))
    }

    @Test("境界値 - 非常に大きな日数加算")
    func addingDays_veryLarge() {
        let date = createDate(year: 2025, month: 1, day: 1)
        let result = date.adding(days: 365)

        #expect(result.get(.year) == 2026)
        #expect(result.get(.month) == 1)
        #expect(result.get(.day) == 1)
    }

    @Test("境界値 - ゼロ月数加算")
    func addingMonths_zero() {
        let date = createDate(year: 2025, month: 6, day: 15)
        let result = date.adding(months: 0)

        #expect(result.get(.month) == 6)
    }

    @Test("境界値 - 12ヶ月加算は1年後")
    func addingMonths_twelve() {
        let date = createDate(year: 2025, month: 6, day: 15)
        let result = date.adding(months: 12)

        #expect(result.get(.year) == 2026)
        #expect(result.get(.month) == 6)
    }

    @Test("境界値 - ゼロ年数加算")
    func addingYears_zero() {
        let date = createDate(year: 2025, month: 6, day: 15)
        let result = date.adding(years: 0)

        #expect(result.get(.year) == 2025)
    }

    // MARK: - 異常系テスト

    @Test("異常系 - 非常に遠い過去の日付")
    func extremeCase_veryOldDate() {
        let date = createDate(year: 1900, month: 1, day: 1)

        #expect(date.get(.year) == 1900)
        #expect(date.startOfMonth.get(.day) == 1)
    }

    @Test("異常系 - 非常に遠い未来の日付")
    func extremeCase_veryFutureDate() {
        let date = createDate(year: 3000, month: 12, day: 31)

        #expect(date.get(.year) == 3000)
        #expect(date.endOfMonth.get(.day) == 31)
    }
}
