//
//  MemoViewModelTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2025/11/23.
//

import Foundation
import Testing
import RealmSwift

@testable import SportsNote_iOS

@Suite("MemoViewModel Tests", .serialized)
@MainActor
struct MemoViewModelTests {
    
    init() async throws {
        // インメモリRealmの設定
        RealmManager.shared.setupInMemoryRealm()
    }
    
    // MARK: - 初期化テスト
    
    @Test("初期化 - プロパティが正しく初期化される")
    func initialization_propertiesAreInitializedCorrectly() async {
        let viewModel = MemoViewModel()
        
        #expect(viewModel.memoList.isEmpty)
        #expect(viewModel.measuresMemoList.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.currentError == nil)
        #expect(viewModel.showingErrorAlert == false)
    }
    
    // MARK: - プロパティテスト
    
    @Test("プロパティ - memoListの設定と取得")
    func property_memoListSetAndGet() async {
        let viewModel = MemoViewModel()
        
        let testMemo = Memo()
        testMemo.memoID = "memo-1"
        testMemo.detail = "Test memo detail"
        
        viewModel.memoList = [testMemo]
        
        #expect(viewModel.memoList.count == 1)
        #expect(viewModel.memoList[0].detail == "Test memo detail")
    }
    
    @Test("プロパティ - measuresMemoListの設定と取得")
    func property_measuresMemoListSetAndGet() async {
        let viewModel = MemoViewModel()
        
        let testMeasuresMemo = MeasuresMemo(
            memoID: "memo-1",
            measuresID: "measures-1",
            noteID: "note-1",
            detail: "Test detail",
            date: Date()
        )
        
        viewModel.measuresMemoList = [testMeasuresMemo]
        
        #expect(viewModel.measuresMemoList.count == 1)
        #expect(viewModel.measuresMemoList[0].detail == "Test detail")
    }
    
    // MARK: - 通知処理テスト
    
    @Test("通知処理 - didClearAllData通知でクリアされる")
    func notification_clearsOnDidClearAllData() async {
        let viewModel = MemoViewModel()
        
        // データを追加
        let testMemo = Memo()
        testMemo.memoID = "memo-1"
        testMemo.detail = "Test"
        viewModel.memoList = [testMemo]
        
        #expect(!viewModel.memoList.isEmpty)
        
        // 通知を送信
        NotificationCenter.default.post(name: .didClearAllData, object: nil)
        
        // 非同期処理を待つ
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        #expect(viewModel.memoList.isEmpty)
        #expect(viewModel.measuresMemoList.isEmpty)
    }
    
    // MARK: - メモ詳細テスト
    
    @Test("メモ詳細 - 空の詳細")
    func memoDetail_emptyDetail() async {
        let viewModel = MemoViewModel()
        
        let memo = Memo()
        memo.memoID = "memo-1"
        memo.detail = ""
        
        viewModel.memoList = [memo]
        
        #expect(viewModel.memoList[0].detail == "")
    }
    
    @Test("メモ詳細 - 特殊文字を含む詳細",
          arguments: [
            "メモ🎾テニス",
            "Line1\nLine2\nLine3",
            "Tab\t\tSeparated",
            "Special & Characters <>"
          ])
    func memoDetail_specialCharacters(detail: String) async {
        let viewModel = MemoViewModel()
        
        let memo = Memo()
        memo.memoID = "memo-1"
        memo.detail = detail
        
        viewModel.memoList = [memo]
        
        #expect(viewModel.memoList[0].detail == detail)
    }
    
    @Test("メモ詳細 - 非常に長い詳細")
    func memoDetail_veryLongDetail() async {
        let viewModel = MemoViewModel()
        let longDetail = String(repeating: "あいうえお", count: 200)
        
        let memo = Memo()
        memo.memoID = "memo-1"
        memo.detail = longDetail
        
        viewModel.memoList = [memo]
        
        #expect(viewModel.memoList[0].detail == longDetail)
        #expect(viewModel.memoList[0].detail.count == 1000)
    }
    
    // MARK: - 境界値テスト
    
    @Test("境界値 - 空のmemoList")
    func boundaryCase_emptyMemoList() async {
        let viewModel = MemoViewModel()
        
        #expect(viewModel.memoList.isEmpty)
        #expect(viewModel.memoList.count == 0)
    }
    
    @Test("境界値 - 大量のメモ", arguments: [10, 50, 100])
    func boundaryCase_largeMemoList(count: Int) async {
        let viewModel = MemoViewModel()
        
        var memoList: [Memo] = []
        for i in 0..<count {
            let memo = Memo()
            memo.memoID = "memo-\(i)"
            memo.detail = "Detail \(i)"
            memoList.append(memo)
        }
        
        viewModel.memoList = memoList
        
        #expect(viewModel.memoList.count == count)
    }
    
    // MARK: - MeasuresMemo構造体テスト
    
