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

@Suite("MeasuresViewModel Tests", .serialized)
@MainActor
struct MeasuresViewModelTests {
    
    init() async throws {
        // インメモリRealmの設定
        RealmManager.shared.setupInMemoryRealm()
    }
    
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
    
    // MARK: - CRUD操作テスト
    
    @Test("fetchData - データを取得できる")
    func fetchData_retrievesData() async {
        let viewModel = MeasuresViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let measures1 = Measures(measuresID: "ms1", taskID: "t1", title: "Measures 1", order: 0, created_at: Date())
        let measures2 = Measures(measuresID: "ms2", taskID: "t1", title: "Measures 2", order: 1, created_at: Date())
        try? manager.saveItem(measures1)
        try? manager.saveItem(measures2)
        
        _ = await viewModel.fetchData()
        
        #expect(viewModel.measuresList.count == 2)
        #expect(viewModel.measuresList.contains(where: { $0.measuresID == "ms1" }))
        #expect(viewModel.measuresList.contains(where: { $0.measuresID == "ms2" }))
        
        manager.clearAll()
    }
    
    @Test("save - 新規対策を保存できる")
    func save_savesNewMeasures() async {
        let viewModel = MeasuresViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let measures = Measures(measuresID: "new-ms", taskID: "t1", title: "New Measures", order: 0, created_at: Date())
        
        let result = await viewModel.save(measures)
        
        if case .failure = result {
            Issue.record("Save failed")
        }
        
        #expect(viewModel.measuresList.count == 1)
        #expect(viewModel.measuresList.first?.measuresID == "new-ms")
        
        manager.clearAll()
    }
    
    @Test("delete - 対策を削除できる")
    func delete_deletesMeasures() async {
        let viewModel = MeasuresViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let measures = Measures(measuresID: "ms1", taskID: "t1", title: "Measures", order: 0, created_at: Date())
        try? manager.saveItem(measures)
        
        _ = await viewModel.fetchData()
        #expect(viewModel.measuresList.count == 1)
        
        let result = await viewModel.delete(id: "ms1")
        
        if case .failure = result {
            Issue.record("Delete failed")
        }
        
        #expect(viewModel.measuresList.isEmpty)
        
        manager.clearAll()
    }
    
    @Test("getMeasuresByTaskID - 課題IDに紐づく対策を取得できる")
    func getMeasuresByTaskID_retrievesMeasures() async {
        let viewModel = MeasuresViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let measures1 = Measures(measuresID: "ms1", taskID: "t1", title: "Measures 1", order: 0, created_at: Date())
        let measures2 = Measures(measuresID: "ms2", taskID: "t1", title: "Measures 2", order: 1, created_at: Date())
        let measures3 = Measures(measuresID: "ms3", taskID: "t2", title: "Measures 3", order: 0, created_at: Date())
        try? manager.saveItem(measures1)
        try? manager.saveItem(measures2)
        try? manager.saveItem(measures3)
        
        let result = await viewModel.getMeasuresByTaskID(taskID: "t1")
        
        if case .success(let measures) = result {
            #expect(measures.count == 2)
            #expect(measures.contains(where: { $0.measuresID == "ms1" }))
            #expect(measures.contains(where: { $0.measuresID == "ms2" }))
        } else {
            Issue.record("GetMeasuresByTaskID failed")
        }
        
        manager.clearAll()
    }
    
    @Test("getMostPriorityMeasures - 最優先対策を取得できる")
    func getMostPriorityMeasures_retrievesMostPriorityMeasures() async {
        let viewModel = MeasuresViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let measures1 = Measures(measuresID: "ms1", taskID: "t1", title: "Measures 1", order: 2, created_at: Date())
        let measures2 = Measures(measuresID: "ms2", taskID: "t1", title: "Measures 2", order: 0, created_at: Date())
        let measures3 = Measures(measuresID: "ms3", taskID: "t1", title: "Measures 3", order: 1, created_at: Date())
        try? manager.saveItem(measures1)
        try? manager.saveItem(measures2)
        try? manager.saveItem(measures3)
        
        let result = await viewModel.getMostPriorityMeasures(taskID: "t1")
        
        if case .success(let measures) = result {
            #expect(measures?.measuresID == "ms2")
            #expect(measures?.order == 0)
        } else {
            Issue.record("GetMostPriorityMeasures failed")
        }
        
        manager.clearAll()
    }
    
    @Test("saveMeasures - 既存インターフェースで対策を保存できる")
    func saveMeasures_savesWithLegacyInterface() async {
        let viewModel = MeasuresViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let result = await viewModel.saveMeasures(
            taskID: "t1",
            title: "Legacy Measures"
        )
        
        if case .failure = result {
            Issue.record("SaveMeasures failed")
        }
        
        #expect(viewModel.measuresList.count == 1)
        #expect(viewModel.measuresList.first?.title == "Legacy Measures")
        
        manager.clearAll()
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
