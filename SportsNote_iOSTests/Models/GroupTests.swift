//
//  GroupTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2026/07/29.
//

import Foundation
import Testing

@testable import SportsNote_iOS

@Suite("Group Model Tests")
struct GroupTests {

    // MARK: - groupColor テスト（issue #43: 範囲外colorでのクラッシュ防止）

    @Test(
        "groupColor - 正常範囲(0-7)では対応するGroupColorを返す",
        arguments: GroupColor.allCases)
    func groupColor_returnsCorrectColorForValidRange(color: GroupColor) {
        let group = Group(
            groupID: "g1", title: "Test", color: color.rawValue, order: 0, created_at: Date())

        #expect(group.groupColor == color)
    }

    @Test(
        "groupColor - 範囲外の値ではクラッシュせずgrayを返す",
        arguments: [-1, 8, 99, Int.max, Int.min])
    func groupColor_returnsGrayForOutOfRangeValue(invalidColor: Int) {
        let group = Group(
            groupID: "g1", title: "Test", color: invalidColor, order: 0, created_at: Date())

        #expect(group.groupColor == .gray)
    }
}
