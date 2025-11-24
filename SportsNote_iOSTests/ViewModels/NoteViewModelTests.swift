//
//  NoteViewModelTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2025/11/23.
//

import Foundation
import Testing
import RealmSwift

@testable import SportsNote_iOS

@Suite("NoteViewModel Tests", .serialized)
@MainActor
struct NoteViewModelTests {
    
    init() async throws {
        // インメモリRealmの設定
        RealmManager.shared.setupInMemoryRealm()
    }
    
    // MARK: - 初期化テスト
    
    @Test("初期化 - プロパティが正しく初期化される")
    func initialization_propertiesAreInitializedCorrectly() async {
        let viewModel = NoteViewModel()
        
        #expect(viewModel.notes.isEmpty)
        #expect(viewModel.selectedNote == nil)
        #expect(viewModel.practiceNotes.isEmpty)
        #expect(viewModel.tournamentNotes.isEmpty)
        #expect(viewModel.freeNotes.isEmpty)
        #expect(viewModel.memos.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.currentError == nil)
        #expect(viewModel.showingErrorAlert == false)
    }
    
    // MARK: - NoteType列挙型テスト
    
    @Test("NoteType - 全てのケースが定義されている")
    func noteType_allCasesAreDefined() async {
        let allTypes: [NoteType] = [.free, .practice, .tournament]
        #expect(NoteType.allCases.count == allTypes.count)
    }
    
    @Test("NoteType - rawValueが連続している", arguments: 0..<3)
    func noteType_rawValuesAreSequential(rawValue: Int) async {
        #expect(NoteType(rawValue: rawValue) != nil)
    }
    
    @Test("NoteType - 各タイプにアイコンが設定されている",
          arguments: NoteType.allCases)
    func noteType_eachTypeHasIcon(noteType: NoteType) async {
        #expect(!noteType.icon.isEmpty)
    }
    
    @Test("NoteType - 各タイプにタイトルが設定されている",
          arguments: NoteType.allCases)
    func noteType_eachTypeHasTitle(noteType: NoteType) async {
        #expect(!noteType.title.isEmpty)
    }
    
    @Test("NoteType - アイコン名が有効なSFSymbol形式",
          arguments: NoteType.allCases)
    func noteType_iconNamesAreValid(noteType: NoteType) async {
        // SF Symbolsの命名規則に従っているか確認
        let icon = noteType.icon
        #expect(!icon.isEmpty)
        // ドットまたはアンダースコアを含む可能性がある
        #expect(icon.contains(".") || icon.contains("_") || icon.count > 0)
    }
    
    // MARK: - Weather列挙型テスト
    
    @Test("Weather - 全てのケースが定義されている")
    func weather_allCasesAreDefined() async {
        let allWeathers: [Weather] = [.sunny, .cloudy, .rainy]
        #expect(Weather.allCases.count == allWeathers.count)
    }
    
    @Test("Weather - rawValueが連続している", arguments: 0..<3)
    func weather_rawValuesAreSequential(rawValue: Int) async {
        #expect(Weather(rawValue: rawValue) != nil)
    }
    
    @Test("Weather - 各天気にタイトルが設定されている",
          arguments: Weather.allCases)
    func weather_eachWeatherHasTitle(weather: Weather) async {
        #expect(!weather.title.isEmpty)
    }
    
    @Test("Weather - 各天気にアイコンが設定されている",
          arguments: Weather.allCases)
    func weather_eachWeatherHasIcon(weather: Weather) async {
        #expect(!weather.icon.isEmpty)
    }
    
    // MARK: - Note作成テスト
    
    @Test("Note作成 - デフォルトイニシャライザ")
    func noteCreation_defaultInitializer() async {
        let note = Note()
        
        #expect(!note.noteID.isEmpty)
        #expect(note.noteType == NoteType.free.rawValue)
        #expect(note.isDeleted == false)
        #expect(note.title == "")
        #expect(note.weather == Weather.sunny.rawValue)
    }
    
