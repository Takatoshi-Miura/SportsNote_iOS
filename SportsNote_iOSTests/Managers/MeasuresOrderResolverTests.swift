//
//  MeasuresOrderResolverTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2026/08/04.
//

import Foundation
import Testing

@testable import SportsNote_iOS

/// `MeasuresOrderResolver`は Realm/UserDefaults/NotificationCenter/シングルトンのいずれにも
/// 依存しない純粋関数のため、`.serialized`は不要（issue #71）
@Suite("MeasuresOrderResolver Tests")
struct MeasuresOrderResolverTests {

    @Test("measuresPriorityと一致するタイトルが先頭(order=0相当)に配置される")
    func resolveOrder_priorityMatches_placesPriorityFirst() {
        let result = MeasuresOrderResolver.resolveOrder(
            measuresTitles: ["B対策", "A対策", "C対策"],
            measuresPriority: "C対策"
        )
        #expect(result == ["C対策", "A対策", "B対策"])
    }

    @Test("measuresPriorityがnilの場合はsorted()順になる")
    func resolveOrder_priorityNil_fallsBackToSorted() {
        let result = MeasuresOrderResolver.resolveOrder(
            measuresTitles: ["B対策", "A対策"],
            measuresPriority: nil
        )
        #expect(result == ["A対策", "B対策"])
    }

    @Test("measuresPriorityが一致しない場合もsorted()にフォールバックする")
    func resolveOrder_priorityNotFound_fallsBackToSorted() {
        let result = MeasuresOrderResolver.resolveOrder(
            measuresTitles: ["B対策", "A対策"],
            measuresPriority: "存在しない対策"
        )
        #expect(result == ["A対策", "B対策"])
    }

    @Test("measuresTitlesが空の場合は空配列を返す")
    func resolveOrder_emptyTitles_returnsEmpty() {
        let result = MeasuresOrderResolver.resolveOrder(measuresTitles: [], measuresPriority: "何か")
        #expect(result.isEmpty)
    }

    @Test("measuresTitlesが1件のみでmeasuresPriorityと一致する場合はその1件を返す")
    func resolveOrder_singleTitleMatchesPriority_returnsSingleTitle() {
        let result = MeasuresOrderResolver.resolveOrder(
            measuresTitles: ["唯一の対策"],
            measuresPriority: "唯一の対策"
        )
        #expect(result == ["唯一の対策"])
    }

    @Test(
        "入力の並び順（Dictionary列挙順を模した順序）に関わらず結果が一定になる",
        arguments: [
            ["A対策", "B対策", "C対策"],
            ["C対策", "A対策", "B対策"],
            ["B対策", "C対策", "A対策"],
        ]
    )
    func resolveOrder_inputOrderVaries_resultIsDeterministic(shuffledTitles: [String]) {
        let result = MeasuresOrderResolver.resolveOrder(
            measuresTitles: shuffledTitles,
            measuresPriority: "C対策"
        )
        #expect(result == ["C対策", "A対策", "B対策"])
    }

    @Test("旧データ実例に近い日本語タイトルでもsorted()フォールバックが決定的に機能する")
    func resolveOrder_realisticJapaneseTitles_fallsBackDeterministically() {
        let titles = [
            "[旧データ] 反応ドリルを毎日5分",
            "[旧データ] 毎日100本トスの練習",
        ]
        let result = MeasuresOrderResolver.resolveOrder(
            measuresTitles: titles,
            measuresPriority: "[旧データ] 毎日100本トスの練習"
        )
        #expect(result == ["[旧データ] 毎日100本トスの練習", "[旧データ] 反応ドリルを毎日5分"])
    }
}
