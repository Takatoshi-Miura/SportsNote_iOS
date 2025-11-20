//
//  UUIDGeneratorTests.swift
//  SportsNote_iOSTests
//
//  Created by Claude on 2025/11/17.
//

import Foundation
import Testing

@testable import SportsNote_iOS

@Suite("UUIDGenerator Tests")
struct UUIDGeneratorTests {

    // MARK: - generateID() 正常系テスト

    @Test("UUID生成 - 有効なUUID形式を返す")
    func generateID_returnsValidUUID() {
        let id = UUIDGenerator.generateID()
        #expect(UUID(uuidString: id) != nil)
    }

    @Test("UUID生成 - 36文字の文字列を返す")
    func generateID_returnsCorrectLength() {
        let id = UUIDGenerator.generateID()
        #expect(id.count == 36)
    }

    @Test("UUID生成 - ハイフン区切りの形式")
    func generateID_hasCorrectFormat() {
        let id = UUIDGenerator.generateID()
        let components = id.split(separator: "-")
        #expect(components.count == 5)
        #expect(components[0].count == 8)
        #expect(components[1].count == 4)
        #expect(components[2].count == 4)
        #expect(components[3].count == 4)
        #expect(components[4].count == 12)
    }

    @Test("UUID生成 - 毎回異なるIDを生成")
    func generateID_generatesUniqueIDs() {
        let id1 = UUIDGenerator.generateID()
        let id2 = UUIDGenerator.generateID()
        let id3 = UUIDGenerator.generateID()

        #expect(id1 != id2)
        #expect(id2 != id3)
        #expect(id1 != id3)
    }

    @Test("UUID生成 - 大量生成でもユニーク")
    func generateID_massGenerationUnique() {
        var ids = Set<String>()
        let count = 1000

        for _ in 0..<count {
            ids.insert(UUIDGenerator.generateID())
        }

        #expect(ids.count == count)
    }

    @Test("UUID生成 - 有効な16進数文字のみ含む")
    func generateID_containsOnlyValidCharacters() {
        let id = UUIDGenerator.generateID()
        let validCharacters = CharacterSet(charactersIn: "0123456789ABCDEFabcdef-")
        let idCharacterSet = CharacterSet(charactersIn: id)

        #expect(validCharacters.isSuperset(of: idCharacterSet))
    }

    // MARK: - generateID(withPrefix:) 正常系テスト

    @Test("プレフィックス付きID - 基本的な生成")
    func generateIDWithPrefix_basicGeneration() {
        let id = UUIDGenerator.generateID(withPrefix: "test")
        #expect(id.hasPrefix("test_"))
    }

    @Test("プレフィックス付きID - UUIDを含む")
    func generateIDWithPrefix_containsUUID() {
        let id = UUIDGenerator.generateID(withPrefix: "test")
        let uuidPart = String(id.dropFirst("test_".count))
        #expect(UUID(uuidString: uuidPart) != nil)
    }

    @Test("プレフィックス付きID - 正しい長さ")
    func generateIDWithPrefix_correctLength() {
        let prefix = "myprefix"
        let id = UUIDGenerator.generateID(withPrefix: prefix)
        // prefix + "_" + UUID(36文字)
        let expectedLength = prefix.count + 1 + 36
        #expect(id.count == expectedLength)
    }

    @Test("プレフィックス付きID - ユニーク性")
    func generateIDWithPrefix_unique() {
        let id1 = UUIDGenerator.generateID(withPrefix: "test")
        let id2 = UUIDGenerator.generateID(withPrefix: "test")

        #expect(id1 != id2)
    }

    @Test("プレフィックス付きID - 異なるプレフィックス")
    func generateIDWithPrefix_differentPrefixes() {
        let id1 = UUIDGenerator.generateID(withPrefix: "user")
        let id2 = UUIDGenerator.generateID(withPrefix: "task")

        #expect(id1.hasPrefix("user_"))
        #expect(id2.hasPrefix("task_"))
    }

    // MARK: - generateID(withPrefix:) 境界値テスト