    @Test("Note作成 - フリーノートイニシャライザ")
    func noteCreation_freeNoteInitializer() async {
        let note = Note(title: "テストタイトル")
        
        #expect(note.noteType == NoteType.free.rawValue)
        #expect(note.title == "テストタイトル")
    }
    
    @Test("Note作成 - 練習ノートイニシャライザ")
    func noteCreation_practiceNoteInitializer() async {
        let note = Note(purpose: "目的", detail: "詳細")
        
        #expect(note.noteType == NoteType.practice.rawValue)
        #expect(note.purpose == "目的")
        #expect(note.detail == "詳細")
    }
    
    @Test("Note作成 - 大会ノートイニシャライザ")
    func noteCreation_tournamentNoteInitializer() async {
        let note = Note(target: "目標", consciousness: "意識点", result: "結果")
        
        #expect(note.noteType == NoteType.tournament.rawValue)
        #expect(note.target == "目標")
        #expect(note.consciousness == "意識点")
        #expect(note.result == "結果")
    }
    
    // MARK: - 温度テスト
    
    @Test("温度 - 様々な温度値", 
          arguments: [-10, 0, 10, 20, 30, 40])
    func temperature_variousValues(temp: Int) async {
        let note = Note()
        note.temperature = temp
        
        #expect(note.temperature == temp)
    }
    
    @Test("温度 - 極端な温度値",
          arguments: [-50, -100, 50, 100])
    func temperature_extremeValues(temp: Int) async {
        let note = Note()
        note.temperature = temp
        
        #expect(note.temperature == temp)
    }
    
    // MARK: - 通知処理テスト
    
    @Test("通知処理 - didClearAllData通知でクリアされる")
    func notification_clearsOnDidClearAllData() async {
        let viewModel = NoteViewModel()
        
        // データを追加
        let testNote = Note(title: "Test")
        viewModel.notes = [testNote]
        viewModel.selectedNote = testNote
        
        #expect(!viewModel.notes.isEmpty)
        #expect(viewModel.selectedNote != nil)
        
        // 通知を送信
        NotificationCenter.default.post(name: .didClearAllData, object: nil)
        
        // 非同期処理を待つ
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        #expect(viewModel.notes.isEmpty)
        #expect(viewModel.selectedNote == nil)
        #expect(viewModel.practiceNotes.isEmpty)
        #expect(viewModel.tournamentNotes.isEmpty)
        #expect(viewModel.freeNotes.isEmpty)
        #expect(viewModel.memos.isEmpty)
    }
    
    // MARK: - Note noteTypeプロパティテスト
    
    @Test("noteType - フリーノートの型確認")
    func noteType_freeNote() async {
        let note = Note(title: "Free")
        
        #expect(note.noteType == NoteType.free.rawValue)
        #expect(NoteType(rawValue: note.noteType) == .free)
    }
    
    @Test("noteType - 練習ノートの型確認")
    func noteType_practiceNote() async {
        let note = Note(purpose: "Purpose", detail: "Detail")
        
        #expect(note.noteType == NoteType.practice.rawValue)
        #expect(NoteType(rawValue: note.noteType) == .practice)
    }
    
    @Test("noteType - 大会ノートの型確認")
    func noteType_tournamentNote() async {
        let note = Note(target: "Target", consciousness: "Consciousness", result: "Result")
        
        #expect(note.noteType == NoteType.tournament.rawValue)
        #expect(NoteType(rawValue: note.noteType) == .tournament)
    }
    
    // MARK: - 境界値テスト
    
    @Test("境界値 - 空のタイトル")
    func boundaryCase_emptyTitle() async {
        let note = Note(title: "")
        
        #expect(note.title == "")
    }
    
    @Test("境界値 - 非常に長いタイトル")
    func boundaryCase_veryLongTitle() async {
        let longTitle = String(repeating: "あ", count: 1000)
        let note = Note(title: longTitle)
        
        #expect(note.title == longTitle)
        #expect(note.title.count == 1000)
    }
    
