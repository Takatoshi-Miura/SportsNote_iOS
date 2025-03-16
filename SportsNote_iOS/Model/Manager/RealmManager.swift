import UIKit
import RealmSwift

struct RealmConstants {
    static let databaseName = "sportsnote.realm"
    static let schemaVersion: UInt64 = 1
}

class RealmManager {
    
    // シングルトンインスタンス
    static let shared = RealmManager()
    
    private init() {}
    
    /// Realmを初期化(起動準備)
    func initRealm() {
        let config = Realm.Configuration(
            fileURL: Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent(RealmConstants.databaseName),
            schemaVersion: RealmConstants.schemaVersion,
            deleteRealmIfMigrationNeeded: true // マイグレーションが必要な場合、データ削除
        )
        Realm.Configuration.defaultConfiguration = config
    }
    
    /// Realmファイルのパスを出力
    func printRealmFilePath() {
        if let realmFile = Realm.Configuration.defaultConfiguration.fileURL {
            print("Realm file path: \(realmFile)")
        }
    }
    
    // MARK: - Insert
    
    /// 汎用的なデータ保存メソッド
    /// - Parameter item: 保存するデータ
    func saveItem<T: Object>(_ item: T) {
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(item, update: .modified) // `insertOrUpdate`相当
            }
        } catch let error {
            print("Failed to save item: \(error)")
        }
    }
    
    // MARK: - Update
    
    /// すべてのデータの userID を指定した値に更新する
    /// - Parameter userId: 更新後の userID
    func updateAllUserIds(userId: String) {
        do {
            let realm = try Realm()
            try realm.write {
                let allObjects = realm.objects(Object.self)
                for object in allObjects {
                    // 各オブジェクトが userID を持っているか確認し、更新する
                    if object.objectSchema.properties.contains(where: { $0.name == "userID" }) {
                        object.setValue(userId, forKey: "userID")
                    }
                }
            }
        } catch let error {
            print("Error updating all userIDs: \(error)")
        }
    }
    
    // MARK: - Select
    
    /// 指定したクラスに対応するプライマリキーのプロパティ名を取得
    /// - Returns: Tに対応するプライマリキーのプロパティ名
    /// - Throws: 対応していないクラスの場合にスローされる
    private func getPrimaryKeyName<T: Object>(_ type: T.Type) -> String {
        switch type {
        case is Group.Type:
            return "groupID"
        case is Measures.Type:
            return "measuresID"
        case is Memo.Type:
            return "memoID"
        case is Note.Type:
            return "noteID"
        case is Target.Type:
            return "targetID"
        case is TaskData.Type:
            return "taskID"
        default:
            fatalError("Unsupported class")
        }
    }
    
    /// 汎用的なデータ取得メソッド（ID指定）
    /// - Parameter id: 検索するID（文字列）
    /// - Returns: 取得データ（存在しない場合やエラーが発生した場合は`nil`）
    internal func getObjectById<T: Object>(id: String, type: T.Type) -> T? {
        do {
            let realm = try Realm()
            let primaryKeyName = getPrimaryKeyName(type)
            return realm.object(ofType: T.self, forPrimaryKey: id)
        } catch {
            print("Error fetching object: \(error)")
            return nil
        }
    }
    
    /// 汎用的なデータ一覧取得メソッド
    /// - Parameter clazz: 取得するデータ型のクラス
    /// - Returns: 条件に一致するデータのリスト
    func getDataList<T: Object>(clazz: T.Type) -> [T] {
        do {
            let realm = try Realm()
            return realm.objects(clazz)
                .filter("isDeleted == false")
                .sorted(byKeyPath: "order", ascending: true)
                .map { $0 }
        } catch {
            print("Error fetching data list: \(error)")
            return []
        }
    }
    
    /// 汎用的なデータカウント取得メソッド
    /// - Parameter clazz: RealmObjectのクラス型
    /// - Returns: isDeletedがfalseのデータ数
    func getCount<T: Object>(clazz: T.Type) -> Int {
        do {
            let realm = try Realm()
            return realm.objects(T.self)
                .filter("isDeleted == false")
                .count
        } catch {
            print("Error fetching count: \(error)")
            return 0
        }
    }
    
    /// groupIDに合致する完了した課題を取得
    /// - Parameter groupID: groupID
    /// - Returns: 完了した課題のリスト
    func getCompletedTasksByGroupId(groupID: String) -> [TaskData] {
        do {
            let realm = try Realm()
            return realm.objects(TaskData.self)
                .filter("groupID == %@ AND isComplete == true AND isDeleted == false", groupID)
                .sorted(byKeyPath: "order", ascending: true)
                .map { $0 }
        } catch {
            print("Error fetching completed tasks: \(error)")
            return []
        }
    }
    
    /// taskIDに合致する対策を取得
    /// - Parameter taskID: taskID
    /// - Returns: 対策のリスト
    func getMeasuresByTaskID(taskID: String) -> [Measures] {
        do {
            let realm = try Realm()
            return realm.objects(Measures.self)
                .filter("taskID == %@ AND isDeleted == false", taskID)
                .sorted(byKeyPath: "order", ascending: true)
                .map { $0 }
        } catch {
            print("Error fetching measures: \(error)")
            return []
        }
    }
    
    /// フリーノートを取得
    /// - Returns: フリーノート（存在しない場合は`nil`）
    func getFreeNote() -> Note? {
        do {
            let realm = try Realm()
            return realm.objects(Note.self)
                .filter("noteType == %@ AND isDeleted == false", NoteType.free.rawValue)
                .first
        } catch {
            print("Error fetching free note: \(error)")
            return nil
        }
    }
    
    /// 指定された文字列を含むノートを検索
    /// - Parameter query: 検索する文字列
    /// - Returns: 検索結果のノートリスト
    func searchNotesByQuery(query: String) -> [Note] {
        do {
            let realm = try Realm()
            
            // フリーノートを取得
            let freeNotes = Array(realm.objects(Note.self)
                .filter("noteType == %@ AND isDeleted == false", NoteType.free.rawValue))
            
            // 検索条件に一致するノートを取得
            let queryNotes = Array(realm.objects(Note.self)
                .filter("isDeleted == false")
                .filter("condition CONTAINS[c] %@ OR reflection CONTAINS[c] %@ OR purpose CONTAINS[c] %@ OR detail CONTAINS[c] %@ OR target CONTAINS[c] %@ OR consciousness CONTAINS[c] %@ OR result CONTAINS[c] %@", query, query, query, query, query, query, query))
            
            // 結果を結合して重複を除去
            return Array(Set(freeNotes + queryNotes))
        } catch {
            print("Error searching notes by query: \(error)")
            return []
        }
    }
    
    /// 指定した日付に合致するノートを取得
    /// - Parameter selectedDate: 日付
    /// - Returns: 指定した日付に合致するノートのリスト
    func getNotesByDate(selectedDate: Date) -> [Note] {
        do {
            let realm = try Realm()
            let startOfDay = Calendar.current.startOfDay(for: selectedDate)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
            return Array(realm.objects(Note.self)
                .filter("isDeleted == false AND noteType != %@ AND date >= %@ AND date < %@", NoteType.free.rawValue, startOfDay, endOfDay))
        } catch {
            print("Error fetching notes by date: \(error)")
            return []
        }
    }
    
    /// measuresIDに合致するメモを取得
    /// - Parameter measuresID: 対策ID
    /// - Returns: 対策IDに関連するメモのリスト
    func getMemosByMeasuresID(measuresID: String) -> [Memo] {
        do {
            let realm = try Realm()
            return Array(realm.objects(Memo.self)
                .filter("measuresID == %@ AND isDeleted == false")
                .sorted(byKeyPath: "created_at", ascending: true))
        } catch {
            print("Error fetching memos by measuresID: \(error)")
            return []
        }
    }
    
    /// noteIDに合致するメモを取得
    /// - Parameter noteID: ノートID
    /// - Returns: ノートIDに関連するメモのリスト
    func getMemosByNoteID(noteID: String) -> [Memo] {
        do {
            let realm = try Realm()
            return Array(realm.objects(Memo.self)
                .filter("noteID == %@ AND isDeleted == false")
                .sorted(byKeyPath: "created_at", ascending: true))
        } catch {
            print("Error fetching memos by noteID: \(error)")
            return []
        }
    }
    
    /// ノートの背景色を取得
    /// - Parameter noteID: ノートID
    /// - Returns: ノートの背景色
    func getNoteBackgroundColor(noteID: String) -> UIColor {
        do {
            let realm = try Realm()
            if let memo = realm.objects(Memo.self)
                .filter("noteID == %@ AND isDeleted == false", noteID)
                .first {
                if let measures = realm.objects(Measures.self)
                    .filter("measuresID == %@", memo.measuresID)
                    .first {
                    if let taskData = realm.objects(TaskData.self)
                        .filter("taskID == %@", measures.taskID)
                        .first {
                        if let group = realm.objects(Group.self)
                            .filter("groupID == %@", taskData.groupID)
                            .first {
                            return GroupColor.allCases[Int(group.color)].color
                        }
                    }
                }
            }
            return .white
        } catch {
            print("Error fetching note background color: \(error)")
            return .white
        }
    }
    
    /// 指定した年と月に合致し、削除されていない目標を取得
    /// - Parameters:
    ///   - year: 取得したい目標の年
    ///   - month: 取得したい目標の月
    /// - Returns: 条件に一致する目標のリスト
    func fetchTargetsByYearMonth(year: Int, month: Int) -> [Target] {
        do {
            let realm = try Realm()
            let targets = realm.objects(Target.self)
                .filter("((isYearlyTarget == false AND year == %@ AND month == %@) OR (isYearlyTarget == true AND year == %@)) AND isDeleted == false", year, month, year)
            return Array(targets)
        } catch {
            print("Error fetching targets by year and month: \(error)")
            return []
        }
    }
    
    // MARK: - Delete
    
    /// 汎用的な論理削除処理
    /// - Parameters:
    ///   - T: RealmObject を継承したデータ型
    ///   - id: 削除するデータの ID
    internal func logicalDelete<T: Object>(id: String, type: T.Type) {
        do {
            let realm = try Realm()
            
            try realm.write {
                // T 型のオブジェクトを指定された ID に一致するものを取得
                if let item = realm.object(ofType: type, forPrimaryKey: id) {
                    // 削除マークを付ける
                    markAsDeleted(item, realm: realm)
                    
                    // T 型に基づく関連エンティティの削除処理
                    if let note = item as? Note {
                        deleteRelatedNoteMemos(noteID: note.noteID, realm: realm)
                    } else if let group = item as? Group {
                        deleteRelatedTasks(groupID: group.groupID, realm: realm)
                    } else if let taskData = item as? TaskData {
                        deleteRelatedMeasures(taskID: taskData.taskID, realm: realm)
                    } else if let measures = item as? Measures {
                        deleteRelatedMeasuresMemos(measuresID: measures.measuresID, realm: realm)
                    }
                }
            }
        } catch {
            print("Error in logicalDelete: \(error)")
        }
    }

    /// 任意のオブジェクトを論理削除
    /// - Parameters:
    ///   - item: データ
    ///   - realm: Realmインスタンス
    private func markAsDeleted(_ item: Object, realm: Realm) {
        // itemが「削除フラグ」を持っているかどうかでチェックし、削除マークを付ける
        if let itemWithDeleteFlag = item as? Note {
            itemWithDeleteFlag.isDeleted = true
            realm.add(itemWithDeleteFlag, update: .modified)
        } else if let itemWithDeleteFlag = item as? Group {
            itemWithDeleteFlag.isDeleted = true
            realm.add(itemWithDeleteFlag, update: .modified)
        } else if let itemWithDeleteFlag = item as? TaskData {
            itemWithDeleteFlag.isDeleted = true
            realm.add(itemWithDeleteFlag, update: .modified)
        } else if let itemWithDeleteFlag = item as? Measures {
            itemWithDeleteFlag.isDeleted = true
            realm.add(itemWithDeleteFlag, update: .modified)
        } else if let itemWithDeleteFlag = item as? Memo {
            itemWithDeleteFlag.isDeleted = true
            realm.add(itemWithDeleteFlag, update: .modified)
        } else if let itemWithDeleteFlag = item as? Target {
            itemWithDeleteFlag.isDeleted = true
            realm.add(itemWithDeleteFlag, update: .modified)
        }
    }
    
    /// Note に関連する Memo を削除
    /// - Parameters:
    ///   - noteID: ノートID
    ///   - realm: Realm トランザクション
    private func deleteRelatedNoteMemos(noteID: String, realm: Realm) {
        let memos = realm.objects(Memo.self).filter("noteID == %@", noteID)
        for memo in memos {
            markAsDeleted(memo, realm: realm)
        }
    }

    /// Group に関連する TaskData, Measures, Memo を削除
    /// - Parameters:
    ///   - groupID: グループID
    ///   - realm: Realm トランザクション
    private func deleteRelatedTasks(groupID: String, realm: Realm) {
        let tasks = realm.objects(TaskData.self).filter("groupID == %@", groupID)
        for task in tasks {
            markAsDeleted(task, realm: realm)
            deleteRelatedMeasures(taskID: task.taskID, realm: realm)
        }
    }

    /// TaskData に関連する Measures, Memo を削除
    /// - Parameters:
    ///   - taskID: 課題ID
    ///   - realm: Realm トランザクション
    private func deleteRelatedMeasures(taskID: String, realm: Realm) {
        let measures = realm.objects(Measures.self).filter("taskID == %@", taskID)
        for measure in measures {
            markAsDeleted(measure, realm: realm)
            deleteRelatedMeasuresMemos(measuresID: measure.measuresID, realm: realm)
        }
    }

    /// Measures に関連する Memo を削除
    /// - Parameters:
    ///   - measuresID: 対策ID
    ///   - realm: Realm トランザクション
    private func deleteRelatedMeasuresMemos(measuresID: String, realm: Realm) {
        let memos = realm.objects(Memo.self).filter("measuresID == %@", measuresID)
        for memo in memos {
            markAsDeleted(memo, realm: realm)
        }
    }
    
    /// Realmの全データを削除
    func clearAll() {
        do {
            let realm = try Realm()
            try realm.write {
                realm.deleteAll()
            }
        } catch let error {
            print("Failed to clear Realm: \(error)")
        }
    }
}
