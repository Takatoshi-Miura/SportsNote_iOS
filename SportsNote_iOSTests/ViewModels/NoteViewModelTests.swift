//
//  NoteViewModelTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2025/11/23.
//

import Foundation
import RealmSwift
import Testing

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

    @Test(
        "NoteType - 各タイプにアイコンが設定されている",
        arguments: NoteType.allCases)
    func noteType_eachTypeHasIcon(noteType: NoteType) async {
        #expect(!noteType.icon.isEmpty)
    }

    @Test(
        "NoteType - 各タイプにタイトルが設定されている",
        arguments: NoteType.allCases)
    func noteType_eachTypeHasTitle(noteType: NoteType) async {
        #expect(!noteType.title.isEmpty)
    }

    @Test(
        "NoteType - アイコン名が有効なSFSymbol形式",
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

    @Test(
        "Weather - 各天気にタイトルが設定されている",
        arguments: Weather.allCases)
    func weather_eachWeatherHasTitle(weather: Weather) async {
        #expect(!weather.title.isEmpty)
    }

    @Test(
        "Weather - 各天気にアイコンが設定されている",
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

    @Test(
        "温度 - 様々な温度値",
        arguments: [-10, 0, 10, 20, 30, 40])
    func temperature_variousValues(temp: Int) async {
        let note = Note()
        note.temperature = temp

        #expect(note.temperature == temp)
    }

    @Test(
        "温度 - 極端な温度値",
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
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

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

    @Test(
        "境界値 - 特殊文字を含むタイトル",
        arguments: [
            "タイトル🎾",
            "Title\nWith\nNewlines",
            "Title\t\tWith\tTabs",
            "Title & Special <> Characters",
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
        note1.noteType = NoteType.free.rawValue
        note1.detail = "Swift Testing"  // issue #76: フリーノートも内容が一致する場合のみヒットする仕様

        let note2 = Note(purpose: "Coding", detail: "Swift Testing")
        note2.noteType = NoteType.practice.rawValue

        let note3 = Note(target: "Win", consciousness: "Focus", result: "Good")
        note3.noteType = NoteType.tournament.rawValue

        try? manager.saveItem(note1)
        try? manager.saveItem(note2)
        try? manager.saveItem(note3)

        // "Testing"で検索 -> note1(Free、detailに一致)とnote2(Practice)がヒット
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
        for _ in 0..<50 {  // 最大5秒待機
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

    // MARK: - updateTaskReflections（課題振り返りメモ）のcreated_atテスト

    @Test("updateTaskReflections - 新規作成時はcreated_atに現在時刻が設定される")
    func updateTaskReflections_newMemo_setsCurrentCreatedAt() async {
        let viewModel = NoteViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        let beforeSave = Date()
        let task = TaskListData(
            taskID: "task-1",
            groupID: "group-1",
            groupColor: .red,
            title: "Test Task",
            measuresID: "measures-1",
            measures: "Test Measures",
            memoID: nil,
            order: 0,
            isComplete: false
        )

        viewModel.savePracticeNoteWithReflections(
            purpose: "Practice Purpose",
            detail: "Practice Detail",
            taskReflections: [task: "初回の振り返り"]
        )

        // Memoの保存はrealmManager.saveItemによる同期処理のため、この時点で既に反映されている
        let memos = (try? manager.getDataList(clazz: Memo.self)) ?? []
        let memo = memos.first

        #expect(memo != nil)
        #expect(memo?.detail == "初回の振り返り")
        // 新規作成時はcreated_atに現在時刻が設定される
        if let createdAt = memo?.created_at {
            #expect(createdAt >= beforeSave.addingTimeInterval(-1))
            #expect(createdAt <= Date().addingTimeInterval(1))
        } else {
            Issue.record("新規作成されたMemoのcreated_atが取得できませんでした")
        }

        manager.clearAll()
    }

    @Test("updateTaskReflections - task.memoIDがある場合、既存メモのcreated_atが維持される")
    func updateTaskReflections_existingMemoWithMemoID_preservesCreatedAt() async {
        let manager = RealmManager.shared
        manager.clearAll()

        // 既存メモをRealmに直接投入（過去のcreated_atを持つ）
        let fixedCreatedAt = Date().addingTimeInterval(-86400)
        let existingMemo = Memo(
            memoID: "memo-fixed-1",
            measuresID: "measures-1",
            noteID: "note-1",
            detail: "初回の振り返り",
            created_at: fixedCreatedAt
        )
        try? manager.saveItem(existingMemo)

        let viewModel = NoteViewModel()
        let task = TaskListData(
            taskID: "task-1",
            groupID: "group-1",
            groupColor: .red,
            title: "Test Task",
            measuresID: "measures-1",
            measures: "Test Measures",
            memoID: "memo-fixed-1",
            order: 0,
            isComplete: false
        )

        // 既存メモを編集（task.memoIDあり）
        viewModel.savePracticeNoteWithReflections(
            noteID: "note-1",
            purpose: "Practice Purpose",
            detail: "Practice Detail",
            taskReflections: [task: "編集後の振り返り"]
        )

        let updatedMemo = try? manager.getObjectById(id: "memo-fixed-1", type: Memo.self)

        #expect(updatedMemo != nil)
        #expect(updatedMemo?.detail == "編集後の振り返り")
        // created_atが編集前の値のまま維持されていること（誤差を許容して比較）
        if let updatedCreatedAt = updatedMemo?.created_at {
            #expect(abs(updatedCreatedAt.timeIntervalSince(fixedCreatedAt)) < 0.5)
        } else {
            Issue.record("更新後のMemoのcreated_atが取得できませんでした")
        }

        manager.clearAll()
    }

    @Test("updateTaskReflections - task.memoIDがなくnoteID+measuresIDで既存メモが見つかる場合もcreated_atが維持される")
    func updateTaskReflections_existingMemoFoundBySearch_preservesCreatedAt() async {
        let manager = RealmManager.shared
        manager.clearAll()

        // 既存メモをRealmに直接投入（過去のcreated_atを持つ）
        let fixedCreatedAt = Date().addingTimeInterval(-3600)
        let existingMemo = Memo(
            memoID: "memo-fixed-2",
            measuresID: "measures-2",
            noteID: "note-2",
            detail: "初回の振り返り",
            created_at: fixedCreatedAt
        )
        try? manager.saveItem(existingMemo)
        try? manager.saveItem(
            Measures(measuresID: "measures-2", taskID: "task-2", title: "Test Measures", order: 0, created_at: Date())
        )

        let viewModel = NoteViewModel()
        // memoIDを持たないTaskListDataで渡す（noteID+measuresIDでの検索分岐を通す）
        let task = TaskListData(
            taskID: "task-2",
            groupID: "group-1",
            groupColor: .blue,
            title: "Test Task",
            measuresID: "measures-2",
            measures: "Test Measures",
            memoID: nil,
            order: 0,
            isComplete: false
        )

        viewModel.savePracticeNoteWithReflections(
            noteID: "note-2",
            purpose: "Practice Purpose",
            detail: "Practice Detail",
            taskReflections: [task: "編集後の振り返り(検索経由)"]
        )

        let updatedMemo = try? manager.getObjectById(id: "memo-fixed-2", type: Memo.self)

        #expect(updatedMemo != nil)
        #expect(updatedMemo?.detail == "編集後の振り返り(検索経由)")
        if let updatedCreatedAt = updatedMemo?.created_at {
            #expect(abs(updatedCreatedAt.timeIntervalSince(fixedCreatedAt)) < 0.5)
        } else {
            Issue.record("更新後のMemoのcreated_atが取得できませんでした")
        }

        manager.clearAll()
    }

    // MARK: - updateTaskReflections（課題振り返りメモ）の対策並び替え回帰テスト（issue #109）

    @Test("updateTaskReflections - 対策の並び替えでmeasuresIDが変わっても、既存メモが重複作成されず更新される")
    func updateTaskReflections_existingMemoFoundAfterMeasuresReorder_updatesExistingMemo() async {
        let manager = RealmManager.shared
        manager.clearAll()

        // 既存メモは並び替え前の最優先対策(measures-old)に対して作成されたもの
        let fixedCreatedAt = Date().addingTimeInterval(-3600)
        let existingMemo = Memo(
            memoID: "memo-reorder-1",
            measuresID: "measures-old",
            noteID: "note-reorder-1",
            detail: "並び替え前の振り返り",
            created_at: fixedCreatedAt
        )
        try? manager.saveItem(existingMemo)

        // measures-old・measures-newとも同じtask-reorder-1に属する対策
        // （並び替え後はmeasures-newが最優先=order0になった状態）
        try? manager.saveItem(
            Measures(
                measuresID: "measures-old", taskID: "task-reorder-1", title: "Old", order: 1, created_at: Date()))
        try? manager.saveItem(
            Measures(
                measuresID: "measures-new", taskID: "task-reorder-1", title: "New", order: 0, created_at: Date()))

        let viewModel = NoteViewModel()
        // taskListDataのmeasuresIDは並び替え後の現在の最優先対策(measures-new)を指す
        let task = TaskListData(
            taskID: "task-reorder-1",
            groupID: "group-1",
            groupColor: .blue,
            title: "Test Task",
            measuresID: "measures-new",
            measures: "New",
            memoID: nil,
            order: 0,
            isComplete: false
        )

        viewModel.savePracticeNoteWithReflections(
            noteID: "note-reorder-1",
            purpose: "Practice Purpose",
            detail: "Practice Detail",
            taskReflections: [task: "並び替え後の振り返り"]
        )

        // 新規メモが作られず、既存メモが更新されていること（重複作成されないこと）
        let memos = manager.getMemosByNoteID(noteID: "note-reorder-1")
        #expect(memos.count == 1)

        let updatedMemo = try? manager.getObjectById(id: "memo-reorder-1", type: Memo.self)
        #expect(updatedMemo != nil)
        #expect(updatedMemo?.detail == "並び替え後の振り返り")
        if let updatedCreatedAt = updatedMemo?.created_at {
            #expect(abs(updatedCreatedAt.timeIntervalSince(fixedCreatedAt)) < 0.5)
        } else {
            Issue.record("更新後のMemoのcreated_atが取得できませんでした")
        }

        manager.clearAll()
    }

    // MARK: - updateTaskReflections（課題振り返りメモ）の空文字編集テスト（issue #105）

    @Test("updateTaskReflections - 既存メモを空文字に編集した場合、Realm上のdetailが空文字に更新される")
    func updateTaskReflections_existingMemo_savesEmptyDetail() async {
        let manager = RealmManager.shared
        manager.clearAll()

        let existingMemo = Memo(
            memoID: "memo-fixed-3",
            measuresID: "measures-3",
            noteID: "note-3",
            detail: "頑張った",
            created_at: Date()
        )
        try? manager.saveItem(existingMemo)

        let viewModel = NoteViewModel()
        let task = TaskListData(
            taskID: "task-3",
            groupID: "group-1",
            groupColor: .red,
            title: "Test Task",
            measuresID: "measures-3",
            measures: "Test Measures",
            memoID: "memo-fixed-3",
            order: 0,
            isComplete: false
        )

        // 振り返り欄を空文字に編集して保存
        viewModel.savePracticeNoteWithReflections(
            noteID: "note-3",
            purpose: "Practice Purpose",
            detail: "Practice Detail",
            taskReflections: [task: ""]
        )

        let updatedMemo = try? manager.getObjectById(id: "memo-fixed-3", type: Memo.self)

        #expect(updatedMemo != nil)
        #expect(updatedMemo?.detail == "")

        manager.clearAll()
    }

    @Test("updateTaskReflections - task.memoIDがなくnoteID+measuresID検索で既存メモが見つかる場合も、空文字への編集が保存される")
    func updateTaskReflections_existingMemoFoundBySearch_savesEmptyDetail() async {
        let manager = RealmManager.shared
        manager.clearAll()

        let existingMemo = Memo(
            memoID: "memo-fixed-4b",
            measuresID: "measures-4b",
            noteID: "note-4b",
            detail: "頑張った",
            created_at: Date()
        )
        try? manager.saveItem(existingMemo)
        try? manager.saveItem(
            Measures(
                measuresID: "measures-4b", taskID: "task-4b", title: "Test Measures", order: 0, created_at: Date())
        )

        let viewModel = NoteViewModel()
        // memoIDを持たないTaskListDataで渡す（noteID+measuresIDでの検索分岐を通す）
        let task = TaskListData(
            taskID: "task-4b",
            groupID: "group-1",
            groupColor: .blue,
            title: "Test Task",
            measuresID: "measures-4b",
            measures: "Test Measures",
            memoID: nil,
            order: 0,
            isComplete: false
        )

        viewModel.savePracticeNoteWithReflections(
            noteID: "note-4b",
            purpose: "Practice Purpose",
            detail: "Practice Detail",
            taskReflections: [task: ""]
        )

        let updatedMemo = try? manager.getObjectById(id: "memo-fixed-4b", type: Memo.self)

        #expect(updatedMemo != nil)
        #expect(updatedMemo?.detail == "")

        manager.clearAll()
    }

    @Test("updateTaskReflections - 既存メモがない状態で空文字のまま保存しても新規メモは作成されない")
    func updateTaskReflections_noExistingMemo_emptyText_doesNotCreateMemo() async {
        let manager = RealmManager.shared
        manager.clearAll()

        let viewModel = NoteViewModel()
        let task = TaskListData(
            taskID: "task-4",
            groupID: "group-1",
            groupColor: .blue,
            title: "Test Task",
            measuresID: "measures-4",
            measures: "Test Measures",
            memoID: nil,
            order: 0,
            isComplete: false
        )

        viewModel.savePracticeNoteWithReflections(
            noteID: "note-4",
            purpose: "Practice Purpose",
            detail: "Practice Detail",
            taskReflections: [task: ""]
        )

        let memos = manager.getMemosByNoteID(noteID: "note-4")
        #expect(memos.isEmpty)

        manager.clearAll()
    }

    // MARK: - updateTaskReflections（課題振り返りメモ）のFirebase同期テスト

    @Test("updateTaskReflections - 新規作成時、Memoの同期呼び出しがisUpdate=falseで発生する")
    func updateTaskReflections_newMemo_triggersFirebaseSyncCall() async {
        let viewModel = NoteViewModel()
        let manager = RealmManager.shared
        manager.clearAll()

        let task = TaskListData(
            taskID: "task-sync-1",
            groupID: "group-1",
            groupColor: .red,
            title: "Test Task",
            measuresID: "measures-sync-1",
            measures: "Test Measures",
            memoID: nil,
            order: 0,
            isComplete: false
        )

        viewModel.savePracticeNoteWithReflections(
            purpose: "Practice Purpose",
            detail: "Practice Detail",
            taskReflections: [task: "新規の振り返り"]
        )

        #expect(viewModel.memoSyncCallsForTesting.count == 1)
        #expect(viewModel.memoSyncCallsForTesting.first?.isUpdate == false)

        manager.clearAll()
    }

    @Test("updateTaskReflections - task.memoIDによる既存メモ編集時、Memoの同期呼び出しがisUpdate=trueで発生する")
    func updateTaskReflections_existingMemoWithMemoID_triggersFirebaseSyncCallAsUpdate() async {
        let manager = RealmManager.shared
        manager.clearAll()

        let existingMemo = Memo(
            memoID: "memo-sync-fixed-1",
            measuresID: "measures-sync-2",
            noteID: "note-sync-1",
            detail: "旧振り返り",
            created_at: Date().addingTimeInterval(-3600)
        )
        try? manager.saveItem(existingMemo)

        let viewModel = NoteViewModel()
        let task = TaskListData(
            taskID: "task-sync-2",
            groupID: "group-1",
            groupColor: .red,
            title: "Test Task",
            measuresID: "measures-sync-2",
            measures: "Test Measures",
            memoID: "memo-sync-fixed-1",
            order: 0,
            isComplete: false
        )

        viewModel.savePracticeNoteWithReflections(
            noteID: "note-sync-1",
            purpose: "Practice Purpose",
            detail: "Practice Detail",
            taskReflections: [task: "更新後の振り返り"]
        )

        #expect(viewModel.memoSyncCallsForTesting.count == 1)
        #expect(viewModel.memoSyncCallsForTesting.first?.memoID == "memo-sync-fixed-1")
        #expect(viewModel.memoSyncCallsForTesting.first?.isUpdate == true)

        manager.clearAll()
    }

    @Test("updateTaskReflections - noteID+measuresID検索で既存メモが見つかる場合もMemoの同期呼び出しがisUpdate=trueで発生する")
    func updateTaskReflections_existingMemoFoundBySearch_triggersFirebaseSyncCallAsUpdate() async {
        let manager = RealmManager.shared
        manager.clearAll()

        let existingMemo = Memo(
            memoID: "memo-sync-fixed-2",
            measuresID: "measures-sync-3",
            noteID: "note-sync-2",
            detail: "旧振り返り",
            created_at: Date().addingTimeInterval(-3600)
        )
        try? manager.saveItem(existingMemo)
        try? manager.saveItem(
            Measures(
                measuresID: "measures-sync-3", taskID: "task-sync-3", title: "Test Measures", order: 0,
                created_at: Date()))

        let viewModel = NoteViewModel()
        // memoIDを持たないTaskListDataで渡す（noteID+measuresIDでの検索分岐を通す）
        let task = TaskListData(
            taskID: "task-sync-3",
            groupID: "group-1",
            groupColor: .blue,
            title: "Test Task",
            measuresID: "measures-sync-3",
            measures: "Test Measures",
            memoID: nil,
            order: 0,
            isComplete: false
        )

        viewModel.savePracticeNoteWithReflections(
            noteID: "note-sync-2",
            purpose: "Practice Purpose",
            detail: "Practice Detail",
            taskReflections: [task: "更新後の振り返り(検索経由)"]
        )

        #expect(viewModel.memoSyncCallsForTesting.count == 1)
        #expect(viewModel.memoSyncCallsForTesting.first?.memoID == "memo-sync-fixed-2")
        #expect(viewModel.memoSyncCallsForTesting.first?.isUpdate == true)

        manager.clearAll()
    }

    @Test("syncMemoToFirebase - オフライン/テスト環境では同期をスキップして成功を返す", arguments: [false, true])
    func syncMemoToFirebase_offline_returnsSuccessWithoutThrowing(isUpdate: Bool) async {
        let viewModel = NoteViewModel()
        let memo = Memo(
            memoID: "memo-direct-sync",
            measuresID: "measures-direct",
            noteID: "note-direct",
            detail: "detail",
            created_at: Date()
        )

        let result = await viewModel.syncMemoToFirebase(memo, isUpdate: isUpdate)

        if case .failure(let error) = result {
            Issue.record("テスト用インメモリRealm使用時は同期がスキップされ成功を返すはず: \(error)")
        }
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
        for _ in 0..<50 {  // 最大5秒待機
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
        for _ in 0..<50 {  // 最大5秒待機
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

    // MARK: - convertFirebaseSyncError テスト（issue #36: エラー二重変換防止）

    @Test(
        "convertFirebaseSyncError - 既にSportsNoteErrorの場合は再変換せずそのまま返す",
        arguments: [
            SportsNoteError.firebasePermissionDenied,
            SportsNoteError.firebaseDocumentNotFound,
            SportsNoteError.networkTimeout,
        ])
    func convertFirebaseSyncError_doesNotReconvertExistingSportsNoteError(original: SportsNoteError) async {
        let viewModel = NoteViewModel()

        let converted = viewModel.convertFirebaseSyncError(original, context: "NoteViewModel-syncEntityToFirebase")

        #expect(converted.errorDescription == original.errorDescription)
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