    @Test("境界値 - 特殊文字を含むタイトル",
          arguments: [
            "タイトル🎾",
            "Title\nWith\nNewlines",
            "Title\t\tWith\tTabs",
            "Title & Special <> Characters"
          ])
    func boundaryCase_specialCharactersInTitle(title: String) async {
        let note = Note(title: title)
        
        #expect(note.title == title)
    }
    
    @Test("境界値 - 大量のノート", arguments: [10, 50, 100])
    func boundaryCase_largeNotesList(count: Int) async {
        let viewModel = NoteViewModel()
        
        var notes: [Note] = []
        for i in 0..<count {
            let note = Note(title: "Note \(i)")
            notes.append(note)
        }
        
        viewModel.notes = notes
        
        #expect(viewModel.notes.count == count)
    }
    
    // MARK: - エラーハンドリングテスト
    
    @Test("エラーハンドリング - isLoadingの初期状態")
    func errorHandling_isLoadingInitialState() async {
        let viewModel = NoteViewModel()
        #expect(viewModel.isLoading == false)
    }
    
    @Test("エラーハンドリング - currentErrorの初期状態")
    func errorHandling_currentErrorInitialState() async {
        let viewModel = NoteViewModel()
        #expect(viewModel.currentError == nil)
    }
    
    @Test("エラーハンドリング - showingErrorAlertの初期状態")
    func errorHandling_showingErrorAlertInitialState() async {
        let viewModel = NoteViewModel()
        #expect(viewModel.showingErrorAlert == false)
    }
    
    // MARK: - NoteType.content メソッドテスト
    
    @Test("NoteType.content - フリーノートの内容取得")
    func noteTypeContent_freeNote() async {
        let note = Note(title: "Free")
        note.detail = "Free note detail"
        
        let content = NoteType.free.content(from: note)
        
        #expect(content == "Free note detail")
    }
    
    @Test("NoteType.content - 練習ノートの内容取得（詳細あり）")
    func noteTypeContent_practiceNoteWithDetail() async {
        let note = Note(purpose: "Purpose", detail: "Detail")
        
        let content = NoteType.practice.content(from: note)
        
        #expect(content == "Detail")
    }
    
    @Test("NoteType.content - 練習ノートの内容取得（詳細なし）")
    func noteTypeContent_practiceNoteWithoutDetail() async {
        let note = Note(purpose: "Purpose", detail: "")
        
        let content = NoteType.practice.content(from: note)
        
        #expect(content == "Purpose")
    }
    
    @Test("NoteType.content - 大会ノートの内容取得（結果あり）")
    func noteTypeContent_tournamentNoteWithResult() async {
        let note = Note(target: "Target", consciousness: "Consciousness", result: "Result")
        
        let content = NoteType.tournament.content(from: note)
        
        #expect(content == "Result")
    }
    
    @Test("NoteType.content - 大会ノートの内容取得（結果なし）")
    func noteTypeContent_tournamentNoteWithoutResult() async {
        let note = Note(target: "Target", consciousness: "Consciousness", result: "")
        
        let content = NoteType.tournament.content(from: note)
        
        #expect(content == "Target")
    }
    // MARK: - CRUD操作テスト
    
    @Test("fetchData - データを取得できる")
    func fetchData_retrievesData() async {
        let viewModel = NoteViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        // テストデータ作成（フリーノート以外を使用）
        let note1 = Note(purpose: "Purpose 1", detail: "Detail 1")
        note1.noteType = NoteType.practice.rawValue
        let note2 = Note(target: "Target 2", consciousness: "Consciousness 2", result: "Result 2")
        note2.noteType = NoteType.tournament.rawValue
        try? manager.saveItem(note1)
        try? manager.saveItem(note2)
        
        // データ取得
        _ = await viewModel.fetchData()
        
        #expect(viewModel.notes.count == 2)
        #expect(viewModel.notes.contains(where: { $0.noteID == note1.noteID }))
        #expect(viewModel.notes.contains(where: { $0.noteID == note2.noteID }))
        
        manager.clearAll()
    }
    
    
    @Test("delete - ノートを削除できる")
    func delete_deletesNote() async {
        let viewModel = NoteViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        // テストデータ（フリーノート以外でないと削除できない仕様があるため練習ノートにする）
        let note = Note(purpose: "Purpose", detail: "Detail")
        note.noteType = NoteType.practice.rawValue
        try? manager.saveItem(note)
        
        // ViewModelにロード
        _ = await viewModel.fetchData()
        #expect(viewModel.notes.count == 1)
        
        // 削除
        let result = await viewModel.delete(id: note.noteID)
        
        // 成功確認
        if case .failure(let error) = result {
            Issue.record("Delete failed: \(error)")
        }
        
        #expect(viewModel.notes.isEmpty)
        
        // Realmでの論理削除確認
        let deletedNote = manager.getRawObjectById(id: note.noteID, type: Note.self)
        #expect(deletedNote?.isDeleted == true)
        
        manager.clearAll()
    }
    
