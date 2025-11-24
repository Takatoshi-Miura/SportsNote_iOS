//
//  RealmManagerTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2025/11/24.
//

import Foundation
import Testing
import RealmSwift
import UIKit

@testable import SportsNote_iOS

@Suite("RealmManager Tests", .serialized)
@MainActor
struct RealmManagerTests {
    
    let manager: RealmManager
    
    init() async throws {
        // テストごとに新しいインスタンスを作成し、インメモリ設定を適用
        manager = RealmManager()
        manager.setupInMemoryRealm()
    }
    
    // MARK: - CRUD操作テスト
    
    @Test("saveItem - データを正常に保存・取得できる")
    func saveItem_savesAndRetrievesData() async throws {
        // let manager = RealmManager.shared (プロパティを使用)
        
        // テストデータ作成
        let group = Group(
            groupID: "test-group-1",
            title: "Test Group",
            color: 0,
            order: 0,
            created_at: Date()
        )
        
        // 保存
        try manager.saveItem(group)
        
        // IDで取得して検証
        let savedGroup = try manager.getObjectById(id: "test-group-1", type: Group.self)
        #expect(savedGroup != nil)
        #expect(savedGroup?.title == "Test Group")
        
        // クリーンアップ
        manager.clearAll()
    }
    
    @Test("updateAllUserIds - 全データのUserIDを一括更新できる")
    func updateAllUserIds_updatesAllData() async throws {
        // let manager = RealmManager.shared
        
        // 複数のデータを作成
        let group = Group(groupID: "g1", title: "G1", color: 0, order: 0, created_at: Date())
        group.userID = "old-user"
        
        let note = Note(title: "N1")
        note.noteID = "n1"
        note.userID = "old-user"
        
        try manager.saveItem(group)
        try manager.saveItem(note)
        
        // 更新実行
        try manager.updateAllUserIds(userId: "new-user")
        
        // 検証
        let updatedGroup = try manager.getObjectById(id: "g1", type: Group.self)
        let updatedNote = try manager.getObjectById(id: "n1", type: Note.self)
        
        #expect(updatedGroup?.userID == "new-user")
        #expect(updatedNote?.userID == "new-user")
        
        manager.clearAll()
    }
    
    @Test("getDataList - データ一覧を取得できる（ソート順・論理削除除外）")
    func getDataList_returnsSortedListExcludingDeleted() async throws {
        // let manager = RealmManager.shared
        
        // テストデータ作成
        let group1 = Group(groupID: "g1", title: "Group 1", color: 0, order: 1, created_at: Date())
        let group2 = Group(groupID: "g2", title: "Group 2", color: 0, order: 0, created_at: Date()) // orderが小さい
        let group3 = Group(groupID: "g3", title: "Group 3", color: 0, order: 2, created_at: Date())
        group3.isDeleted = true // 削除済み
        
        try manager.saveItem(group1)
        try manager.saveItem(group2)
        try manager.saveItem(group3)
        
        // 取得
        let results = try manager.getDataList(clazz: Group.self)
        
        // 検証
        #expect(results.count == 2) // 削除済みは除外される
        #expect(results[0].groupID == "g2") // order順（0 -> 1）
        #expect(results[1].groupID == "g1")
        
        manager.clearAll()
    }
    
    @Test("getCount - 有効なデータ件数を取得できる")
    func getCount_returnsValidCount() async throws {
        // let manager = RealmManager.shared
        
        try manager.saveItem(Note(title: "Note 1"))
        try manager.saveItem(Note(title: "Note 2"))
        
        let deletedNote = Note(title: "Deleted")
        deletedNote.isDeleted = true
        try manager.saveItem(deletedNote)
        
        let count = try manager.getCount(clazz: Note.self)
        #expect(count == 2)
        
        manager.clearAll()
    }
    
    // MARK: - 論理削除テスト
    
    @Test("logicalDelete - データを論理削除できる")
    func logicalDelete_marksAsDeleted() async throws {
        // let manager = RealmManager.shared
        
        let note = Note(title: "Delete Me")
        note.noteID = "del-1"
        try manager.saveItem(note)
        
        // 論理削除
        try manager.logicalDelete(id: "del-1", type: Note.self)
        
        // getObjectByIdは削除済みデータを返さないはず
        let deletedNote = try manager.getObjectById(id: "del-1", type: Note.self)
        #expect(deletedNote == nil)
        
        // 直接Realmから確認（isDeletedがtrueになっているか）
        // RealmManagerのヘルパーメソッドを使用
        let rawNote = manager.getRawObjectById(id: "del-1", type: Note.self)
        #expect(rawNote != nil)
        #expect(rawNote?.isDeleted == true)
        
        manager.clearAll()
    }
    
