@preconcurrency import FirebaseFirestore
import Foundation

/// 旧アプリ（UIKit版）のFirebaseデータを新形式に変換するマネージャー
/// 旧コレクション: TaskData, TargetData, FreeNoteData, NoteData
/// 新コレクション: Task + Measures + Memo, Target, Note（free/practice/tournament）
@MainActor
final class MigrationManager {

    static let shared = MigrationManager()
    private let db = Firestore.firestore()
    private let stepRunner = MigrationStepRunner()

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
        let oldTaskDocs = try await fetchOldDocuments(collection: "TaskData")
        for doc in oldTaskDocs {
            try await stepRunner.run(
                entity: "Task",
                documentID: doc.documentID,
                migrate: { try await self.migrateTask(documentID: doc.documentID, data: doc.data()) },
                markDeleted: {
                    try await self.markOldDocumentDeleted(collection: "TaskData", documentID: doc.documentID)
                }
            )
        }
        print("OldTask変換終了: \(oldTaskDocs.count)件")

        // 2. Target と FreeNote を並列変換（互いに依存なし）
        // getUserID() は @MainActor のため addTask クロージャ外で事前に取得
        let currentUserID = getUserID()
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { [self] in
                print("OldTarget変換開始")
                let docs = try await fetchOldDocuments(collection: "TargetData")
                for doc in docs {
                    try await stepRunner.run(
                        entity: "Target",
                        documentID: doc.documentID,
                        migrate: { try await self.migrateTarget(documentID: doc.documentID, data: doc.data()) },
                        markDeleted: {
                            try await self.markOldDocumentDeleted(collection: "TargetData", documentID: doc.documentID)
                        }
                    )
                }
                print("OldTarget変換終了: \(docs.count)件")
            }
            group.addTask { [self] in
                print("OldFreeNote変換開始")
                if let doc = try await fetchOldFreeNoteDocument() {
                    try await stepRunner.run(
                        entity: "FreeNote",
                        documentID: doc.documentID,
                        migrate: { try await self.migrateFreeNote(documentID: doc.documentID, data: doc.data()) },
                        markDeleted: { try await self.deleteOldFreeNoteDocument(userID: currentUserID) }
                    )
                    print("OldFreeNote変換終了: 1件")
                } else {
                    print("OldFreeNote変換終了: 0件（データなし）")
                }
            }
            for try await _ in group {}
        }

        // 3. Note → Note（practice/tournament）（Task変換完了後）
        print("OldNote変換開始")
        let oldNoteDocs = try await fetchOldDocuments(collection: "NoteData")
        for doc in oldNoteDocs {
            try await stepRunner.run(
                entity: "Note",
                documentID: doc.documentID,
                migrate: { try await self.migrateNote(documentID: doc.documentID, data: doc.data()) },
                markDeleted: {
                    try await self.markOldDocumentDeleted(collection: "NoteData", documentID: doc.documentID)
                }
            )
        }
        print("OldNote変換終了: \(oldNoteDocs.count)件")

        // マイグレーション完了フラグを保存
        UserDefaultsManager.set(key: UserDefaultsManager.Keys.migrationV1Completed, value: true)
        print("終了: 旧データマイグレーション ----------")
    }

    // MARK: - 旧コレクション取得（FirebaseManager.getAllDocuments() は private のため直接アクセス）

    /// 指定した旧コレクションから isDeleted=false のドキュメントを全取得
    /// - Parameter collection: 対象コレクション名（"TaskData" / "TargetData" / "NoteData"）
    private func fetchOldDocuments(collection: String) async throws -> [QueryDocumentSnapshot] {
        let userID = getUserID()
        return try await withFirestoreQueryContinuation { completion in
            db.collection(collection)
                .whereField("userID", isEqualTo: userID)
                .whereField("isDeleted", isEqualTo: false)
                .getDocuments(completion: completion)
        }
    }

    /// 旧コレクション "FreeNoteData" からドキュメントを取得（ドキュメントID = userID）
    /// isDeleted フィルタを持たず単一ドキュメントを返す点で fetchOldDocuments(collection:) とは構造が異なるため対象外
    private func fetchOldFreeNoteDocument() async throws -> QueryDocumentSnapshot? {
        let userID = getUserID()
        let documents = try await withFirestoreQueryContinuation { completion in
            db.collection("FreeNoteData")
                .whereField("userID", isEqualTo: userID)
                .getDocuments(completion: completion)
        }
        return documents.first
    }

    // MARK: - 変換・Realm + Firebase 保存

    /// 未分類グループ（タイトルが「未分類」と一致するグループ）のIDを取得する。
    /// 該当グループがRealmに存在しない場合は新規作成して保存する。
    /// - Note: RealmManager経由のローカルDB操作のみで完結しFirebaseに依存しないため`static func`として定義する。
    ///   Swiftのstatic funcはインスタンスの`init()`（`Firestore.firestore()`呼び出し）を経由しないため、
    ///   Firebase未設定のテスト環境でも`MigrationManager.shared`をインスタンス化せずに直接検証できる（issue #73）。
    ///   `groups.first`（orderが最小のグループ）で判定すると、グループの並び替え後に
    ///   意図しない別グループを「未分類」と誤判定してしまうため、タイトル一致で判定する（issue #56）。
    /// - Parameter userID: 新規作成時にGroupへ設定するuserID（呼び出し元で解決済みの値を渡す）
    /// - Returns: 既存または新規作成した未分類グループのgroupID
    /// - Throws: RealmManagerの取得・保存に失敗した場合
    static func resolveUncategorizedGroupID(userID: String) throws -> String {
        let groups = try RealmManager.shared.getDataList(clazz: Group.self)
        if let existing = groups.first(where: { $0.title == LocalizedStrings.uncategorized }) {
            return existing.groupID
        }

        // InitializationManager.createUncategorizedGroup() と同等のロジック（issue #73）
        let group = Group()
        group.groupID = UUIDGenerator.generateID()
        group.title = LocalizedStrings.uncategorized
        group.color = GroupColor.gray.rawValue
        group.userID = userID
        group.created_at = Date()
        group.updated_at = Date()

        try RealmManager.shared.saveItem(group)
        return group.groupID
    }

    /// 旧課題データを TaskData + Measures + Memo に変換して保存
    /// measuresData: [対策タイトル: [[有効性コメント: ノートID(Int)]]]
    private func migrateTask(documentID: String, data: [String: Any]) async throws {
        guard
            let title = data["taskTitle"] as? String,
            let cause = data["taskCause"] as? String,
            let isAchieve = data["taskAchievement"] as? Bool,
            let isDeleted = data["isDeleted"] as? Bool
        else { throw MigrationError.invalidData(entity: "Task", documentID: documentID) }

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
        // タイトル一致で判定し（issue #56）、Group が0件の場合は空文字にフォールバックせずその場で作成する（issue #73）
        task.groupID = try MigrationManager.resolveUncategorizedGroupID(userID: userID)

        try RealmManager.shared.saveItem(task)
        try await FirebaseManager.shared.saveTask(task: task)

        // measuresData から Measures + Memo を生成
        guard let measuresData = data["measuresData"] as? [String: [[String: Int]]] else { return }

        // measuresPriority（旧データの最優先対策タイトル）を order=0 に固定し、
        // 残りは決定的な順序（sorted）で採番する（Dictionary列挙順の不定性に依存しないため。issue #71）
        let measuresPriority = data["measuresPriority"] as? String
        let orderedTitles = MeasuresOrderResolver.resolveOrder(
            measuresTitles: Array(measuresData.keys),
            measuresPriority: measuresPriority
        )

        // 対策ごとの効果コメントを収集する（Memoへの変換は課題全体でノートIDごとにマージしてから行う。issue #184）
        var effectivenessByMeasures: [MigrationMemoMerger.MeasuresEffectiveness] = []

        for (measuresOrder, measuresTitle) in orderedTitles.enumerated() {
            guard let effectivenessArray = measuresData[measuresTitle] else { continue }

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

            // effectivenessArray: [ ["コメント文字列": ノートID(Int)], ... ]
            var comments: [(comment: String, oldNoteID: Int)] = []
            for effectivenessDict in effectivenessArray {
                for (comment, oldNoteIDInt) in effectivenessDict {
                    comments.append((comment: comment, oldNoteID: oldNoteIDInt))
                }
            }
            effectivenessByMeasures.append(
                MigrationMemoMerger.MeasuresEffectiveness(measuresID: measures.measuresID, comments: comments))
        }

        // 旧アプリは効果コメントを対策単位で保持していたため、同一ノートで複数対策にコメントが
        // 付いていた場合、素直に変換すると同一taskID・同一noteIDだが異なるmeasuresIDを持つ複数の
        // Memoが生成されてしまう（新データモデルは1課題1メモ/ノートが前提のため、片方が画面から
        // 見えなくなる。issue #184）。ノートIDごとに1件へマージしてからMemoを生成する
        let mergedMemos = MigrationMemoMerger.merge(effectivenessByMeasures: effectivenessByMeasures)
        for merged in mergedMemos {
            let memo = Memo()
            memo.memoID = UUIDGenerator.generateID()
            memo.userID = userID
            memo.measuresID = merged.measuresID
            memo.noteID = merged.noteID
            memo.detail = merged.detail
            memo.isDeleted = false
            memo.created_at = now
            memo.updated_at = now

            try RealmManager.shared.saveItem(memo)
            try await FirebaseManager.shared.saveMemo(memo: memo)
        }
    }

    /// 旧目標データを Target に変換して保存
    /// month == 13 は年間目標を示す旧仕様
    private func migrateTarget(documentID: String, data: [String: Any]) async throws {
        guard
            let year = data["year"] as? Int,
            let month = data["month"] as? Int,
            let detail = data["detail"] as? String,
            let isDeleted = data["isDeleted"] as? Bool
        else { throw MigrationError.invalidData(entity: "Target", documentID: documentID) }

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
    private func migrateFreeNote(documentID: String, data: [String: Any]) async throws {
        guard
            let title = data["title"] as? String,
            let detail = data["detail"] as? String
        else { throw MigrationError.invalidData(entity: "FreeNote", documentID: documentID) }

        let userID = getUserID()
        let now = Date()

        if let existingFreeNote = try RealmManager.shared.getFreeNote() {
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
    private func migrateNote(documentID: String, data: [String: Any]) async throws {
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
        else { throw MigrationError.invalidData(entity: "Note", documentID: documentID) }

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
        default: noteType = NoteType.practice.rawValue
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

    /// 指定した旧コレクションのドキュメントを論理削除（isDeleted = true）
    /// - Parameters:
    ///   - collection: 対象コレクション名（"TaskData" / "TargetData" / "NoteData"）
    ///   - documentID: 対象ドキュメントID
    private func markOldDocumentDeleted(collection: String, documentID: String) async throws {
        try await withFirestoreContinuation { completion in
            db.collection(collection).document(documentID)
                .updateData(["isDeleted": true], completion: completion)
        }
    }

    /// 旧 FreeNoteData ドキュメントを論理削除（isDeleted = true）
    private func deleteOldFreeNoteDocument(userID: String) async throws {
        try await withFirestoreContinuation { completion in
            db.collection("FreeNoteData").document(userID)
                .updateData(["isDeleted": true], completion: completion)
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
        case "晴れ": return Weather.sunny.rawValue
        case "くもり": return Weather.cloudy.rawValue
        case "雨": return Weather.rainy.rawValue
        default: return Weather.sunny.rawValue
        }
    }
}

// MARK: - MigrationStepRunner

/// 旧データマイグレーションの「変換→旧データ削除」という制御フローを、
/// `MigrationManager`（Firebase依存）から切り離して独立にテストできるようにするための実行役
///
/// 変換（migrate）が`MigrationError`で失敗した場合、旧データ削除（markDeleted）を呼ばずに
/// 旧データを保持したまま処理を継続させる（issue #35: 必須フィールド欠損によるデータ恒久消失の防止）。
/// `MigrationError`以外のエラー（Firestore通信エラー等）はそのままrethrowし、
/// 既存の異常系挙動（`migrateAll()`全体の中断）を変えない。
///
/// また、`migrate`が成功した直後に`markDeleted`だけが失敗した場合、旧ドキュメントの
/// `isDeleted`が更新されないため次回のマイグレーション再実行で同一旧ドキュメントが再取得され、
/// `migrate`が再実行されて新規レコードが重複作成されてしまう（issue #30）。これを防ぐため、
/// `entity`+`documentID`単位で「migrate成功済みか」をUserDefaults経由で永続的に記録し、
/// 既にmigrate済みの場合は`migrate`をスキップして`markDeleted`のみ再試行する。
@MainActor
struct MigrationStepRunner {

    /// ログ出力先（テストでは注入して呼び出し内容を検証する）
    private let logger: (String) -> Void

    init(logger: @escaping (String) -> Void = { print($0) }) {
        self.logger = logger
    }

    /// 1件の旧データについて、変換→旧データ削除を実行する
    /// - Parameters:
    ///   - entity: ログ出力用・べき等性ガードのキー用のエンティティ名（例: "Task"）
    ///   - documentID: ログ出力用・べき等性ガードのキー用の旧ドキュメントID
    ///   - migrate: 変換処理（`MigrationError.invalidData`をthrowした場合はスキップ扱いとする）
    ///   - markDeleted: 変換成功時にのみ実行する旧データ削除処理
    /// - Throws: `migrate`/`markDeleted`が`MigrationError`以外のエラーをthrowした場合、そのまま伝播する
    func run(
        entity: String,
        documentID: String,
        migrate: () async throws -> Void,
        markDeleted: () async throws -> Void
    ) async throws {
        if isAlreadyMigrated(entity: entity, documentID: documentID) {
            // 前回の実行でmigrateは成功済み（markDeletedのみ失敗）のため、
            // migrateを再実行せずmarkDeletedのみ再試行する（issue #30: 重複作成防止）
            logger("旧\(entity)データは変換済みのためスキップし、旧データ削除のみ再試行します: documentID=\(documentID)")
        } else {
            do {
                try await migrate()
            } catch let error as MigrationError {
                logger("旧\(entity)データの変換に失敗したため、旧データを保持します: documentID=\(documentID), error=\(error)")
                return
            }
            markAsMigrated(entity: entity, documentID: documentID)
        }

        try await markDeleted()

        // markDeletedまで成功したら、旧ドキュメントは再取得されなくなるためガード記録は不要になる
        clearMigrated(entity: entity, documentID: documentID)
    }

    // MARK: - べき等性ガード（migrate成功後のmarkDeleted失敗による重複作成防止）

    private func guardKey(entity: String, documentID: String) -> String {
        "migratedOldDoc_\(entity)_\(documentID)"
    }

    private func isAlreadyMigrated(entity: String, documentID: String) -> Bool {
        UserDefaultsManager.get(key: guardKey(entity: entity, documentID: documentID), defaultValue: false)
    }

    private func markAsMigrated(entity: String, documentID: String) {
        UserDefaultsManager.set(key: guardKey(entity: entity, documentID: documentID), value: true)
    }

    private func clearMigrated(entity: String, documentID: String) {
        UserDefaultsManager.remove(key: guardKey(entity: entity, documentID: documentID))
    }
}

// MARK: - MeasuresOrderResolver

/// 旧アプリの measuresData（対策タイトルをキーとするDictionary）から、
/// Measures.order を決定的に採番するための対策タイトル順序を算出する
///
/// Swift Dictionary の列挙順は不定なため、旧データの "measuresPriority" フィールド
/// （ユーザーが指定した最優先対策のタイトル）を order=0 として先頭に固定し、
/// 残りは `sorted()` で決定的にソートする（issue #71）
///
/// `MigrationManager`（Firebase依存でテスト環境ではインスタンス化できない）から独立した
/// 純粋関数とすることで、Firebase未設定のテスト環境でも単体テスト可能にする
/// （`MigrationStepRunner`と同じ設計方針）
enum MeasuresOrderResolver {

    /// - Parameters:
    ///   - measuresTitles: measuresData のキー一覧（対策タイトル、重複なし）
    ///   - measuresPriority: 旧データの "measuresPriority" フィールド値（最優先対策のタイトル）
    /// - Returns: order=0から順に採番すべき対策タイトルの配列。
    ///   measuresPriorityがmeasuresTitlesに一致するものを含む場合は先頭に配置し、
    ///   残り（一致しない場合は全件）は sorted() による決定的な順序とする
    static func resolveOrder(measuresTitles: [String], measuresPriority: String?) -> [String] {
        let sortedTitles = measuresTitles.sorted()

        guard let priority = measuresPriority, sortedTitles.contains(priority) else {
            return sortedTitles
        }

        return [priority] + sortedTitles.filter { $0 != priority }
    }
}

// MARK: - MigrationMemoMerger

/// 旧アプリのmeasuresData（対策単位で保持されていた効果コメント）を、
/// 新データモデルの「1課題1メモ/ノート」という前提に適合させるため、
/// 同一の実ノート（旧noteID、0以外）に属する複数対策の効果コメントを1件のMemoにマージする純粋関数
///
/// 旧アプリは効果コメントを対策(Measures)単位で保持していたため、同一の練習ノートで
/// 複数の対策にコメントが付いていた場合、変換時に素直にMemoを生成すると
/// 同一taskID・同一noteIDだが異なるmeasuresIDを持つ複数のMemoレコードが生成されてしまう。
/// 新データモデルの`TaskViewModel.associateTasksWithMemos`は「1課題1メモ」を前提に
/// taskIDでDictionaryキー化するため、後から処理された方でもう一方が画面から見えなくなる
/// （データ自体はRealm/Firestoreに残るが、ユーザーからは消失したように見える。issue #184）。
///
/// 一方、旧noteID == 0（新データモデルでのnoteID = ""、旧アプリでノートに紐付けられなかった
/// 効果コメント）は、`MemoViewModel.getMemosByMeasuresID`により対策ごとに独立した一覧として
/// 表示される前提のため、`associateTasksWithMemos`の「1課題1メモ/ノート」制約の対象外であり、
/// マージ対象にしてはいけない（マージすると異なる対策の独立したコメントが1件に統合され、
/// 対策詳細画面から一方のコメントが消えてしまう回帰を生む。クロスレビュー指摘により判明）。
/// そのため実ノートID（0以外）のみをマージキーとして扱い、noteID == ""のコメントは
/// 対策ごとに個別のMemoとしてそのまま生成する。
///
/// `MigrationManager`（Firebase依存でテスト環境ではインスタンス化できない）から独立した
/// 純粋関数とすることで、Firebase未設定のテスト環境でも単体テスト可能にする
/// （`MeasuresOrderResolver`と同じ設計方針）
enum MigrationMemoMerger {

    /// マージ後に生成すべきMemoの情報
    struct MergedMemo: Equatable {
        /// メモが紐づく対策ID（実ノートに複数対策のコメントがあり1件へマージされた場合は、
        /// 呼び出し元が渡した順序（通常はmeasuresPriorityが最優先の対策順）で最初に登場した対策のIDを採用する）
        let measuresID: String
        /// 旧Int型noteIDを変換したノートID（Note変換時のnoteIDと整合させるための文字列表現）。
        /// 空文字は旧アプリでノートに紐付けられなかったコメントを表す
        let noteID: String
        /// 本文（実ノートへの複数コメントがマージされた場合は改行区切りで連結する）
        let detail: String
    }

    /// 対策ごとの効果コメント一覧
    struct MeasuresEffectiveness {
        let measuresID: String
        /// (コメント文字列, 旧ノートID(Int)) の配列
        let comments: [(comment: String, oldNoteID: Int)]

        init(measuresID: String, comments: [(comment: String, oldNoteID: Int)]) {
            self.measuresID = measuresID
            self.comments = comments
        }
    }

    /// - Parameter effectivenessByMeasures: 課題（TaskData）1件に属する対策ごとの効果コメント一覧。
    ///   呼び出し元でmeasuresOrder順（measuresPriorityが最優先）に並べたものを渡すこと
    /// - Returns: Memo生成計画。実ノートID（0以外）のコメントは同一noteIDごとに1件へマージし、
    ///   ノート未紐付け（旧noteID == 0）のコメントはマージせずコメントごとに個別のまま返す。
    ///   全体を通じて、最初にそのエントリが出現した順（＝measuresPriorityが最優先の対策から
    ///   処理される前提）を維持する
    static func merge(effectivenessByMeasures: [MeasuresEffectiveness]) -> [MergedMemo] {
        var result: [MergedMemo] = []
        // 実ノートID（0以外）のみをマージキーとして扱う。noteID == ""の位置をこのDictionaryで
        // 管理しないことで、ノート未紐付けのコメントは常に個別のMergedMemoとして追加される
        var indexByNoteID: [String: Int] = [:]

        for measuresEffectiveness in effectivenessByMeasures {
            for (comment, oldNoteIDInt) in measuresEffectiveness.comments {
                guard !comment.isEmpty else { continue }

                guard oldNoteIDInt != 0 else {
                    // ノート未紐付けのコメントは対策ごとに独立して表示される前提のため、
                    // 他の対策のコメントとマージせずそのまま個別のMemoとして追加する
                    result.append(
                        MergedMemo(measuresID: measuresEffectiveness.measuresID, noteID: "", detail: comment))
                    continue
                }

                // noteID は旧 Int を String に変換して保持（Note 変換時の noteID と整合させる）
                let noteID = String(oldNoteIDInt)

                if let index = indexByNoteID[noteID] {
                    // 既に同一ノートのコメントがある場合は本文を追記してマージし、
                    // measuresIDは先に登場した対策のものを維持する（measuresPriority優先）
                    let existing = result[index]
                    result[index] = MergedMemo(
                        measuresID: existing.measuresID,
                        noteID: noteID,
                        detail: existing.detail + "\n" + comment
                    )
                } else {
                    indexByNoteID[noteID] = result.count
                    result.append(
                        MergedMemo(
                            measuresID: measuresEffectiveness.measuresID,
                            noteID: noteID,
                            detail: comment
                        ))
                }
            }
        }

        return result
    }
}
