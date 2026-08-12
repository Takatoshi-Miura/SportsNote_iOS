//
//  MigrationMemoMergerTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2026/08/11.
//

import Foundation
import Testing

@testable import SportsNote_iOS

/// `MigrationMemoMerger`は Realm/UserDefaults/NotificationCenter/シングルトンのいずれにも
/// 依存しない純粋関数のため、`.serialized`は不要（issue #184、`MeasuresOrderResolverTests`と同方針）
@Suite("MigrationMemoMerger Tests")
struct MigrationMemoMergerTests {

    @Test("同一課題内で異なる対策のコメントが同じ旧noteIDを指す場合、1件のMemoにマージされる（issue #184の再現シナリオ）")
    func merge_sameOldNoteIDAcrossDifferentMeasures_mergesIntoSingleMemo() {
        // 旧アプリで「対策A」「対策B」の両方に、同じ練習ノート(旧noteID=100)への
        // 効果コメントが記録されていたケース（対策単位でコメントを持つ旧データモデル特有の状況）
        let effectivenessByMeasures = [
            MigrationMemoMerger.MeasuresEffectiveness(
                measuresID: "measures-a", comments: [(comment: "対策Aのコメント", oldNoteID: 100)]),
            MigrationMemoMerger.MeasuresEffectiveness(
                measuresID: "measures-b", comments: [(comment: "対策Bのコメント", oldNoteID: 100)]),
        ]

        let result = MigrationMemoMerger.merge(effectivenessByMeasures: effectivenessByMeasures)

        // 素直に変換すると同一noteID・異なるmeasuresIDのMemoが2件生成され、
        // associateTasksWithMemosのtaskIDキー辞書で片方が上書きされ画面から消えてしまう。
        // マージ後は1件のみになり、本文は両方のコメントを保持する
        #expect(result.count == 1)
        #expect(result.first?.noteID == "100")
        #expect(result.first?.measuresID == "measures-a")  // 先に処理された（＝優先度の高い）対策のIDを維持
        #expect(result.first?.detail == "対策Aのコメント\n対策Bのコメント")
    }

    @Test("異なる旧noteIDの場合はマージされず、別々のMemoとして生成される")
    func merge_differentOldNoteIDs_doesNotMerge() {
        let effectivenessByMeasures = [
            MigrationMemoMerger.MeasuresEffectiveness(
                measuresID: "measures-a", comments: [(comment: "1回目の練習", oldNoteID: 100)]),
            MigrationMemoMerger.MeasuresEffectiveness(
                measuresID: "measures-b", comments: [(comment: "2回目の練習", oldNoteID: 200)]),
        ]

        let result = MigrationMemoMerger.merge(effectivenessByMeasures: effectivenessByMeasures)

        #expect(result.count == 2)
        #expect(result[0].noteID == "100")
        #expect(result[0].measuresID == "measures-a")
        #expect(result[0].detail == "1回目の練習")
        #expect(result[1].noteID == "200")
        #expect(result[1].measuresID == "measures-b")
        #expect(result[1].detail == "2回目の練習")
    }

    @Test("同一対策・同一ノートに複数コメントがある場合もマージされる")
    func merge_sameMeasuresSameNoteMultipleComments_merges() {
        let effectivenessByMeasures = [
            MigrationMemoMerger.MeasuresEffectiveness(
                measuresID: "measures-a",
                comments: [(comment: "コメント1", oldNoteID: 100), (comment: "コメント2", oldNoteID: 100)])
        ]

        let result = MigrationMemoMerger.merge(effectivenessByMeasures: effectivenessByMeasures)

        #expect(result.count == 1)
        #expect(result.first?.detail == "コメント1\nコメント2")
    }

    @Test("空文字のコメントは除外される")
    func merge_emptyComment_isExcluded() {
        let effectivenessByMeasures = [
            MigrationMemoMerger.MeasuresEffectiveness(
                measuresID: "measures-a", comments: [(comment: "", oldNoteID: 100)])
        ]

        let result = MigrationMemoMerger.merge(effectivenessByMeasures: effectivenessByMeasures)

        #expect(result.isEmpty)
    }