    @Test("logicalDelete - 連鎖削除（Group -> Task -> Measures -> Memo）")
    func logicalDelete_cascadesDeletion() async throws {
        // let manager = RealmManager.shared
        
        // 階層データ作成
        let group = Group(groupID: "g-cascade", title: "Group", color: 0, order: 0, created_at: Date())
        
        let task = TaskData()
        task.taskID = "t-cascade"
        task.groupID = "g-cascade"
        
        let measures = Measures()
        measures.measuresID = "m-cascade"
        measures.taskID = "t-cascade"
        
        let memo = Memo()
        memo.memoID = "memo-cascade"
        memo.measuresID = "m-cascade"
        
        try manager.saveItem(group)
        try manager.saveItem(task)
        try manager.saveItem(measures)
        try manager.saveItem(memo)
        
        // Groupを削除
        try manager.logicalDelete(id: "g-cascade", type: Group.self)
        
        // 全て論理削除されているか確認
        // RealmManagerのヘルパーメソッドを使用
        
        let rawGroup = manager.getRawObjectById(id: "g-cascade", type: Group.self)
        let rawTask = manager.getRawObjectById(id: "t-cascade", type: TaskData.self)
        let rawMeasures = manager.getRawObjectById(id: "m-cascade", type: Measures.self)
        let rawMemo = manager.getRawObjectById(id: "memo-cascade", type: Memo.self)
        
        #expect(rawGroup?.isDeleted == true)
        #expect(rawTask?.isDeleted == true)
        #expect(rawMeasures?.isDeleted == true)
        #expect(rawMemo?.isDeleted == true)
        
        manager.clearAll()
    }
    
    // MARK: - 検索機能テスト
    
    @Test("searchNotesByQuery - クエリでノートを検索できる")
    func searchNotesByQuery_findsMatchingNotes() async throws {
        // let manager = RealmManager.shared
        
        let note1 = Note(title: "Swift Testing")
        note1.noteID = "n-1"
        note1.purpose = "Learn testing"
        // note1はフリーノートのまま（Note(title:)はデフォルトでfree）
        
        let note2 = Note(title: "Realm DB")
        note2.noteID = "n-2"
        note2.noteType = NoteType.practice.rawValue // 検索対象にするためpracticeに変更
        note2.detail = "Database management"
        
        let note3 = Note(title: "Unrelated")
        note3.noteID = "n-3"
        note3.noteType = NoteType.tournament.rawValue // 検索対象外にするためtournamentに変更（クエリにヒットしない）
        
        try manager.saveItem(note1)
        try manager.saveItem(note2)
        try manager.saveItem(note3)
        
        // "test"で検索 -> note1 (Free) がヒット
        let results1 = manager.searchNotesByQuery(query: "test")
        #expect(results1.count == 1)
        #expect(results1.first?.noteID == "n-1")
        
        // "Data"で検索 -> note1 (Free) と note2 (Practice) がヒット
        // searchNotesByQueryは常に全てのフリーノートを返す仕様のため
        let results2 = manager.searchNotesByQuery(query: "Data")
        #expect(results2.count == 2)
        #expect(results2.contains(where: { $0.noteID == "n-1" }))
        #expect(results2.contains(where: { $0.noteID == "n-2" }))
        
        manager.clearAll()
    }
    
    @Test("getNotesByDate - 日付でノートを取得できる")
    func getNotesByDate_findsNotesOnDate() async throws {
        // let manager = RealmManager.shared
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let noteToday = Note(title: "Today")
        noteToday.noteID = "today"
        noteToday.noteType = NoteType.practice.rawValue // 日付検索対象にするためpracticeに変更
        noteToday.date = today
        
        let noteYesterday = Note(title: "Yesterday")
        noteYesterday.noteID = "yesterday"
        noteYesterday.noteType = NoteType.practice.rawValue // 日付検索対象にするためpracticeに変更
        noteYesterday.date = yesterday
        
        try manager.saveItem(noteToday)
        try manager.saveItem(noteYesterday)
        
        // 今日のノートを取得
        let results = manager.getNotesByDate(selectedDate: today)
        #expect(results.count == 1)
        #expect(results.first?.noteID == "today")
        
        manager.clearAll()
    }
    