    @Test("プレフィックス付きID - 空のプレフィックス")
    func generateIDWithPrefix_emptyPrefix() {
        let id = UUIDGenerator.generateID(withPrefix: "")
        #expect(id.hasPrefix("_"))
        let uuidPart = String(id.dropFirst(1))
        #expect(UUID(uuidString: uuidPart) != nil)
    }

    @Test("プレフィックス付きID - 単一文字プレフィックス")
    func generateIDWithPrefix_singleCharacter() {
        let id = UUIDGenerator.generateID(withPrefix: "a")
        #expect(id.hasPrefix("a_"))
        #expect(id.count == 38)  // 1 + 1 + 36
    }

    @Test("プレフィックス付きID - 長いプレフィックス")
    func generateIDWithPrefix_longPrefix() {
        let longPrefix = String(repeating: "x", count: 100)
        let id = UUIDGenerator.generateID(withPrefix: longPrefix)
        #expect(id.hasPrefix(longPrefix + "_"))
        #expect(id.count == 100 + 1 + 36)
    }

    @Test("プレフィックス付きID - 特殊文字を含むプレフィックス")
    func generateIDWithPrefix_specialCharacters() {
        let id = UUIDGenerator.generateID(withPrefix: "test-user_123")
        #expect(id.hasPrefix("test-user_123_"))
    }

    @Test("プレフィックス付きID - 数字のみのプレフィックス")
    func generateIDWithPrefix_numericPrefix() {
        let id = UUIDGenerator.generateID(withPrefix: "12345")
        #expect(id.hasPrefix("12345_"))
    }

    @Test("プレフィックス付きID - 日本語プレフィックス")
    func generateIDWithPrefix_japaneseCharacters() {
        let id = UUIDGenerator.generateID(withPrefix: "テスト")
        #expect(id.hasPrefix("テスト_"))
    }

    // MARK: - generateCompactID() 正常系テスト

    @Test("コンパクトID - ハイフンなし")
    func generateCompactID_noHyphens() {
        let id = UUIDGenerator.generateCompactID()
        #expect(!id.contains("-"))
    }

    @Test("コンパクトID - 32文字")
    func generateCompactID_correctLength() {
        let id = UUIDGenerator.generateCompactID()
        #expect(id.count == 32)
    }

    @Test("コンパクトID - 有効な16進数文字のみ")
    func generateCompactID_onlyHexCharacters() {
        let id = UUIDGenerator.generateCompactID()
        let validCharacters = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        let idCharacterSet = CharacterSet(charactersIn: id)

        #expect(validCharacters.isSuperset(of: idCharacterSet))
    }

    @Test("コンパクトID - ユニーク性")
    func generateCompactID_unique() {
        let id1 = UUIDGenerator.generateCompactID()
        let id2 = UUIDGenerator.generateCompactID()

        #expect(id1 != id2)
    }

    @Test("コンパクトID - 大量生成でもユニーク")
    func generateCompactID_massGenerationUnique() {
        var ids = Set<String>()
        let count = 1000

        for _ in 0..<count {
            ids.insert(UUIDGenerator.generateCompactID())
        }

        #expect(ids.count == count)
    }

    // MARK: - isValidUUID() 正常系テスト

    @Test("UUID検証 - 有効なUUID")
    func isValidUUID_validUUID() {
        let validID = "123e4567-e89b-12d3-a456-426614174000"
        #expect(UUIDGenerator.isValidUUID(validID))
    }

    @Test("UUID検証 - 生成したUUID")
    func isValidUUID_generatedUUID() {
        let id = UUIDGenerator.generateID()
        #expect(UUIDGenerator.isValidUUID(id))
    }

    @Test("UUID検証 - 小文字UUID")
    func isValidUUID_lowercaseUUID() {
        let id = "123e4567-e89b-12d3-a456-426614174000"
        #expect(UUIDGenerator.isValidUUID(id))
    }

    @Test("UUID検証 - 大文字UUID")
    func isValidUUID_uppercaseUUID() {
        let id = "123E4567-E89B-12D3-A456-426614174000"
        #expect(UUIDGenerator.isValidUUID(id))
    }

