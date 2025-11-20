//
//  JapaneseHolidayCheckerTests.swift
//  SportsNote_iOSTests
//
//  Created by Claude on 2025/11/17.
//

import Foundation
import Testing

@testable import SportsNote_iOS

@Suite("JapaneseHolidayChecker Tests")
struct JapaneseHolidayCheckerTests {

    // MARK: - Helper Methods

    /// テスト用の特定日付を生成
    private func createDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    // MARK: - 固定祝日テスト（正常系）

    @Test("固定祝日 - 元日（1月1日）")
    func fixedHoliday_newYearsDay() {
        let date = createDate(year: 2025, month: 1, day: 1)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("固定祝日 - 建国記念の日（2月11日）")
    func fixedHoliday_foundationDay() {
        let date = createDate(year: 2025, month: 2, day: 11)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("固定祝日 - 天皇誕生日（2月23日）")
    func fixedHoliday_emperorsBirthday() {
        let date = createDate(year: 2025, month: 2, day: 23)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("固定祝日 - 昭和の日（4月29日）")
    func fixedHoliday_showaDay() {
        let date = createDate(year: 2025, month: 4, day: 29)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("固定祝日 - 憲法記念日（5月3日）")
    func fixedHoliday_constitutionDay() {
        let date = createDate(year: 2025, month: 5, day: 3)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("固定祝日 - みどりの日（5月4日）")
    func fixedHoliday_greeneryDay() {
        let date = createDate(year: 2025, month: 5, day: 4)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("固定祝日 - こどもの日（5月5日）")
    func fixedHoliday_childrensDay() {
        let date = createDate(year: 2025, month: 5, day: 5)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("固定祝日 - 山の日（8月11日）")
    func fixedHoliday_mountainDay() {
        let date = createDate(year: 2025, month: 8, day: 11)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("固定祝日 - 文化の日（11月3日）")
    func fixedHoliday_cultureDay() {
        let date = createDate(year: 2025, month: 11, day: 3)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("固定祝日 - 勤労感謝の日（11月23日）")
    func fixedHoliday_laborThanksgivingDay() {
        let date = createDate(year: 2025, month: 11, day: 23)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    // MARK: - ハッピーマンデー祝日テスト

    @Test("ハッピーマンデー - 成人の日（1月第2月曜日）2025年")
    func happyMonday_comingOfAgeDay_2025() {
        let date = createDate(year: 2025, month: 1, day: 13)  // 2025年1月13日は第2月曜日
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("ハッピーマンデー - 海の日（7月第3月曜日）2025年")
    func happyMonday_marineDay_2025() {
        let date = createDate(year: 2025, month: 7, day: 21)  // 2025年7月21日は第3月曜日
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("ハッピーマンデー - 敬老の日（9月第3月曜日）2025年")
    func happyMonday_respectForTheAgedDay_2025() {
        let date = createDate(year: 2025, month: 9, day: 15)  // 2025年9月15日は第3月曜日
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("ハッピーマンデー - スポーツの日（10月第2月曜日）2025年")
    func happyMonday_sportsDay_2025() {
        let date = createDate(year: 2025, month: 10, day: 13)  // 2025年10月13日は第2月曜日
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("ハッピーマンデー - 成人の日 2024年")
    func happyMonday_comingOfAgeDay_2024() {
        let date = createDate(year: 2024, month: 1, day: 8)  // 2024年1月8日は第2月曜日
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("ハッピーマンデー - 海の日 2024年")
    func happyMonday_marineDay_2024() {
        let date = createDate(year: 2024, month: 7, day: 15)  // 2024年7月15日は第3月曜日
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    // MARK: - 春分の日・秋分の日テスト

    @Test("春分の日 - 2025年（3月20日）")
    func equinoxDay_spring_2025() {
        let date = createDate(year: 2025, month: 3, day: 20)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("春分の日 - 2024年（3月20日）")
    func equinoxDay_spring_2024() {
        let date = createDate(year: 2024, month: 3, day: 20)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("秋分の日 - 2025年（9月23日）")
    func equinoxDay_autumn_2025() {
        let date = createDate(year: 2025, month: 9, day: 23)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("秋分の日 - 2024年（9月22日）")
    func equinoxDay_autumn_2024() {
        let date = createDate(year: 2024, month: 9, day: 22)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("春分の日 - 2020年（3月20日）")
    func equinoxDay_spring_2020() {
        let date = createDate(year: 2020, month: 3, day: 20)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    // MARK: - 振替休日テスト

    @Test("振替休日 - 2025年2月24日（天皇誕生日の振替）")
    func substituteHoliday_emperorsBirthday_2025() {
        // 2025年2月23日（天皇誕生日）は日曜日
        // 2025年2月24日（月曜日）が振替休日
        let date = createDate(year: 2025, month: 2, day: 24)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("振替休日 - 2025年5月6日（こどもの日の振替）")
    func substituteHoliday_childrensDay_2025() {
        // 2025年5月5日（こどもの日）は月曜日なので振替休日なし
        // 代わりに2025年11月24日をチェック（勤労感謝の日の振替）
        let date = createDate(year: 2025, month: 11, day: 24)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("振替休日 - 2024年8月12日（山の日の振替）")
    func substituteHoliday_mountainDay_2024() {
        // 2024年8月11日（山の日）は日曜日
        // 2024年8月12日（月曜日）が振替休日
        let date = createDate(year: 2024, month: 8, day: 12)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("振替休日 - 2024年11月4日（文化の日の振替）")
    func substituteHoliday_cultureDay_2024() {
        // 2024年11月3日（文化の日）は日曜日
        // 2024年11月4日（月曜日）が振替休日
        let date = createDate(year: 2024, month: 11, day: 4)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    // MARK: - 異常系テスト（祝日ではない日）

    @Test("非祝日 - 通常の平日")
    func notHoliday_normalWeekday() {
        let date = createDate(year: 2025, month: 6, day: 10)  // 火曜日
        #expect(!JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("非祝日 - 通常の週末（土曜日）")
    func notHoliday_saturday() {
        let date = createDate(year: 2025, month: 6, day: 14)  // 土曜日
        #expect(!JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("非祝日 - 通常の週末（日曜日）")
    func notHoliday_sunday() {
        let date = createDate(year: 2025, month: 6, day: 15)  // 日曜日
        #expect(!JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("非祝日 - 祝日の前日")
    func notHoliday_dayBeforeHoliday() {
        let date = createDate(year: 2025, month: 4, day: 28)  // 昭和の日の前日
        #expect(!JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("非祝日 - 祝日の翌日")
    func notHoliday_dayAfterHoliday() {
        let date = createDate(year: 2025, month: 5, day: 6)  // こどもの日の翌日
        #expect(!JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("非祝日 - 固定祝日の異なる月")
    func notHoliday_wrongMonth() {
        let date = createDate(year: 2025, month: 3, day: 11)  // 2月11日は祝日だが3月11日は違う
        #expect(!JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("非祝日 - ハッピーマンデーでない月曜日")
    func notHoliday_nonHappyMonday() {
        let date = createDate(year: 2025, month: 1, day: 6)  // 1月第1月曜日
        #expect(!JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("非祝日 - 月曜日でないが祝日と同じ週")
    func notHoliday_notMonday() {
        let date = createDate(year: 2025, month: 1, day: 14)  // 成人の日(13日)の翌日
        #expect(!JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    // MARK: - 境界値テスト

    @Test("境界値 - 年初（1月1日）")
    func boundary_startOfYear() {
        let date = createDate(year: 2025, month: 1, day: 1)
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("境界値 - 年末（12月31日）")
    func boundary_endOfYear() {
        let date = createDate(year: 2025, month: 12, day: 31)
        #expect(!JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("境界値 - うるう年の2月29日")
    func boundary_leapYearFeb29() {
        let date = createDate(year: 2024, month: 2, day: 29)
        #expect(!JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("境界値 - 月初（祝日でない月）")
    func boundary_startOfNonHolidayMonth() {
        let date = createDate(year: 2025, month: 6, day: 1)
        #expect(!JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("境界値 - 月末（祝日でない月）")
    func boundary_endOfNonHolidayMonth() {
        let date = createDate(year: 2025, month: 6, day: 30)
        #expect(!JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("境界値 - 過去の年（2000年）")
    func boundary_year2000() {
        let date = createDate(year: 2000, month: 1, day: 1)  // 元日
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("境界値 - 未来の年（2030年）")
    func boundary_year2030() {
        let date = createDate(year: 2030, month: 1, day: 1)  // 元日
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    // MARK: - ゴールデンウィーク連続テスト

    @Test("GW - 4月29日から5月5日の連続祝日")
    func goldenWeek_consecutiveHolidays() {
        let april29 = createDate(year: 2025, month: 4, day: 29)
        let may3 = createDate(year: 2025, month: 5, day: 3)
        let may4 = createDate(year: 2025, month: 5, day: 4)
        let may5 = createDate(year: 2025, month: 5, day: 5)

        #expect(JapaneseHolidayChecker.isJapaneseHoliday(april29))
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(may3))
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(may4))
        #expect(JapaneseHolidayChecker.isJapaneseHoliday(may5))
    }

    @Test("GW - 4月30日は祝日ではない")
    func goldenWeek_april30NotHoliday() {
        let date = createDate(year: 2025, month: 4, day: 30)
        #expect(!JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("GW - 5月1日は祝日ではない")
    func goldenWeek_may1NotHoliday() {
        let date = createDate(year: 2025, month: 5, day: 1)
        #expect(!JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    @Test("GW - 5月2日は祝日ではない")
    func goldenWeek_may2NotHoliday() {
        let date = createDate(year: 2025, month: 5, day: 2)
        #expect(!JapaneseHolidayChecker.isJapaneseHoliday(date))
    }

    // MARK: - 複数年にわたる一貫性テスト

    @Test("一貫性 - 元日は毎年1月1日")
    func consistency_newYearsDay() {
        for year in 2020...2030 {
            let date = createDate(year: year, month: 1, day: 1)
            #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
        }
    }

    @Test("一貫性 - 憲法記念日は毎年5月3日")
    func consistency_constitutionDay() {
        for year in 2020...2030 {
            let date = createDate(year: year, month: 5, day: 3)
            #expect(JapaneseHolidayChecker.isJapaneseHoliday(date))
        }
    }

    @Test("一貫性 - 12月25日は祝日ではない")
    func consistency_christmasNotHoliday() {
        for year in 2020...2030 {
            let date = createDate(year: year, month: 12, day: 25)
            #expect(!JapaneseHolidayChecker.isJapaneseHoliday(date))
        }
    }
}