    @Test("getFreeNote - フリーノートを取得できる")
    func getFreeNote_returnsFreeNote() async throws {
        // let manager = RealmManager.shared
        
        let freeNote = Note(title: "Free Note")
        freeNote.noteType = NoteType.free.rawValue
        
        let practiceNote = Note(title: "Practice Note")
        practiceNote.noteType = NoteType.practice.rawValue
        
        try manager.saveItem(freeNote)
        try manager.saveItem(practiceNote)
        
        let result = manager.getFreeNote()
        #expect(result != nil)
        #expect(result?.noteType == NoteType.free.rawValue)
        
        manager.clearAll()
    }
    
    @Test("getNotes - 通常ノート（フリー以外）を日付順で取得できる")
    func getNotes_returnsSortedNormalNotes() async throws {
        // let manager = RealmManager.shared
        
        let today = Date()
        let yesterday = Date().addingTimeInterval(-86400)
        
        let note1 = Note(title: "Today")
        note1.noteType = NoteType.practice.rawValue
        note1.date = today
        
        let note2 = Note(title: "Yesterday")
        note2.noteType = NoteType.tournament.rawValue
        note2.date = yesterday
        
        let freeNote = Note(title: "Free")
        freeNote.noteType = NoteType.free.rawValue
        
        try manager.saveItem(note1)
        try manager.saveItem(note2)
        try manager.saveItem(freeNote)
        
        let results = manager.getNotes()
        
        #expect(results.count == 2) // フリーノートは除外
        #expect(results[0].title == "Today") // 日付降順
        #expect(results[1].title == "Yesterday")
        
        manager.clearAll()
    }
    
    // MARK: - 特定条件取得テスト
    
    @Test("getCompletedTasksByGroupId - 完了済み課題のみ取得できる")
    func getCompletedTasksByGroupId_returnsOnlyCompleted() async throws {
        // let manager = RealmManager.shared
        let groupID = "g-tasks"
        
        let task1 = TaskData()
        task1.taskID = "t-1"
        task1.groupID = groupID
        task1.isComplete = true
        task1.order = 1
        
        let task2 = TaskData()
        task2.taskID = "t-2"
        task2.groupID = groupID
        task2.isComplete = false // 未完了
        task2.order = 0
        
        let task3 = TaskData()
        task3.taskID = "t-3"
        task3.groupID = "other-group" // 別のグループ
        task3.isComplete = true
        
        try manager.saveItem(task1)
        try manager.saveItem(task2)
        try manager.saveItem(task3)
        
        let results = manager.getCompletedTasksByGroupId(groupID: groupID)
        #expect(results.count == 1)
        manager.clearAll()
    }
    
    @Test("getMeasuresByTaskID - 特定TaskIDの対策を取得できる")
    func getMeasuresByTaskID_returnsMeasures() async throws {
        // let manager = RealmManager.shared
        let taskID = "t-measures"
        
        let m1 = Measures()
        m1.measuresID = "m1"
        m1.taskID = taskID
        m1.order = 1
        
        let m2 = Measures()
        m2.measuresID = "m2"
        m2.taskID = taskID
        m2.order = 0
        
        let m3 = Measures()
        m3.measuresID = "m3"
        m3.taskID = "other-task"
        
        try manager.saveItem(m1)
        try manager.saveItem(m2)
        try manager.saveItem(m3)
        
        let results = manager.getMeasuresByTaskID(taskID: taskID)
        #expect(results.count == 2)
        #expect(results[0].measuresID == "m2") // order順
        #expect(results[1].measuresID == "m1")
        
        manager.clearAll()
    }
    
    @Test("getMemosByMeasuresID - 特定MeasuresIDのメモを取得できる")
    func getMemosByMeasuresID_returnsMemos() async throws {
        // let manager = RealmManager.shared
        let measuresID = "m-memos"
        
        let memo1 = Memo()
        memo1.memoID = "memo1"
        memo1.measuresID = measuresID
        memo1.created_at = Date()
        
        let memo2 = Memo()
        memo2.memoID = "memo2"
        memo2.measuresID = "other-measures"
        
        try manager.saveItem(memo1)
        try manager.saveItem(memo2)
        
        let results = manager.getMemosByMeasuresID(measuresID: measuresID)
        #expect(results.count == 1)
        #expect(results.first?.memoID == "memo1")
        
        manager.clearAll()
    }
    
