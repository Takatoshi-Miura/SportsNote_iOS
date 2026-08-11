//
//  StringExtensionsTests.swift
//  SportsNote_iOSTests
//
//  Created by Claude on 2026/08/11.
//

import Foundation
import Testing

@testable import SportsNote_iOS

@Suite("StringExtensions Tests")
struct StringExtensionsTests {

    // MARK: - isBlank Tests

    @Test(
        "isBlank - 空白のみ（またはブランク）の場合はtrue",
        arguments: [
            "",
            " ",
            "   ",
            "\n",
            "\t",
            " \n\t ",
            "　",  // 全角スペース
            "　　",  // 全角スペースのみ
        ]
    )
    func isBlank_blankInput_returnsTrue(input: String) {
        #expect(input.isBlank == true)
    }

    @Test(
        "isBlank - 非空白文字を含む場合はfalse",
        arguments: [
            "タイトル",
            "a",
            " タイトル ",
            "\nタイトル\n",
            "  a  ",
            "0",
        ]
    )
    func isBlank_nonBlankInput_returnsFalse(input: String) {
        #expect(input.isBlank == false)
    }
}
