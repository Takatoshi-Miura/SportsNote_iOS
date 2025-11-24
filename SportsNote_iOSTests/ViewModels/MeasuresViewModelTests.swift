//
//  MeasuresViewModelTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2025/11/23.
//

import Foundation
import Testing
import RealmSwift

@testable import SportsNote_iOS

@Suite("MeasuresViewModel Tests")
@MainActor
struct MeasuresViewModelTests {
    
    // MARK: - 初期化テスト
    
    @Test("初期化 - プロパティが正しく初期化される")
    func initialization_propertiesAreInitializedCorrectly() async {
        let viewModel = MeasuresViewModel()
        
        #expect(viewModel.measuresList.isEmpty)
        #expect(viewModel.memos.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.currentError == nil)
        #expect(viewModel.showingErrorAlert == false)
    }
    
    // MARK: - プロパティテスト
    
    @Test("プロパティ - measuresListの設定と取得")
    func property_measuresListSetAndGet() async {
        let viewModel = MeasuresViewModel()
        
        let testMeasures = Measures(
            measuresID: "test-1",
            taskID: "task-1",
            title: "Test Measures",
            order: 0,
            created_at: Date()
        )
        
        viewModel.measuresList = [testMeasures]
        
        #expect(viewModel.measuresList.count == 1)
        #expect(viewModel.measuresList[0].title == "Test Measures")
    }
    
    @Test("プロパティ - memosの設定と取得")
    func property_memosSetAndGet() async {
        let viewModel = MeasuresViewModel()
        
        let testMemo = Memo()
        testMemo.memoID = "memo-1"
        testMemo.detail = "Test memo"
        
        viewModel.memos = [testMemo]
        
        #expect(viewModel.memos.count == 1)
        #expect(viewModel.memos[0].detail == "Test memo")
    }
    
    // MARK: - 通知処理テスト
    
    @Test("通知処理 - didClearAllData通知でクリアされる")
    func notification_clearsOnDidClearAllData() async {
        let viewModel = MeasuresViewModel()
        
        // データを追加
        let testMeasures = Measures(
            measuresID: "test-1",
            taskID: "task-1",
            title: "Test",
            order: 0,
            created_at: Date()
        )
        viewModel.measuresList = [testMeasures]
        
        #expect(!viewModel.measuresList.isEmpty)
        
        // 通知を送信
        NotificationCenter.default.post(name: .didClearAllData, object: nil)
        
        // 非同期処理を待つ
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        #expect(viewModel.measuresList.isEmpty)
        #expect(viewModel.memos.isEmpty)
    }
    
    // MARK: - 境界値テスト
    
    @Test("境界値 - 空のmeasuresList")
    func boundaryCase_emptyMeasuresList() async {
        let viewModel = MeasuresViewModel()
        
        #expect(viewModel.measuresList.isEmpty)
        #expect(viewModel.measuresList.count == 0)
    }
    
    @Test("境界値 - 大量のmeasures", arguments: [10, 50, 100])
    func boundaryCase_largeMeasuresList(count: Int) async {
        let viewModel = MeasuresViewModel()
        
        var measuresList: [Measures] = []
        for i in 0..<count {
            let measures = Measures(
                measuresID: "test-\(i)",
                taskID: "task-1",
                title: "Measures \(i)",
                order: i,
                created_at: Date()
            )
            measuresList.append(measures)
        }
        
        viewModel.measuresList = measuresList
        
        #expect(viewModel.measuresList.count == count)
    }
    
    @Test("境界値 - 空のタイトルを持つmeasures")
    func boundaryCase_emptyTitle() async {
        let viewModel = MeasuresViewModel()
        
        let measures = Measures(
            measuresID: "test-1",
            taskID: "task-1",
            title: "",
            order: 0,
            created_at: Date()
        )
        
        viewModel.measuresList = [measures]
        
        #expect(viewModel.measuresList[0].title == "")
    }
    
    @Test("境界値 - 非常に長いタイトル")
    func boundaryCase_veryLongTitle() async {
        let viewModel = MeasuresViewModel()
        let longTitle = String(repeating: "あ", count: 1000)
        
        let measures = Measures(
            measuresID: "test-1",
            taskID: "task-1",
            title: longTitle,
            order: 0,
            created_at: Date()
        )
        
        viewModel.measuresList = [measures]
        
        #expect(viewModel.measuresList[0].title == longTitle)
        #expect(viewModel.measuresList[0].title.count == 1000)
    }
    