    @Test("getMemosByNoteID - 特定NoteIDのメモを取得できる")
    func getMemosByNoteID_returnsMemos() async throws {
        // let manager = RealmManager.shared
        let noteID = "n-memos"
        
        let memo1 = Memo()
        memo1.memoID = "memo1"
        memo1.noteID = noteID
        
        let memo2 = Memo()
        memo2.memoID = "memo2"
        memo2.noteID = "other-note"
        
        try manager.saveItem(memo1)
        try manager.saveItem(memo2)
        
        let results = manager.getMemosByNoteID(noteID: noteID)
        #expect(results.count == 1)
        #expect(results.first?.memoID == "memo1")
        
        manager.clearAll()
    }
    
    @Test("fetchYearlyTargets - 年間目標を取得できる")
    func fetchYearlyTargets_returnsTargets() async throws {
        // let manager = RealmManager.shared
        let year = 2025
        
        let t1 = Target(title: "Yearly Target", year: year, month: 0, isYearlyTarget: true)
        let t2 = Target(title: "Monthly Target", year: year, month: 1, isYearlyTarget: false)
        let t3 = Target(title: "Other Year", year: 2024, month: 0, isYearlyTarget: true)
        
        try manager.saveItem(t1)
        try manager.saveItem(t2)
        try manager.saveItem(t3)
        
        let results = manager.fetchYearlyTargets(year: year)
        #expect(results.count == 1)
        #expect(results.first?.title == "Yearly Target")
        
        manager.clearAll()
    }
    
    @Test("fetchTargetsByYearMonth - 月間目標を取得できる")
    func fetchTargetsByYearMonth_returnsTargets() async throws {
        // let manager = RealmManager.shared
        let year = 2025
        let month = 5
        
        let t1 = Target(title: "May Target", year: year, month: month, isYearlyTarget: false)
        let t2 = Target(title: "June Target", year: year, month: 6, isYearlyTarget: false)
        let t3 = Target(title: "Yearly Target", year: year, month: 0, isYearlyTarget: true)
        
        try manager.saveItem(t1)
        try manager.saveItem(t2)
        try manager.saveItem(t3)
        
        let results = manager.fetchTargetsByYearMonth(year: year, month: month)
        #expect(results.count == 1)
        #expect(results.first?.title == "May Target")
        
        manager.clearAll()
    }
    
    @Test("getNoteBackgroundColor - 正しい背景色を取得できる")
    func getNoteBackgroundColor_returnsCorrectColor() async throws {
        // let manager = RealmManager.shared
        
        // 階層データ作成
        let group = Group(groupID: "g-color", title: "Blue Group", color: GroupColor.blue.rawValue, order: 0, created_at: Date())
        
        let task = TaskData()
        task.taskID = "t-color"
        task.groupID = "g-color"
        
        let measures = Measures()
        measures.measuresID = "m-color"
        measures.taskID = "t-color"
        
        let memo = Memo()
        memo.memoID = "memo-color"
        memo.measuresID = "m-color"
        memo.noteID = "n-color" // NoteIDと紐付け
        
        try manager.saveItem(group)
        try manager.saveItem(task)
        try manager.saveItem(measures)
        try manager.saveItem(memo)
        
        // NoteIDから背景色（Groupの色）を取得
        let color = manager.getNoteBackgroundColor(noteID: "n-color")
        
        // GroupColor.blueの色と一致するか確認
        // UIColorの比較は厳密には難しいが、ここではCGColorで比較
        #expect(color.cgColor == GroupColor.blue.color.cgColor)
        
        manager.clearAll()
    }
    
    // MARK: - パラメータ化テスト
    
    @Test("searchNotesByQuery - 複数のクエリパターン", arguments: ["Swift", "Testing", "Learn"])
    func searchNotesByQuery_parameterized(query: String) async throws {
        // let manager = RealmManager.shared
        
        let note = Note(title: "Swift Testing")
        note.noteID = "n-param"
        note.purpose = "Learn testing"
        
        try manager.saveItem(note)
        
        let results = manager.searchNotesByQuery(query: query)
        #expect(!results.isEmpty)
        #expect(results.first?.noteID == "n-param")
        
        manager.clearAll()
    }
}
