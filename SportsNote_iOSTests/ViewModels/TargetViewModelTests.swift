//
//  TargetViewModelTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2025/11/23.
//

import Foundation
import RealmSwift
import Testing

@testable import SportsNote_iOS

@Suite("TargetViewModel Tests", .serialized)
@MainActor
struct TargetViewModelTests {

    init() async throws {
        RealmManager.shared.setupInMemoryRealm()
    }

    // MARK: - 初期化テスト

    @Test("初期化 - プロパティが正しく初期化される")
    func initialization_propertiesAreInitializedCorrectly() async {
        let viewModel = TargetViewModel()

        #expect(viewModel.yearlyTargets.isEmpty)
        #expect(viewModel.monthlyTargets.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.currentError == nil)
        #expect(viewModel.showingErrorAlert == false)
    }

    // MARK: - プロパティテスト

    @Test("プロパティ - yearlyTargetsの設定と取得")
    func property_yearlyTargetsSetAndGet() async {
        let viewModel = TargetViewModel()

        let testTarget = Target(
            title: "年間目標",
            year: 2024,
            month: 1,
            isYearlyTarget: true
        )

        viewModel.yearlyTargets = [testTarget]

        #expect(viewModel.yearlyTargets.count == 1)
        #expect(viewModel.yearlyTargets[0].title == "年間目標")
        #expect(viewModel.yearlyTargets[0].isYearlyTarget == true)
    }

    @Test("プロパティ - monthlyTargetsの設定と取得")
    func property_monthlyTargetsSetAndGet() async {
        let viewModel = TargetViewModel()

        let testTarget = Target(
            title: "月間目標",
            year: 2024,
            month: 11,
            isYearlyTarget: false
        )

        viewModel.monthlyTargets = [testTarget]

        #expect(viewModel.monthlyTargets.count == 1)
        #expect(viewModel.monthlyTargets[0].title == "月間目標")
        #expect(viewModel.monthlyTargets[0].isYearlyTarget == false)
    }

    // MARK: - 年月テスト

    @Test("年月 - 様々な年", arguments: [2020, 2021, 2024, 2025, 2030])
    func yearMonth_variousYears(year: Int) async {
        let target = Target(
            title: "Test",
            year: year,
            month: 1,
            isYearlyTarget: false
        )

        #expect(target.year == year)
    }

    @Test("年月 - 様々な月", arguments: Array(1...12))
    func yearMonth_variousMonths(month: Int) async {
        let target = Target(
            title: "Test",
            year: 2024,
            month: month,
            isYearlyTarget: false
        )

        #expect(target.month == month)
    }

    @Test("年月 - 境界値の月", arguments: [0, 1, 12, 13])
    func yearMonth_boundaryMonths(month: Int) async {
        let target = Target(
            title: "Test",
            year: 2024,
            month: month,
            isYearlyTarget: false
        )

        #expect(target.month == month)
    }

    // MARK: - isYearlyTarget フラグテスト

    @Test("isYearlyTarget - trueの場合")
    func isYearlyTarget_true() async {
        let target = Target(
            title: "年間目標",
            year: 2024,
            month: 1,
            isYearlyTarget: true
        )

        #expect(target.isYearlyTarget == true)
    }

    @Test("isYearlyTarget - falseの場合")
    func isYearlyTarget_false() async {
        let target = Target(
            title: "月間目標",
            year: 2024,
            month: 11,
            isYearlyTarget: false
        )

        #expect(target.isYearlyTarget == false)
    }

    @Test("isYearlyTarget - デフォルト値はfalse")
    func isYearlyTarget_defaultIsFalse() async {
        let target = Target(
            title: "Test",
            year: 2024,
            month: 1
        )

        #expect(target.isYearlyTarget == false)
    }

    // MARK: - 通知処理テスト

    @Test("通知処理 - didClearAllData通知でクリアされる")
    func notification_clearsOnDidClearAllData() async {
        let viewModel = TargetViewModel()

        // データを追加
        let yearlyTarget = Target(title: "年間", year: 2024, month: 1, isYearlyTarget: true)
        let monthlyTarget = Target(title: "月間", year: 2024, month: 11, isYearlyTarget: false)

        viewModel.yearlyTargets = [yearlyTarget]
        viewModel.monthlyTargets = [monthlyTarget]

        #expect(!viewModel.yearlyTargets.isEmpty)
        #expect(!viewModel.monthlyTargets.isEmpty)

        // 通知を送信
        NotificationCenter.default.post(name: .didClearAllData, object: nil)

        // 非同期処理を待つ
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

        #expect(viewModel.yearlyTargets.isEmpty)
        #expect(viewModel.monthlyTargets.isEmpty)
    }

    // MARK: - 境界値テスト

    @Test("境界値 - 空のタイトル")
    func boundaryCase_emptyTitle() async {
        let target = Target(
            title: "",
            year: 2024,
            month: 1,
            isYearlyTarget: false
        )

        #expect(target.title == "")
    }

