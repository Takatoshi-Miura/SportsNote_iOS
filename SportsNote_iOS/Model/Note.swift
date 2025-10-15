import RealmSwift
import SwiftUI
import UIKit

/// ノート
class Note: Object {
    @Persisted(primaryKey: true) var noteID: String
    @Persisted var userID: String
    @Persisted var noteType: Int
    @Persisted var isDeleted: Bool
    @Persisted var created_at: Date
    @Persisted var updated_at: Date

    // フリーノート
    @Persisted var title: String

    // 練習・大会共通
    @Persisted var date: Date
    @Persisted var weather: Int
    @Persisted var temperature: Int
    @Persisted var condition: String
    @Persisted var reflection: String

    // 練習ノート
    @Persisted var purpose: String
    @Persisted var detail: String

    // 大会ノート
    @Persisted var target: String
    @Persisted var consciousness: String
    @Persisted var result: String

    /// デフォルトイニシャライザ
    override init() {
        super.init()
        self.noteID = UUIDGenerator.generateID()
        self.noteType = NoteType.free.rawValue
        self.isDeleted = false
        self.created_at = Date()
        self.updated_at = Date()
        self.title = ""
        self.date = Date()
        self.weather = Weather.sunny.rawValue
        self.temperature = 0
        self.condition = ""
        self.reflection = ""
        self.purpose = ""
        self.detail = ""
        self.target = ""
        self.consciousness = ""
        self.result = ""

        // UserDefaultsから同期的に値を取得
        if let userID = UserDefaults.standard.string(forKey: "userID") {
            self.userID = userID
        } else {
            self.userID = ""
        }
    }

    /// フリーノートのイニシャライザ
    convenience init(title: String) {
        self.init()
        self.noteType = NoteType.free.rawValue
        self.title = title
    }

    /// 練習ノートのイニシャライザ
    convenience init(purpose: String, detail: String) {
        self.init()
        self.noteType = NoteType.practice.rawValue
        self.purpose = purpose
        self.detail = detail
    }

    /// 大会ノートのイニシャライザ
    convenience init(target: String, consciousness: String, result: String) {
        self.init()
        self.noteType = NoteType.tournament.rawValue
        self.target = target
        self.consciousness = consciousness
        self.result = result
    }

    override static func primaryKey() -> String? {
        return "noteID"
    }
}

/// ノート一覧表示用
struct NoteListItem {
    let noteID: String
    let noteType: Int
    let date: Date
    let backGroundColor: UIColor
    let title: String
    let subTitle: String
}

/// 練習ノート詳細画面表示用
struct PracticeNote {
    let noteID: String
    let date: Date
    let weather: Int
    let temperature: Int
    let condition: String
    let purpose: String
    let detail: String
    let reflection: String
    let taskReflections: [TaskListData]
    let created_at: Date
    let updated_at: Date
}

/// ノート種別
enum NoteType: Int, CaseIterable {
    case free
    case practice
    case tournament

    var icon: String {
        switch self {
        case .free: return "pin.fill"
        case .practice: return "figure.run"
        case .tournament: return "trophy"
        }
    }

    var color: Color {
        switch self {
        case .free: return .blue
        case .practice: return .green
        case .tournament: return .orange
        }
    }

    var title: String {
        switch self {
        case .free: return LocalizedStrings.freeNote
        case .practice: return LocalizedStrings.practiceNote
        case .tournament: return LocalizedStrings.tournamentNote
        }
    }

    func displayTitle(from note: Note) -> String {
        if self == .free && !note.title.isEmpty {
            return note.title
        }
        return title
    }

    func content(from note: Note) -> String {
        switch self {
        case .free:
            return note.detail
        case .practice:
            return note.detail.isEmpty ? note.purpose : note.detail
        case .tournament:
            return note.result.isEmpty ? note.target : note.result
        }
    }

    @MainActor
    @ViewBuilder
    func destinationView(noteID: String) -> some View {
        switch self {
        case .free:
            FreeNoteView(noteID: noteID)
        case .practice:
            PracticeNoteView(noteID: noteID)
        case .tournament:
            TournamentNoteView(noteID: noteID)
        }
    }
}

/// 天気
enum Weather: Int, CaseIterable {
    case sunny
    case cloudy
    case rainy

    var title: String {
        switch self {
        case .sunny: return LocalizedStrings.sunny
        case .cloudy: return LocalizedStrings.cloudy
        case .rainy: return LocalizedStrings.rainy
        }
    }

    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        }
    }
}