    @Test("UUID検証 - 混合ケースUUID")
    func isValidUUID_mixedCaseUUID() {
        let id = "123e4567-E89B-12d3-A456-426614174000"
        #expect(UUIDGenerator.isValidUUID(id))
    }

    // MARK: - isValidUUID() 異常系テスト

    @Test("UUID検証 - 無効な形式")
    func isValidUUID_invalidFormat() {
        let invalidID = "invalid-id"
        #expect(!UUIDGenerator.isValidUUID(invalidID))
    }

    @Test("UUID検証 - 空文字列")
    func isValidUUID_emptyString() {
        #expect(!UUIDGenerator.isValidUUID(""))
    }

    @Test("UUID検証 - ハイフンなし（短すぎる）")
    func isValidUUID_noHyphensShort() {
        let id = "123e4567e89b12d3a456426614174000"
        #expect(!UUIDGenerator.isValidUUID(id))
    }

    @Test("UUID検証 - ハイフン位置が不正")
    func isValidUUID_wrongHyphenPosition() {
        let id = "123e-4567-e89b-12d3-a456426614174000"
        #expect(!UUIDGenerator.isValidUUID(id))
    }

    @Test("UUID検証 - 文字数が足りない")
    func isValidUUID_tooShort() {
        let id = "123e4567-e89b-12d3-a456-42661417400"  // 1文字足りない
        #expect(!UUIDGenerator.isValidUUID(id))
    }

    @Test("UUID検証 - 文字数が多すぎる")
    func isValidUUID_tooLong() {
        let id = "123e4567-e89b-12d3-a456-4266141740000"  // 1文字多い
        #expect(!UUIDGenerator.isValidUUID(id))
    }

    @Test("UUID検証 - 無効な文字を含む")
    func isValidUUID_invalidCharacters() {
        let id = "123g4567-e89b-12d3-a456-426614174000"  // 'g'は無効
        #expect(!UUIDGenerator.isValidUUID(id))
    }

    @Test("UUID検証 - スペースを含む")
    func isValidUUID_containsSpaces() {
        let id = "123e4567-e89b-12d3-a456-426614174000 "
        #expect(!UUIDGenerator.isValidUUID(id))
    }

    @Test("UUID検証 - 先頭にスペース")
    func isValidUUID_leadingSpace() {
        let id = " 123e4567-e89b-12d3-a456-426614174000"
        #expect(!UUIDGenerator.isValidUUID(id))
    }

    @Test("UUID検証 - プレフィックス付きID")
    func isValidUUID_prefixedID() {
        let id = UUIDGenerator.generateID(withPrefix: "test")
        #expect(!UUIDGenerator.isValidUUID(id))
    }

    @Test("UUID検証 - コンパクトID")
    func isValidUUID_compactID() {
        let id = UUIDGenerator.generateCompactID()
        #expect(!UUIDGenerator.isValidUUID(id))
    }

    @Test("UUID検証 - nil UUID文字列")
    func isValidUUID_nilUUIDString() {
        let id = "00000000-0000-0000-0000-000000000000"
        #expect(UUIDGenerator.isValidUUID(id))
    }

    // MARK: - 境界値・特殊ケーステスト

    @Test("境界値 - すべてゼロのUUID")
    func boundaryCase_allZerosUUID() {
        let id = "00000000-0000-0000-0000-000000000000"
        #expect(UUIDGenerator.isValidUUID(id))
    }

    @Test("境界値 - すべてFのUUID")
    func boundaryCase_allFsUUID() {
        let id = "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"
        #expect(UUIDGenerator.isValidUUID(id))
    }

    @Test("特殊ケース - 改行を含む")
    func specialCase_containsNewline() {
        let id = "123e4567-e89b-12d3-a456-426614174000\n"
        #expect(!UUIDGenerator.isValidUUID(id))
    }

    @Test("特殊ケース - タブを含む")
    func specialCase_containsTab() {
        let id = "123e4567-e89b-12d3-a456-426614174000\t"
        #expect(!UUIDGenerator.isValidUUID(id))
    }
}