    @Test("oldNoteIDが0の場合は空文字のnoteIDに変換される（フリーノート等、旧仕様のnoteID=0を踏襲）")
    func merge_oldNoteIDZero_convertsToEmptyStringNoteID() {
        let effectivenessByMeasures = [
            MigrationMemoMerger.MeasuresEffectiveness(
                measuresID: "measures-a", comments: [(comment: "コメント", oldNoteID: 0)])
        ]

        let result = MigrationMemoMerger.merge(effectivenessByMeasures: effectivenessByMeasures)

        #expect(result.count == 1)
        #expect(result.first?.noteID == "")
    }

    @Test(
        "oldNoteIDが0（ノート未紐付け）のコメントは、異なる対策間でマージされず個別のMemoのまま生成される（クロスレビュー指摘の回帰防止）"
    )
    func merge_oldNoteIDZero_acrossDifferentMeasures_doesNotMerge() {
        // noteID=""のコメントはMemoViewModel.getMemosByMeasuresIDにより対策ごとに独立して
        // 一覧表示される前提のため、実ノートへのコメントとは異なりマージしてはいけない。
        // マージしてしまうと対策Bの「継続できている」が対策Aの「調子が良い」に統合され、
        // 対策B側の詳細画面からコメントが消えてしまう
        let effectivenessByMeasures = [
            MigrationMemoMerger.MeasuresEffectiveness(
                measuresID: "measures-a", comments: [(comment: "調子が良い", oldNoteID: 0)]),
            MigrationMemoMerger.MeasuresEffectiveness(
                measuresID: "measures-b", comments: [(comment: "継続できている", oldNoteID: 0)]),
        ]

        let result = MigrationMemoMerger.merge(effectivenessByMeasures: effectivenessByMeasures)

        #expect(result.count == 2)
        #expect(result[0].measuresID == "measures-a")
        #expect(result[0].noteID == "")
        #expect(result[0].detail == "調子が良い")
        #expect(result[1].measuresID == "measures-b")
        #expect(result[1].noteID == "")
        #expect(result[1].detail == "継続できている")
    }

    @Test("oldNoteIDが0の複数コメントと実ノートへのコメントが混在していても、実ノート分のみマージされる")
    func merge_mixedFreeformAndRealNoteComments_onlyMergesRealNoteComments() {
        let effectivenessByMeasures = [
            MigrationMemoMerger.MeasuresEffectiveness(
                measuresID: "measures-a",
                comments: [(comment: "未紐付けA", oldNoteID: 0), (comment: "ノート100へのA", oldNoteID: 100)]),
            MigrationMemoMerger.MeasuresEffectiveness(
                measuresID: "measures-b",
                comments: [(comment: "未紐付けB", oldNoteID: 0), (comment: "ノート100へのB", oldNoteID: 100)]),
        ]

        let result = MigrationMemoMerger.merge(effectivenessByMeasures: effectivenessByMeasures)

        // 未紐付け2件（マージされない）+ ノート100宛て1件（マージされる）= 計3件
        #expect(result.count == 3)
        #expect(result.filter { $0.noteID == "" }.count == 2)
        let merged = result.first { $0.noteID == "100" }
        #expect(merged?.measuresID == "measures-a")
        #expect(merged?.detail == "ノート100へのA\nノート100へのB")
    }

    @Test("入力が空配列の場合は空配列を返す")
    func merge_emptyInput_returnsEmpty() {
        let result = MigrationMemoMerger.merge(effectivenessByMeasures: [])
        #expect(result.isEmpty)
    }

    @Test("戻り値の順序はnoteIDが最初に出現した順（決定的な順序）になる")
    func merge_resultOrder_matchesFirstOccurrenceOrder() {
        let effectivenessByMeasures = [
            MigrationMemoMerger.MeasuresEffectiveness(
                measuresID: "measures-a",
                comments: [(comment: "3回目", oldNoteID: 300), (comment: "1回目", oldNoteID: 100)]),
            MigrationMemoMerger.MeasuresEffectiveness(
                measuresID: "measures-b", comments: [(comment: "2回目", oldNoteID: 200)]),
        ]

        let result = MigrationMemoMerger.merge(effectivenessByMeasures: effectivenessByMeasures)

        #expect(result.map { $0.noteID } == ["300", "100", "200"])
    }
}