    @Test("境界値 - 非常に長いタイトル")
    func boundaryCase_veryLongTitle() async {
        let longTitle = String(repeating: "目標", count: 500)
        let target = Target(
            title: longTitle,
            year: 2024,
            month: 1,
            isYearlyTarget: false
        )

        #expect(target.title == longTitle)
        #expect(target.title.count == 1000)
    }

    @Test(
        "境界値 - 特殊文字を含むタイトル",
        arguments: [
            "目標🎾",
            "Target\nWith\nNewlines",
            "Target & Special <> Characters",
        ])
    func boundaryCase_specialCharactersInTitle(title: String) async {
        let target = Target(
            title: title,
            year: 2024,
            month: 1,
            isYearlyTarget: false
        )

        #expect(target.title == title)
    }

    @Test("境界値 - 大量の目標", arguments: [10, 50, 100])
    func boundaryCase_largeTargetsList(count: Int) async {
        let viewModel = TargetViewModel()

        var targets: [Target] = []
        for i in 0..<count {
            let target = Target(
                title: "Target \(i)",
                year: 2024,
                month: 1,
                isYearlyTarget: false
            )
            targets.append(target)
        }

        viewModel.monthlyTargets = targets

        #expect(viewModel.monthlyTargets.count == count)
    }

    // MARK: - 年月の組み合わせテスト

    @Test(
        "年月の組み合わせ - 様々な年月",
        arguments: zip([2024, 2024, 2025, 2025], [1, 12, 6, 11]))
    func yearMonthCombination_variousCombinations(year: Int, month: Int) async {
        let target = Target(
            title: "Test",
            year: year,
            month: month,
            isYearlyTarget: false
        )

        #expect(target.year == year)
        #expect(target.month == month)
    }

    // MARK: - Target作成テスト

    @Test("Target作成 - デフォルトイニシャライザ")
    func targetCreation_defaultInitializer() async {
        let target = Target()

        #expect(!target.targetID.isEmpty)
        #expect(target.title == "")
        #expect(target.year == 2020)
        #expect(target.month == 1)
        #expect(target.isYearlyTarget == false)
        #expect(target.isDeleted == false)
    }

    @Test("Target作成 - コンビニエンスイニシャライザ")
    func targetCreation_convenienceInitializer() async {
        let target = Target(
            title: "テスト目標",
            year: 2024,
            month: 11,
            isYearlyTarget: true
        )

        #expect(target.title == "テスト目標")
        #expect(target.year == 2024)
        #expect(target.month == 11)
        #expect(target.isYearlyTarget == true)
    }

    // MARK: - エラーハンドリングテスト

    @Test("エラーハンドリング - isLoadingの初期状態")
    func errorHandling_isLoadingInitialState() async {
        let viewModel = TargetViewModel()
        #expect(viewModel.isLoading == false)
    }

    @Test("エラーハンドリング - currentErrorの初期状態")
    func errorHandling_currentErrorInitialState() async {
        let viewModel = TargetViewModel()
        #expect(viewModel.currentError == nil)
    }

    @Test("エラーハンドリング - showingErrorAlertの初期状態")
    func errorHandling_showingErrorAlertInitialState() async {
        let viewModel = TargetViewModel()
        #expect(viewModel.showingErrorAlert == false)
    }

    // MARK: - 年間/月間目標の分類テスト

    @Test("分類 - 年間目標と月間目標の混在")
    func classification_mixedYearlyAndMonthly() async {
        let viewModel = TargetViewModel()

        let yearlyTarget = Target(title: "年間", year: 2024, month: 1, isYearlyTarget: true)
        let monthlyTarget = Target(title: "月間", year: 2024, month: 11, isYearlyTarget: false)

        viewModel.yearlyTargets = [yearlyTarget]
        viewModel.monthlyTargets = [monthlyTarget]

        #expect(viewModel.yearlyTargets.count == 1)
        #expect(viewModel.monthlyTargets.count == 1)
        #expect(viewModel.yearlyTargets[0].isYearlyTarget == true)
        #expect(viewModel.monthlyTargets[0].isYearlyTarget == false)
    }

    @Test("分類 - 複数の年間目標")
    func classification_multipleYearlyTargets() async {
        let viewModel = TargetViewModel()

        let targets = (0..<5)
            .map { i in
                Target(title: "年間目標\(i)", year: 2024, month: 1, isYearlyTarget: true)
            }

        viewModel.yearlyTargets = targets

        #expect(viewModel.yearlyTargets.count == 5)
        #expect(viewModel.yearlyTargets.allSatisfy { $0.isYearlyTarget == true })
    }

    @Test("分類 - 複数の月間目標")
    func classification_multipleMonthlyTargets() async {
        let viewModel = TargetViewModel()

        let targets = (1...12)
            .map { month in
                Target(title: "\(month)月の目標", year: 2024, month: month, isYearlyTarget: false)
            }

        viewModel.monthlyTargets = targets

        #expect(viewModel.monthlyTargets.count == 12)
        #expect(viewModel.monthlyTargets.allSatisfy { $0.isYearlyTarget == false })
    }