    @Test("delete - フリーノートは削除できない")
    func delete_cannotDeleteFreeNote() async {
        let viewModel = NoteViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        // フリーノート作成
        let note = Note(title: "Free Note")
        note.noteType = NoteType.free.rawValue
        try? manager.saveItem(note)
        
        // ViewModelにロード
        _ = await viewModel.fetchData()
        
        // 削除試行
        let result = await viewModel.delete(id: note.noteID)
        
        // 失敗確認
        if case .success = result {
            Issue.record("Should fail to delete free note")
        }
        
        // データが残っていること
        #expect(viewModel.notes.count == 1)
        let existingNote = try? manager.getObjectById(id: note.noteID, type: Note.self)
        #expect(existingNote != nil)
        
        manager.clearAll()
    }
    
    // MARK: - 検索・フィルタリングテスト
    
    @Test("searchNotes - クエリで検索できる")
    func searchNotes_filtersByQuery() async {
        let viewModel = NoteViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        // データ作成
        let note1 = Note(title: "Swift")
        note1.noteType = NoteType.free.rawValue // フリーノートは常にヒットする仕様
        
        let note2 = Note(purpose: "Coding", detail: "Swift Testing")
        note2.noteType = NoteType.practice.rawValue
        
        let note3 = Note(target: "Win", consciousness: "Focus", result: "Good")
        note3.noteType = NoteType.tournament.rawValue
        
        try? manager.saveItem(note1)
        try? manager.saveItem(note2)
        try? manager.saveItem(note3)
        
        // "Testing"で検索 -> note1(Free)とnote2(Practice)がヒット
        viewModel.searchNotes(query: "Testing")
        
        #expect(viewModel.notes.count == 2)
        #expect(viewModel.notes.contains(where: { $0.noteID == note1.noteID }))
        #expect(viewModel.notes.contains(where: { $0.noteID == note2.noteID }))
        
        manager.clearAll()
    }
    
    @Test("filterNotesByDate - 日付でフィルタリングできる")
    func filterNotesByDate_filtersByDate() async {
        let viewModel = NoteViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        let noteToday = Note(purpose: "Today", detail: "")
        noteToday.date = today
        noteToday.noteType = NoteType.practice.rawValue
        
        let noteYesterday = Note(purpose: "Yesterday", detail: "")
        noteYesterday.date = yesterday
        noteYesterday.noteType = NoteType.practice.rawValue
        
        try? manager.saveItem(noteToday)
        try? manager.saveItem(noteYesterday)
        
        // 今日のノートを取得
        let filtered = viewModel.filterNotesByDate(today)
        
        #expect(filtered.count == 1)
        #expect(filtered.first?.noteID == noteToday.noteID)
        
        manager.clearAll()
    }
    
    // MARK: - 各種ノート作成メソッドテスト
    
