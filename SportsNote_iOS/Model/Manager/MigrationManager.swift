@preconcurrency import FirebaseFirestore
import Foundation

/// 旧アプリ（UIKit版）のFirebaseデータを新形式に変換するマネージャー
/// 旧コレクション: TaskData, TargetData, FreeNoteData, NoteData
/// 新コレクション: Task + Measures + Memo, Target, Note（free/practice/tournament）
@MainActor
final class MigrationManager {

    static let shared = MigrationManager()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Public

    /// マイグレーションが必要かどうかを判定
    /// - Returns: 未実施の場合は true
    func needsMigration() -> Bool {
        return !UserDefaultsManager.get(key: UserDefaultsManager.Keys.migrationV1Completed, defaultValue: false)
    }

    /// 全データのマイグレーションを実行
    /// 処理順: Task → (Target + FreeNote 並列) → Note
    /// - Throws: Firebase 操作に失敗した場合
    func migrateAll() async throws {
        print("開始: 旧データマイグレーション ----------")

        // 1. Task → TaskData + Measures + Memo（Note変換より先に実行）
        print("OldTask変換開始")
        let oldTaskDocs = try await fetchOldTaskDocuments()
        for doc in oldTaskDocs {
            try await migrateTask(data: doc.data())
            try await markOldTaskDeleted(documentID: doc.documentID)
        }
        print("OldTask変換終了: \(oldTaskDocs.count)件")

        // 2. Target と FreeNote を並列変換（互いに依存なし）
        // getUserID() は @MainActor のため addTask クロージャ外で事前に取得
        let currentUserID = getUserID()
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { [self] in
                print("OldTarget変換開始")
                let docs = try await fetchOldTargetDocuments()
                for doc in docs {
                    try await migrateTarget(data: doc.data())
                    try await markOldTargetDeleted(documentID: doc.documentID)
                }
                print("OldTarget変換終了: \(docs.count)件")
            }
            group.addTask { [self] in
                print("OldFreeNote変換開始")
                if let doc = try await fetchOldFreeNoteDocument() {
                    try await migrateFreeNote(data: doc.data())
                    try await deleteOldFreeNoteDocument(userID: currentUserID)
                    print("OldFreeNote変換終了: 1件")
                } else {
                    print("OldFreeNote変換終了: 0件（データなし）")
                }
            }
            for try await _ in group {}
        }

        // 3. Note → Note（practice/tournament）（Task変換完了後）
        print("OldNote変換開始")
        let oldNoteDocs = try await fetchOldNoteDocuments()
        for doc in oldNoteDocs {
            try await migrateNote(data: doc.data())
            try await markOldNoteDeleted(documentID: doc.documentID)
        }
        print("OldNote変換終了: \(oldNoteDocs.count)件")