    // MARK: - order値テスト
    
    @Test("order値 - 異なるorder値", arguments: [0, 1, 10, 100, 999])
    func orderValue_differentOrders(order: Int) async {
        let viewModel = MeasuresViewModel()
        
        let measures = Measures(
            measuresID: "test-1",
            taskID: "task-1",
            title: "Test",
            order: order,
            created_at: Date()
        )
        
        viewModel.measuresList = [measures]
        
        #expect(viewModel.measuresList[0].order == order)
    }
    
    @Test("order値 - 負のorder値")
    func orderValue_negativeOrder() async {
        let viewModel = MeasuresViewModel()
        
        let measures = Measures(
            measuresID: "test-1",
            taskID: "task-1",
            title: "Test",
            order: -1,
            created_at: Date()
        )
        
        viewModel.measuresList = [measures]
        
        #expect(viewModel.measuresList[0].order == -1)
    }
    
    // MARK: - 複数taskIDテスト
    
    @Test("複数taskID - 異なるtaskIDを持つmeasures")
    func multipleTaskIds_differentTaskIds() async {
        let viewModel = MeasuresViewModel()
        
        let measures1 = Measures(
            measuresID: "test-1",
            taskID: "task-1",
            title: "Measures 1",
            order: 0,
            created_at: Date()
        )
        
        let measures2 = Measures(
            measuresID: "test-2",
            taskID: "task-2",
            title: "Measures 2",
            order: 0,
            created_at: Date()
        )
        
        viewModel.measuresList = [measures1, measures2]
        
        #expect(viewModel.measuresList.count == 2)
        #expect(viewModel.measuresList[0].taskID == "task-1")
        #expect(viewModel.measuresList[1].taskID == "task-2")
    }
    
    // MARK: - エラーハンドリングテスト
    
    @Test("エラーハンドリング - isLoadingの初期状態")
    func errorHandling_isLoadingInitialState() async {
        let viewModel = MeasuresViewModel()
        #expect(viewModel.isLoading == false)
    }
    
    @Test("エラーハンドリング - currentErrorの初期状態")
    func errorHandling_currentErrorInitialState() async {
        let viewModel = MeasuresViewModel()
        #expect(viewModel.currentError == nil)
    }
    
    @Test("エラーハンドリング - showingErrorAlertの初期状態")
    func errorHandling_showingErrorAlertInitialState() async {
        let viewModel = MeasuresViewModel()
        #expect(viewModel.showingErrorAlert == false)
    }
    
    // MARK: - 日付テスト
    
    @Test("日付 - 異なる作成日時")
    func date_differentCreatedDates() async {
        let viewModel = MeasuresViewModel()
        
        let date1 = Date()
        let date2 = Date().addingTimeInterval(-86400) // 1日前
        
        let measures1 = Measures(
            measuresID: "test-1",
            taskID: "task-1",
            title: "Measures 1",
            order: 0,
            created_at: date1
        )
        
        let measures2 = Measures(
            measuresID: "test-2",
            taskID: "task-1",
            title: "Measures 2",
            order: 1,
            created_at: date2
        )
        
        viewModel.measuresList = [measures1, measures2]
        
        #expect(viewModel.measuresList[0].created_at.timeIntervalSince1970 > 
                viewModel.measuresList[1].created_at.timeIntervalSince1970)
    }
}

// MARK: - テストヘルパー拡張

extension MeasuresViewModelTests {
    
    /// テスト用のMeasuresを作成
    static func createTestMeasures(
        id: String = "test-1",
        taskID: String = "task-1",
        title: String = "Test Measures",
        order: Int = 0
    ) -> Measures {
        return Measures(
            measuresID: id,
            taskID: taskID,
            title: title,
            order: order,
            created_at: Date()
        )
    }
    
    /// 複数のテストMeasuresを作成
    static func createTestMeasuresList(count: Int, taskID: String = "task-1") -> [Measures] {
        return (0..<count).map { i in
            createTestMeasures(
                id: "test-\(i)",
                taskID: taskID,
                title: "Measures \(i)",
                order: i
            )
        }
    }
}