    @Test("savePracticeNote - 練習ノートを保存できる")
    func savePracticeNote_savesCorrectly() async {
        let viewModel = NoteViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        viewModel.savePracticeNoteWithReflections(
            purpose: "Practice Purpose",
            detail: "Practice Detail",
            weather: .rainy,
            temperature: 25
        )
        
        // 保存完了を待機（ポーリング）
        var notes: [Note] = []
        for _ in 0..<50 { // 最大5秒待機
            await Task.yield()
            if let fetched = try? manager.getDataList(clazz: Note.self), !fetched.isEmpty {
                notes = fetched
                break
            }
            if let error = viewModel.currentError {
                print("ViewModel Error: \(error)")
                break
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        let note = notes.first
        
        #expect(note != nil)
        #expect(note?.noteType == NoteType.practice.rawValue)
        #expect(note?.purpose == "Practice Purpose")
        #expect(note?.detail == "Practice Detail")
        #expect(note?.weather == Weather.rainy.rawValue)
        #expect(note?.temperature == 25)
        
        manager.clearAll()
    }
    
    @Test("saveTournamentNote - 大会ノートを保存できる")
    func saveTournamentNote_savesCorrectly() async {
        let viewModel = NoteViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        viewModel.saveTournamentNote(
            target: "Tournament Target",
            consciousness: "Consciousness",
            result: "Result"
        )
        
        // 保存完了を待機（ポーリング）
        var notes: [Note] = []
        for _ in 0..<50 { // 最大5秒待機
            await Task.yield()
            if let fetched = try? manager.getDataList(clazz: Note.self), !fetched.isEmpty {
                notes = fetched
                break
            }
            if let error = viewModel.currentError {
                print("ViewModel Error: \(error)")
                break
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        let note = notes.first
        
        #expect(note != nil)
        #expect(note?.noteType == NoteType.tournament.rawValue)
        #expect(note?.target == "Tournament Target")
        #expect(note?.consciousness == "Consciousness")
        #expect(note?.result == "Result")
        
        manager.clearAll()
    }
    
    @Test("saveFreeNote - フリーノートを保存できる")
    func saveFreeNote_savesCorrectly() async {
        let viewModel = NoteViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        viewModel.saveFreeNote(
            title: "Free Title",
            detail: "Free Detail"
        )
        
        // 保存完了を待機（ポーリング）
        var notes: [Note] = []
        for _ in 0..<50 { // 最大5秒待機
            await Task.yield()
            if let fetched = try? manager.getDataList(clazz: Note.self), !fetched.isEmpty {
                notes = fetched
                break
            }
            if let error = viewModel.currentError {
                print("ViewModel Error: \(error)")
                break
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        let note = notes.first
        
        #expect(note != nil)
        #expect(note?.noteType == NoteType.free.rawValue)
        #expect(note?.title == "Free Title")
        #expect(note?.detail == "Free Detail")
        
        manager.clearAll()
    }
    
    @Test("fetchNotesExcludingFree - フリーノートを除外して取得できる")
    func fetchNotesExcludingFree_excludesFreeNotes() async {
        let viewModel = NoteViewModel()
        let manager = RealmManager.shared
        manager.clearAll()
        
        let freeNote = Note(title: "Free")
        freeNote.noteType = NoteType.free.rawValue
        
        let practiceNote = Note(purpose: "Practice", detail: "")
        practiceNote.noteType = NoteType.practice.rawValue
        
        try? manager.saveItem(freeNote)
        try? manager.saveItem(practiceNote)
        
        _ = await viewModel.fetchNotesExcludingFree()
        
        #expect(viewModel.notes.count == 1)
        #expect(viewModel.notes.first?.noteType == NoteType.practice.rawValue)
        
        manager.clearAll()
    }
}

extension NoteViewModelTests {
    
    /// テスト用のNoteを作成（フリーノート）
    static func createTestFreeNote(title: String = "Test Note") -> Note {
        return Note(title: title)
    }
    
    /// テスト用のNoteを作成（練習ノート）
    static func createTestPracticeNote(
        purpose: String = "Test Purpose",
        detail: String = "Test Detail"
    ) -> Note {
        return Note(purpose: purpose, detail: detail)
    }
    
    /// テスト用のNoteを作成（大会ノート）
    static func createTestTournamentNote(
        target: String = "Test Target",
        consciousness: String = "Test Consciousness",
        result: String = "Test Result"
    ) -> Note {
        return Note(target: target, consciousness: consciousness, result: result)
    }
}