        // マイグレーション完了フラグを保存
        UserDefaultsManager.set(key: UserDefaultsManager.Keys.migrationV1Completed, value: true)
        print("終了: 旧データマイグレーション ----------")
    }

    // MARK: - 旧コレクション取得（FirebaseManager.getAllDocuments() は private のため直接アクセス）

    /// 旧コレクション "TaskData" から isDeleted=false のドキュメントを全取得
    private func fetchOldTaskDocuments() async throws -> [QueryDocumentSnapshot] {
        let userID = getUserID()
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("TaskData")
                .whereField("userID", isEqualTo: userID)
                .whereField("isDeleted", isEqualTo: false)
                .getDocuments { snapshot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: snapshot?.documents ?? [])
                    }
                }
        }
    }

    /// 旧コレクション "TargetData" から isDeleted=false のドキュメントを全取得
    private func fetchOldTargetDocuments() async throws -> [QueryDocumentSnapshot] {
        let userID = getUserID()
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("TargetData")
                .whereField("userID", isEqualTo: userID)
                .whereField("isDeleted", isEqualTo: false)
                .getDocuments { snapshot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: snapshot?.documents ?? [])
                    }
                }
        }
    }

    /// 旧コレクション "FreeNoteData" からドキュメントを取得（ドキュメントID = userID）
    private func fetchOldFreeNoteDocument() async throws -> QueryDocumentSnapshot? {
        let userID = getUserID()
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("FreeNoteData")
                .whereField("userID", isEqualTo: userID)
                .getDocuments { snapshot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: snapshot?.documents.first)
                    }
                }
        }
    }

    /// 旧コレクション "NoteData" から isDeleted=false のドキュメントを全取得
    private func fetchOldNoteDocuments() async throws -> [QueryDocumentSnapshot] {
        let userID = getUserID()
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("NoteData")
                .whereField("userID", isEqualTo: userID)
                .whereField("isDeleted", isEqualTo: false)
                .getDocuments { snapshot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: snapshot?.documents ?? [])
                    }
                }
        }
    }

    // MARK: - 変換・Realm + Firebase 保存

    /// 旧課題データを TaskData + Measures + Memo に変換して保存
    /// measuresData: [対策タイトル: [[有効性コメント: ノートID(Int)]]]
    private func migrateTask(data: [String: Any]) async throws {
        guard
            let title = data["taskTitle"] as? String,
            let cause = data["taskCause"] as? String,
            let isAchieve = data["taskAchievement"] as? Bool,
            let isDeleted = data["isDeleted"] as? Bool
        else { return }

        let order = data["order"] as? Int ?? 0
        let userID = getUserID()
        let now = Date()

        // TaskData の作成
        let task = TaskData()
        task.taskID = UUIDGenerator.generateID()
        task.userID = userID
        task.title = title
        task.cause = cause
        task.order = order
        task.isComplete = isAchieve
        task.isDeleted = isDeleted
        task.created_at = now
        task.updated_at = now

        // 未分類グループに割り当て（旧データにグループ概念なし）
        if let groups = try? RealmManager.shared.getDataList(clazz: Group.self),
           let uncategorized = groups.first
        {
            task.groupID = uncategorized.groupID
        } else {
            task.groupID = ""
        }

        try RealmManager.shared.saveItem(task)
        try await FirebaseManager.shared.saveTask(task: task)

        // measuresData から Measures + Memo を生成
        guard let measuresData = data["measuresData"] as? [String: [[String: Int]]] else { return }

        var measuresOrder = 0
        for (measuresTitle, effectivenessArray) in measuresData {
            let measures = Measures()
            measures.measuresID = UUIDGenerator.generateID()
            measures.userID = userID
            measures.taskID = task.taskID
            measures.title = measuresTitle
            measures.order = measuresOrder
            measures.isDeleted = false
            measures.created_at = now
            measures.updated_at = now

            try RealmManager.shared.saveItem(measures)
            try await FirebaseManager.shared.saveMeasures(measures: measures)
            measuresOrder += 1

            // 有効性コメントを Memo に変換
            // effectivenessArray: [ ["コメント文字列": ノートID(Int)], ... ]
            for effectivenessDict in effectivenessArray {
                for (comment, oldNoteIDInt) in effectivenessDict {
                    guard !comment.isEmpty else { continue }

                    let memo = Memo()
                    memo.memoID = UUIDGenerator.generateID()
                    memo.userID = userID
                    memo.measuresID = measures.measuresID
                    // noteID は旧 Int を String に変換して保持（Note 変換時の noteID と整合させる）
                    memo.noteID = oldNoteIDInt == 0 ? "" : String(oldNoteIDInt)
                    memo.detail = comment
                    memo.isDeleted = false
                    memo.created_at = now
                    memo.updated_at = now

                    try RealmManager.shared.saveItem(memo)
                    try await FirebaseManager.shared.saveMemo(memo: memo)
                }
            }
        }
    }

    /// 旧目標データを Target に変換して保存
    /// month == 13 は年間目標を示す旧仕様
    private func migrateTarget(data: [String: Any]) async throws {
        guard
            let year = data["year"] as? Int,
            let month = data["month"] as? Int,
            let detail = data["detail"] as? String,
            let isDeleted = data["isDeleted"] as? Bool
        else { return }

        let userID = getUserID()
        let now = Date()

        let target = Target()
        target.targetID = UUIDGenerator.generateID()
        target.userID = userID
        target.title = detail
        target.year = year
        target.month = month
        target.isYearlyTarget = (month == 13)
        target.isDeleted = isDeleted
        target.created_at = now
        target.updated_at = now

        try RealmManager.shared.saveItem(target)
        try await FirebaseManager.shared.saveTarget(target: target)
    }

    /// 旧フリーノートデータを Note(free) に変換して保存
    /// Realm に既存のフリーノートがあれば内容を上書き、なければ新規作成
    private func migrateFreeNote(data: [String: Any]) async throws {
        guard
            let title = data["title"] as? String,
            let detail = data["detail"] as? String
        else { return }

        let userID = getUserID()
        let now = Date()

        if let existingFreeNote = RealmManager.shared.getFreeNote() {
            // 既存のフリーノートに上書き（managed objectを直接変更するとwriteトランザクション外エラーになるため、
            // 同じnoteIDで新規unmanagedオブジェクトを作成し saveItem(.modified) で上書きする）
            let updatedNote = Note()
            updatedNote.noteID = existingFreeNote.noteID
            updatedNote.userID = existingFreeNote.userID
            updatedNote.noteType = existingFreeNote.noteType
            updatedNote.date = existingFreeNote.date
            updatedNote.isDeleted = existingFreeNote.isDeleted
            updatedNote.created_at = existingFreeNote.created_at
            updatedNote.title = title
            updatedNote.detail = detail
            updatedNote.updated_at = now
            try RealmManager.shared.saveItem(updatedNote)
            try await FirebaseManager.shared.saveNote(note: updatedNote)
        } else {
            // 新規フリーノートを作成
            let note = Note()
            note.noteID = UUIDGenerator.generateID()
            note.userID = userID
            note.noteType = NoteType.free.rawValue
            note.title = title
            note.detail = detail
            note.date = Date()
            note.isDeleted = false
            note.created_at = now
            note.updated_at = now
            try RealmManager.shared.saveItem(note)
            try await FirebaseManager.shared.saveNote(note: note)
        }
    }

    /// 旧ノートデータを Note(practice/tournament) に変換して保存
    /// noteID は旧 Int を String に変換して保持（Memo との紐付けを維持するため）
    private func migrateNote(data: [String: Any]) async throws {
        guard
            let oldNoteIDInt = data["noteID"] as? Int,
            let noteTypeStr = data["noteType"] as? String,
            let year = data["year"] as? Int,
            let month = data["month"] as? Int,
            let day = data["date"] as? Int,
            let weatherStr = data["weather"] as? String,
            let temperature = data["temperature"] as? Int,
            let physicalCondition = data["physicalCondition"] as? String,
            let reflection = data["reflection"] as? String,
            let isDeleted = data["isDeleted"] as? Bool
        else { return }

        let purpose = data["purpose"] as? String ?? ""
        let detail = data["detail"] as? String ?? ""
        let target = data["target"] as? String ?? ""
        let consciousness = data["consciousness"] as? String ?? ""
        let result = data["result"] as? String ?? ""

        let userID = getUserID()
        let now = Date()

        // noteType の変換
        let noteType: Int
        switch noteTypeStr {
        case "練習記録": noteType = NoteType.practice.rawValue
        case "大会記録": noteType = NoteType.tournament.rawValue
        default:         noteType = NoteType.practice.rawValue
        }

        let note = Note()
        // noteID: メモとの紐付けのため旧 Int を String に変換して保持
        note.noteID = String(oldNoteIDInt)
        note.userID = userID
        note.noteType = noteType
        note.date = makeDate(year: year, month: month, day: day)
        note.weather = convertWeather(from: weatherStr)
        note.temperature = temperature
        note.condition = physicalCondition
        note.purpose = purpose
        note.detail = detail
        note.target = target
        note.consciousness = consciousness
        note.result = result
        note.reflection = reflection
        note.title = ""
        note.isDeleted = isDeleted
        note.created_at = now
        note.updated_at = now

        try RealmManager.shared.saveItem(note)
        try await FirebaseManager.shared.saveNote(note: note)
    }

    // MARK: - 旧データ削除

    /// 旧 TaskData ドキュメントを論理削除（isDeleted = true）
    private func markOldTaskDeleted(documentID: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection("TaskData").document(documentID)
                .updateData(["isDeleted": true]) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
        }
    }

    /// 旧 TargetData ドキュメントを論理削除（isDeleted = true）
    private func markOldTargetDeleted(documentID: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection("TargetData").document(documentID)
                .updateData(["isDeleted": true]) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
        }
    }

    /// 旧 FreeNoteData ドキュメントを物理削除
    private func deleteOldFreeNoteDocument(userID: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection("FreeNoteData").document(userID)
                .delete { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
        }
    }

    /// 旧 NoteData ドキュメントを論理削除（isDeleted = true）
    private func markOldNoteDeleted(documentID: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection("NoteData").document(documentID)
                .updateData(["isDeleted": true]) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
        }
    }

    // MARK: - ヘルパー

    private func getUserID() -> String {
        return UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: "")
    }

    /// 年・月・日の整数から Date 型を生成
    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }

    /// 旧天気文字列（"晴れ"/"くもり"/"雨"）を Weather enum の rawValue に変換
    private func convertWeather(from weatherString: String) -> Int {
        switch weatherString {
        case "晴れ":   return Weather.sunny.rawValue
        case "くもり": return Weather.cloudy.rawValue
        case "雨":     return Weather.rainy.rawValue
        default:       return Weather.sunny.rawValue
        }
    }
}