    @Test("MeasuresMemo構造体 - プロパティが正しく設定される")
    func measuresMemoStruct_propertiesSetCorrectly() async {
        let date = Date()
        let measuresMemo = MeasuresMemo(
            memoID: "memo-1",
            measuresID: "measures-1",
            noteID: "note-1",
            detail: "Test detail",
            date: date
        )
        
        #expect(measuresMemo.memoID == "memo-1")
        #expect(measuresMemo.measuresID == "measures-1")
        #expect(measuresMemo.noteID == "note-1")
        #expect(measuresMemo.detail == "Test detail")
        #expect(measuresMemo.date == date)
    }
    
    @Test("MeasuresMemo構造体 - 空の値で作成")
    func measuresMemoStruct_createWithEmptyValues() async {
        let measuresMemo = MeasuresMemo(
            memoID: "",
            measuresID: "",
            noteID: "",
            detail: "",
            date: Date()
        )
        
        #expect(measuresMemo.memoID == "")
        #expect(measuresMemo.measuresID == "")
        #expect(measuresMemo.noteID == "")
        #expect(measuresMemo.detail == "")
    }
    
    // MARK: - 複数measuresIDテスト
    
    @Test("複数measuresID - 異なるmeasuresIDを持つメモ")
    func multipleMeasuresIds_differentMeasuresIds() async {
        let viewModel = MemoViewModel()
        
        let memo1 = Memo()
        memo1.memoID = "memo-1"
        memo1.measuresID = "measures-1"
        memo1.detail = "Detail 1"
        
        let memo2 = Memo()
        memo2.memoID = "memo-2"
        memo2.measuresID = "measures-2"
        memo2.detail = "Detail 2"
        
        viewModel.memoList = [memo1, memo2]
        
        #expect(viewModel.memoList.count == 2)
        #expect(viewModel.memoList[0].measuresID == "measures-1")
        #expect(viewModel.memoList[1].measuresID == "measures-2")
    }
    
    // MARK: - エラーハンドリングテスト
    
    @Test("エラーハンドリング - isLoadingの初期状態")
    func errorHandling_isLoadingInitialState() async {
        let viewModel = MemoViewModel()
        #expect(viewModel.isLoading == false)
    }
    
    @Test("エラーハンドリング - currentErrorの初期状態")
    func errorHandling_currentErrorInitialState() async {
        let viewModel = MemoViewModel()
        #expect(viewModel.currentError == nil)
    }
    
    @Test("エラーハンドリング - showingErrorAlertの初期状態")
    func errorHandling_showingErrorAlertInitialState() async {
        let viewModel = MemoViewModel()
        #expect(viewModel.showingErrorAlert == false)
    }
    
    // MARK: - 日付テスト
    