    // MARK: - CRUD操作テスト

    @Test("fetchTargetsByYearMonth - 目標を取得できる")
    func fetchTargetsByYearMonth_retrievesTargets() async {
        let viewModel = TargetViewModel()
        let manager = RealmManager.shared
        try? manager.clearAll()

        let target1 = Target(title: "Target 1", year: 2024, month: 11, isYearlyTarget: false)
        let target2 = Target(title: "Target 2", year: 2024, month: 11, isYearlyTarget: false)
        try? manager.saveItem(target1)
        try? manager.saveItem(target2)

        _ = await viewModel.fetchTargetsByYearMonth(year: 2024, month: 11)

        #expect(viewModel.monthlyTargets.count == 2)

        try? manager.clearAll()
    }

    @Test("save - 新規目標を保存できる")
    func save_savesNewTarget() async {
        let viewModel = TargetViewModel()
        let manager = RealmManager.shared
        try? manager.clearAll()

        let target = Target(title: "New Target", year: 2024, month: 11, isYearlyTarget: false)

        let result = await viewModel.save(target)

        if case .failure = result {
            Issue.record("Save failed")
        }

        _ = await viewModel.fetchTargetsByYearMonth(year: 2024, month: 11)
        #expect(viewModel.monthlyTargets.count == 1)

        try? manager.clearAll()
    }

    @Test("delete - 目標を削除できる")
    func delete_deletesTarget() async {
        let viewModel = TargetViewModel()
        let manager = RealmManager.shared
        try? manager.clearAll()

        let target = Target(title: "Target", year: 2024, month: 11, isYearlyTarget: false)
        try? manager.saveItem(target)

        _ = await viewModel.fetchTargetsByYearMonth(year: 2024, month: 11)
        #expect(viewModel.monthlyTargets.count == 1)

        let result = await viewModel.delete(id: target.targetID)

        if case .failure = result {
            Issue.record("Delete failed")
        }

        #expect(viewModel.monthlyTargets.isEmpty)

        try? manager.clearAll()
    }

    @Test(
        "delete - performBackgroundSyncが直接呼ばれ、戻り値を返す前にBackgroundSyncTrackerへ登録される（issue #164回帰）"
    )
    func delete_registersBackgroundSyncTaskBeforeReturning() async {
        let viewModel = TargetViewModel()
        let manager = RealmManager.shared
        try? manager.clearAll()

        // 他テストの追跡Taskが残っていないことを保証
        await BackgroundSyncTracker.shared.waitForAll()

        let target = Target(title: "Target", year: 2024, month: 11, isYearlyTarget: false)
        try? manager.saveItem(target)
        _ = await viewModel.fetchTargetsByYearMonth(year: 2024, month: 11)

        _ = await viewModel.delete(id: target.targetID)

        // delete(id:)から戻った直後（追加のawait/yieldを挟まない）時点でperformBackgroundSyncが
        // 直接（同期的に）呼ばれていればtrack()は既に完了している。外側Task{}でラップされていると
        // この時点ではまだ登録されておらず0のままになる（issue #164のシナリオを再現する回帰テスト）
        #expect(BackgroundSyncTracker.shared.trackedCountForTesting == 1)

        await BackgroundSyncTracker.shared.waitForAll()
        #expect(BackgroundSyncTracker.shared.trackedCountForTesting == 0)

        try? manager.clearAll()
    }

    // MARK: - convertFirebaseSyncError テスト（issue #36: エラー二重変換防止）

    @Test(
        "convertFirebaseSyncError - 既にSportsNoteErrorの場合は再変換せずそのまま返す",
        arguments: [
            SportsNoteError.firebasePermissionDenied,
            SportsNoteError.firebaseDocumentNotFound,
            SportsNoteError.networkTimeout,
        ])
    func convertFirebaseSyncError_doesNotReconvertExistingSportsNoteError(original: SportsNoteError) async {
        let viewModel = TargetViewModel()

        let converted = viewModel.convertFirebaseSyncError(original, context: "TargetViewModel-syncEntityToFirebase")

        #expect(converted.errorDescription == original.errorDescription)
    }
}

// MARK: - テストヘルパー拡張

extension TargetViewModelTests {

    /// テスト用のTargetを作成
    static func createTestTarget(
        title: String = "Test Target",
        year: Int = 2024,
        month: Int = 1,
        isYearlyTarget: Bool = false
    ) -> Target {
        return Target(
            title: title,
            year: year,
            month: month,
            isYearlyTarget: isYearlyTarget
        )
    }

    /// 複数のテストTargetを作成
    static func createTestTargets(count: Int, isYearlyTarget: Bool = false) -> [Target] {
        return (0..<count)
            .map { i in
                createTestTarget(
                    title: "Target \(i)",
                    year: 2024,
                    month: (i % 12) + 1,
                    isYearlyTarget: isYearlyTarget
                )
            }
    }
}