    @Test("日付 - 異なる作成日時")
    func date_differentCreatedDates() async {
        let viewModel = MemoViewModel()
        
        let date1 = Date()
        let date2 = Date().addingTimeInterval(-3600) // 1時間前
        
        let memo1 = MeasuresMemo(
            memoID: "memo-1",
            measuresID: "measures-1",
            noteID: "note-1",
            detail: "Detail 1",
            date: date1
        )
        
        let memo2 = MeasuresMemo(
            memoID: "memo-2",
            measuresID: "measures-1",
            noteID: "note-1",
            detail: "Detail 2",
            date: date2
        )
        
        viewModel.measuresMemoList = [memo1, memo2]
        
        #expect(viewModel.measuresMemoList[0].date.timeIntervalSince1970 >
                viewModel.measuresMemoList[1].date.timeIntervalSince1970)
    }
    
    @Test("日付 - 未来の日付")
    func date_futureDate() async {
        let futureDate = Date().addingTimeInterval(86400) // 1日後
        
        let measuresMemo = MeasuresMemo(
            memoID: "memo-1",
            measuresID: "measures-1",
            noteID: "note-1",
            detail: "Future memo",
            date: futureDate
        )
        
        #expect(measuresMemo.date > Date())
    }
    
    @Test("日付 - 過去の日付")
    func date_pastDate() async {
        let pastDate = Date().addingTimeInterval(-86400 * 365) // 1年前
        
        let measuresMemo = MeasuresMemo(
            memoID: "memo-1",
            measuresID: "measures-1",
            noteID: "note-1",
            detail: "Past memo",
            date: pastDate
        )
        
        #expect(measuresMemo.date < Date())
    }
    
    // MARK: - ソート関連テスト
    
    @Test("ソート - 作成日時でソート可能")
    func sort_canSortByCreatedDate() async {
        let viewModel = MemoViewModel()
        
        let date1 = Date().addingTimeInterval(-200)
        let date2 = Date().addingTimeInterval(-100)
        let date3 = Date()
        
        let memo1 = MeasuresMemo(memoID: "1", measuresID: "m1", noteID: "n1", detail: "Old", date: date1)
        let memo2 = MeasuresMemo(memoID: "2", measuresID: "m1", noteID: "n1", detail: "Middle", date: date2)
        let memo3 = MeasuresMemo(memoID: "3", measuresID: "m1", noteID: "n1", detail: "New", date: date3)
        
        viewModel.measuresMemoList = [memo3, memo1, memo2]
        
        let sorted = viewModel.measuresMemoList.sorted { $0.date < $1.date }
        
        #expect(sorted[0].memoID == "1")
        #expect(sorted[1].memoID == "2")
        #expect(sorted[2].memoID == "3")
    }
    
    // MARK: - CRUD操作テスト
    
    @Test("fetchData - データを取得できる")
    func fetchData_retrievesData() async {
        let viewModel = MemoViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let memo1 = Memo(memoID: "m1", measuresID: "ms1", noteID: "n1", detail: "Detail 1", created_at: Date())
        let memo2 = Memo(memoID: "m2", measuresID: "ms2", noteID: "n2", detail: "Detail 2", created_at: Date())
        try? manager.saveItem(memo1)
        try? manager.saveItem(memo2)
        
        _ = await viewModel.fetchData()
        
        #expect(viewModel.memoList.count == 2)
        #expect(viewModel.memoList.contains(where: { $0.memoID == "m1" }))
        #expect(viewModel.memoList.contains(where: { $0.memoID == "m2" }))
        
        manager.clearAll()
    }
    
    @Test("save - 新規メモを保存できる")
    func save_savesNewMemo() async {
        let viewModel = MemoViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let memo = Memo(memoID: "new-memo", measuresID: "ms1", noteID: "n1", detail: "New Detail", created_at: Date())
        
        let result = await viewModel.save(memo)
        
        if case .failure = result {
            Issue.record("Save failed")
        }
        
        #expect(viewModel.memoList.count == 1)
        #expect(viewModel.memoList.first?.memoID == "new-memo")
        
        manager.clearAll()
    }
    
    @Test("delete - メモを削除できる")
    func delete_deletesMemo() async {
        let viewModel = MemoViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let memo = Memo(memoID: "m1", measuresID: "ms1", noteID: "n1", detail: "Detail", created_at: Date())
        try? manager.saveItem(memo)
        
        _ = await viewModel.fetchData()
        #expect(viewModel.memoList.count == 1)
        
        let result = await viewModel.delete(id: "m1")
        
        if case .failure = result {
            Issue.record("Delete failed")
        }
        
        #expect(viewModel.memoList.isEmpty)
        
        manager.clearAll()
    }
    
    @Test("getMemosByMeasuresID - 対策IDに紐づくメモを取得できる")
    func getMemosByMeasuresID_retrievesMemos() async {
        let viewModel = MemoViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let note = Note(purpose: "Purpose", detail: "Detail")
        note.noteID = "n1"
        note.noteType = NoteType.practice.rawValue
        note.date = Date()
        try? manager.saveItem(note)
        
        let memo1 = Memo(memoID: "m1", measuresID: "ms1", noteID: "n1", detail: "Detail 1", created_at: Date())
        let memo2 = Memo(memoID: "m2", measuresID: "ms1", noteID: "n1", detail: "Detail 2", created_at: Date())
        let memo3 = Memo(memoID: "m3", measuresID: "ms2", noteID: "n1", detail: "Detail 3", created_at: Date())
        try? manager.saveItem(memo1)
        try? manager.saveItem(memo2)
        try? manager.saveItem(memo3)
        
        let result = viewModel.getMemosByMeasuresID(measuresID: "ms1")
        
        if case .success(let memos) = result {
            #expect(memos.count == 2)
            #expect(memos.contains(where: { $0.memoID == "m1" }))
            #expect(memos.contains(where: { $0.memoID == "m2" }))
        } else {
            Issue.record("GetMemosByMeasuresID failed")
        }
        
        manager.clearAll()
    }
    
    @Test("saveMemo - 既存インターフェースでメモを保存できる")
    func saveMemo_savesWithLegacyInterface() async {
        let viewModel = MemoViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let result = await viewModel.saveMemo(
            measuresID: "ms1",
            noteID: "n1",
            detail: "Legacy Detail"
        )
        
        if case .success(let memo) = result {
            #expect(memo.detail == "Legacy Detail")
            #expect(memo.measuresID == "ms1")
            #expect(memo.noteID == "n1")
        } else {
            Issue.record("SaveMemo failed")
        }
        
        manager.clearAll()
    }
}

// MARK: - テストヘルパー拡張

extension MemoViewModelTests {
    
    /// テスト用のMemoを作成
    static func createTestMemo(
        id: String = "memo-1",
        measuresID: String = "measures-1",
        detail: String = "Test detail"
    ) -> Memo {
        let memo = Memo()
        memo.memoID = id
        memo.measuresID = measuresID
        memo.detail = detail
        return memo
    }
    
    /// テスト用のMeasuresMemoを作成
    static func createTestMeasuresMemo(
        id: String = "memo-1",
        measuresID: String = "measures-1",
        noteID: String = "note-1",
        detail: String = "Test detail",
        date: Date = Date()
    ) -> MeasuresMemo {
        return MeasuresMemo(
            memoID: id,
            measuresID: measuresID,
            noteID: noteID,
            detail: detail,
            date: date
        )
    }
    
    /// 複数のテストメモを作成
    static func createTestMemoList(count: Int) -> [Memo] {
        return (0..<count).map { i in
            createTestMemo(
                id: "memo-\(i)",
                measuresID: "measures-1",
                detail: "Detail \(i)"
            )
        }
    }
}
