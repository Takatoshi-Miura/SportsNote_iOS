@preconcurrency import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Foundation

final class FirebaseManager: @unchecked Sendable {

    static let shared = FirebaseManager()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Create

    /**
     * Firebaseにデータを保存
     *
     * @param collectionName コレクション名
     * @param documentID ドキュメントID
     * @param data 保存するデータ
     * @throws SportsNoteError Firebase保存に失敗した場合
     */
    private func saveDocument(
        collectionName: String,
        documentID: String,
        data: [String: Any]
    ) async throws {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                db.collection(collectionName)
                    .document(documentID)
                    .setData(data) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: ())
                        }
                    }
            }
        } catch let error {
            throw ErrorMapper.mapFirebaseError(error, context: "saveDocument-\(collectionName)-\(documentID)")
        }
    }

    /**
     * FirebaseにGroupを保存
     *
     * @param group Group
     * @throws SportsNoteError Firebase保存に失敗した場合
     */
    func saveGroup(group: Group) async throws {
        try await saveDocument(
            collectionName: "Group",
            documentID: "\(group.userID)_\(group.groupID)",
            data: [
                "userID": group.userID,
                "groupID": group.groupID,
                "title": group.title,
                "color": group.color,
                "order": group.order,
                "isDeleted": group.isDeleted,
                "created_at": group.created_at,
                "updated_at": group.updated_at,
            ]
        )
    }

    /**
     * FirebaseにTaskを保存
     *
     * @param task TaskData
     */
    func saveTask(task: TaskData) async throws {
        try await saveDocument(
            collectionName: "Task",
            documentID: "\(task.userID)_\(task.taskID)",
            data: [
                "userID": task.userID,
                "taskID": task.taskID,
                "groupID": task.groupID,
                "title": task.title,
                "cause": task.cause,
                "order": task.order,
                "isComplete": task.isComplete,
                "isDeleted": task.isDeleted,
                "created_at": task.created_at,
                "updated_at": task.updated_at,
            ]
        )
    }

    /**
     * FirebaseにMeasuresを保存
     *
     * @param measures Measures
     */
    func saveMeasures(measures: Measures) async throws {
        try await saveDocument(
            collectionName: "Measures",
            documentID: "\(measures.userID)_\(measures.measuresID)",
            data: [
                "userID": measures.userID,
                "measuresID": measures.measuresID,
                "taskID": measures.taskID,
                "title": measures.title,
                "order": measures.order,
                "isDeleted": measures.isDeleted,
                "created_at": measures.created_at,
                "updated_at": measures.updated_at,
            ]
        )
    }

    /**
     * FirebaseにMemoを保存
     *
     * @param memo Memo
     */
    func saveMemo(memo: Memo) async throws {
        try await saveDocument(
            collectionName: "Memo",
            documentID: "\(memo.userID)_\(memo.memoID)",
            data: [
                "userID": memo.userID,
                "memoID": memo.memoID,
                "noteID": memo.noteID,
                "measuresID": memo.measuresID,
                "detail": memo.detail,
                "isDeleted": memo.isDeleted,
                "created_at": memo.created_at,
                "updated_at": memo.updated_at,
            ]
        )
    }

    /**
     * FirebaseにTargetを保存
     *
     * @param target Target
     */
    func saveTarget(target: Target) async throws {
        try await saveDocument(
            collectionName: "Target",
            documentID: "\(target.userID)_\(target.targetID)",
            data: [
                "userID": target.userID,
                "targetID": target.targetID,
                "title": target.title,
                "year": target.year,
                "month": target.month,
                "isYearlyTarget": target.isYearlyTarget,
                "isDeleted": target.isDeleted,
                "created_at": target.created_at,
                "updated_at": target.updated_at,
            ]
        )
    }

    /**
     * FirebaseにNoteを保存
     *
     * @param note Note
     */
    func saveNote(note: Note) async throws {
        try await saveDocument(
            collectionName: "Note",
            documentID: "\(note.userID)_\(note.noteID)",
            data: [
                "userID": note.userID,
                "noteID": note.noteID,
                "noteType": note.noteType,
                "isDeleted": note.isDeleted,
                "created_at": note.created_at,
                "updated_at": note.updated_at,
                "title": note.title,
                "date": note.date,
                "weather": note.weather,
                "temperature": note.temperature,
                "condition": note.condition,
                "reflection": note.reflection,
                "purpose": note.purpose,
                "detail": note.detail,
                "target": note.target,
                "consciousness": note.consciousness,
                "result": note.result,
            ]
        )
    }

    // MARK: - Select

    /**
     * Firebaseから指定したコレクションのデータを全取得
     *
     * @param collection コレクション名
     * @return 取得したドキュメント
     */
    private func getAllDocuments(collection: String) async throws -> [QueryDocumentSnapshot] {
        let userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: UUID().uuidString)

        do {
            return try await withCheckedThrowingContinuation { continuation in
                db.collection(collection)
                    .whereField("userID", isEqualTo: userID)
                    .getDocuments { (querySnapshot, error) in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }

                        if let querySnapshot = querySnapshot {
                            continuation.resume(returning: querySnapshot.documents)
                        } else {
                            continuation.resume(returning: [])
                        }
                    }
            }
        } catch let error {
            throw ErrorMapper.mapFirebaseError(error, context: "getAllDocuments-\(collection)")
        }
    }

    /**
     * FirebaseからGroupを全取得
     *
     * @return [Group]
     */
    func getAllGroup() async throws -> [Group] {
        let documents = try await getAllDocuments(collection: "Group")

        return documents.compactMap { document -> Group? in
            let data = document.data()
            let group = Group()

            guard let userID = data["userID"] as? String,
                let groupID = data["groupID"] as? String,
                let title = data["title"] as? String,
                let color = data["color"] as? Int,
                let order = data["order"] as? Int,
                let isDeleted = data["isDeleted"] as? Bool,
                let created_at = (data["created_at"] as? Timestamp)?.dateValue(),
                let updated_at = (data["updated_at"] as? Timestamp)?.dateValue()
            else {
                return nil
            }

            group.userID = userID
            group.groupID = groupID
            group.title = title
            group.color = color
            group.order = order
            group.isDeleted = isDeleted
            group.created_at = created_at
            group.updated_at = updated_at

            return group
        }
    }

    /**
     * FirebaseからTaskを全取得
     *
     * @return [TaskData]
     */
    func getAllTask() async throws -> [TaskData] {
        let documents = try await getAllDocuments(collection: "Task")

        return documents.compactMap { document -> TaskData? in
            let data = document.data()
            let task = TaskData()

            guard let userID = data["userID"] as? String,
                let taskID = data["taskID"] as? String,
                let groupID = data["groupID"] as? String,
                let title = data["title"] as? String,
                let cause = data["cause"] as? String,
                let order = data["order"] as? Int,
                let isComplete = data["isComplete"] as? Bool,
                let isDeleted = data["isDeleted"] as? Bool,
                let created_at = (data["created_at"] as? Timestamp)?.dateValue(),
                let updated_at = (data["updated_at"] as? Timestamp)?.dateValue()
            else {
                return nil
            }

            task.userID = userID
            task.taskID = taskID
            task.groupID = groupID
            task.title = title
            task.cause = cause
            task.order = order
            task.isComplete = isComplete
            task.isDeleted = isDeleted
            task.created_at = created_at
            task.updated_at = updated_at

            return task
        }
    }

    /**
     * FirebaseからMeasuresを全取得
     *
     * @return [Measures]
     */
    func getAllMeasures() async throws -> [Measures] {
        let documents = try await getAllDocuments(collection: "Measures")

        return documents.compactMap { document -> Measures? in
            let data = document.data()
            let measure = Measures()

            guard let userID = data["userID"] as? String,
                let measuresID = data["measuresID"] as? String,
                let taskID = data["taskID"] as? String,
                let title = data["title"] as? String,
                let order = data["order"] as? Int,
                let isDeleted = data["isDeleted"] as? Bool,
                let created_at = (data["created_at"] as? Timestamp)?.dateValue(),
                let updated_at = (data["updated_at"] as? Timestamp)?.dateValue()
            else {
                return nil
            }

            measure.userID = userID
            measure.measuresID = measuresID
            measure.taskID = taskID
            measure.title = title
            measure.order = order
            measure.isDeleted = isDeleted
            measure.created_at = created_at
            measure.updated_at = updated_at

            return measure
        }
    }

    /**
     * FirebaseからMemoを全取得
     *
     * @return [Memo]
     */
    func getAllMemo() async throws -> [Memo] {
        let documents = try await getAllDocuments(collection: "Memo")

        return documents.compactMap { document -> Memo? in
            let data = document.data()
            let memo = Memo()

            guard let userID = data["userID"] as? String,
                let memoID = data["memoID"] as? String,
                let noteID = data["noteID"] as? String,
                let measuresID = data["measuresID"] as? String,
                let detail = data["detail"] as? String,
                let isDeleted = data["isDeleted"] as? Bool,
                let created_at = (data["created_at"] as? Timestamp)?.dateValue(),
                let updated_at = (data["updated_at"] as? Timestamp)?.dateValue()
            else {
                return nil
            }

            memo.userID = userID
            memo.memoID = memoID
            memo.noteID = noteID
            memo.measuresID = measuresID
            memo.detail = detail
            memo.isDeleted = isDeleted
            memo.created_at = created_at
            memo.updated_at = updated_at

            return memo
        }
    }

    /**
     * FirebaseからTargetを全取得
     *
     * @return [Target]
     */
    func getAllTarget() async throws -> [Target] {
        let documents = try await getAllDocuments(collection: "Target")

        return documents.compactMap { document -> Target? in
            let data = document.data()
            let target = Target()

            guard let userID = data["userID"] as? String,
                let targetID = data["targetID"] as? String,
                let title = data["title"] as? String,
                let year = data["year"] as? Int,
                let month = data["month"] as? Int,
                let isYearlyTarget = data["isYearlyTarget"] as? Bool,
                let isDeleted = data["isDeleted"] as? Bool,
                let created_at = (data["created_at"] as? Timestamp)?.dateValue(),
                let updated_at = (data["updated_at"] as? Timestamp)?.dateValue()
            else {
                return nil
            }

            target.userID = userID
            target.targetID = targetID
            target.title = title
            target.year = year
            target.month = month
            target.isYearlyTarget = isYearlyTarget
            target.isDeleted = isDeleted
            target.created_at = created_at
            target.updated_at = updated_at

            return target
        }
    }

    /**
     * FirebaseからNoteを全取得
     *
     * @return [Note]
     */
    func getAllNote() async throws -> [Note] {
        let documents = try await getAllDocuments(collection: "Note")

        return documents.compactMap { document -> Note? in
            let data = document.data()
            let note = Note()

            guard let userID = data["userID"] as? String,
                let noteID = data["noteID"] as? String,
                let noteType = data["noteType"] as? Int,
                let isDeleted = data["isDeleted"] as? Bool,
                let created_at = (data["created_at"] as? Timestamp)?.dateValue(),
                let updated_at = (data["updated_at"] as? Timestamp)?.dateValue(),
                let title = data["title"] as? String,
                let date = (data["date"] as? Timestamp)?.dateValue(),
                let weather = data["weather"] as? Int,
                let temperature = data["temperature"] as? Int,
                let condition = data["condition"] as? String,
                let reflection = data["reflection"] as? String,
                let purpose = data["purpose"] as? String,
                let detail = data["detail"] as? String,
                let target = data["target"] as? String,
                let consciousness = data["consciousness"] as? String,
                let result = data["result"] as? String
            else {
                return nil
            }

            note.userID = userID
            note.noteID = noteID
            note.noteType = noteType
            note.isDeleted = isDeleted
            note.created_at = created_at
            note.updated_at = updated_at
            note.title = title
            note.date = date
            note.weather = weather
            note.temperature = temperature
            note.condition = condition
            note.reflection = reflection
            note.purpose = purpose
            note.detail = detail
            note.target = target
            note.consciousness = consciousness
            note.result = result

            return note
        }
    }

    // MARK: - Update

    /**
     * Firebaseから指定したコレクションのデータを更新
     *
     * @param collection コレクション名
     * @param documentID ドキュメントID
     * @param data 更新するデータ
     */
    private func updateDocument(
        collection: String,
        documentID: String,
        data: [String: Any]
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            db.collection(collection).document(documentID)
                .updateData(data) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
        }
    }

    /**
     * グループを更新
     *
     * @param group グループデータ
     */
    func updateGroup(group: Group) async throws {
        let userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: UUID().uuidString)
        let documentID = "\(userID)_\(group.groupID)"

        let data: [String: Any] = [
            "title": group.title,
            "color": group.color,
            "order": group.order,
            "isDeleted": group.isDeleted,
            "updated_at": group.updated_at,
        ]

        try await updateDocument(collection: "Group", documentID: documentID, data: data)
    }

    /**
     * 課題を更新
     *
     * @param task 課題データ
     */
    func updateTask(task: TaskData) async throws {
        let userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: UUID().uuidString)
        let documentID = "\(userID)_\(task.taskID)"

        let data: [String: Any] = [
            "groupID": task.groupID,
            "title": task.title,
            "cause": task.cause,
            "order": task.order,
            "isComplete": task.isComplete,
            "isDeleted": task.isDeleted,
            "updated_at": task.updated_at,
        ]

        try await updateDocument(collection: "Task", documentID: documentID, data: data)
    }

    /**
     * 対策を更新
     *
     * @param measures 対策データ
     */
    func updateMeasures(measures: Measures) async throws {
        let userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: UUID().uuidString)
        let documentID = "\(userID)_\(measures.measuresID)"

        let data: [String: Any] = [
            "title": measures.title,
            "order": measures.order,
            "isDeleted": measures.isDeleted,
            "updated_at": measures.updated_at,
        ]

        try await updateDocument(collection: "Measures", documentID: documentID, data: data)
    }

    /**
     * メモを更新
     *
     * @param memo メモデータ
     */
    func updateMemo(memo: Memo) async throws {
        let userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: UUID().uuidString)
        let documentID = "\(userID)_\(memo.memoID)"

        let data: [String: Any] = [
            "detail": memo.detail,
            "isDeleted": memo.isDeleted,
            "updated_at": memo.updated_at,
        ]

        try await updateDocument(collection: "Memo", documentID: documentID, data: data)
    }

    /**
     * 目標を更新
     *
     * @param target 目標データ
     */
    func updateTarget(target: Target) async throws {
        let userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: UUID().uuidString)
        let documentID = "\(userID)_\(target.targetID)"

        let data: [String: Any] = [
            "title": target.title,
            "year": target.year,
            "month": target.month,
            "isYearlyTarget": target.isYearlyTarget,
            "isDeleted": target.isDeleted,
            "updated_at": target.updated_at,
        ]

        try await updateDocument(collection: "Target", documentID: documentID, data: data)
    }

    /**
     * ノート(フリー、練習、大会)を更新
     *
     * @param note ノートデータ
     */
    func updateNote(note: Note) async throws {
        let userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: UUID().uuidString)
        let documentID = "\(userID)_\(note.noteID)"

        let data: [String: Any] = [
            "isDeleted": note.isDeleted,
            "updated_at": note.updated_at,
            "title": note.title,
            "date": note.date,
            "weather": note.weather,
            "temperature": note.temperature,
            "condition": note.condition,
            "reflection": note.reflection,
            "purpose": note.purpose,
            "detail": note.detail,
            "target": note.target,
            "consciousness": note.consciousness,
            "result": note.result,
        ]

        try await updateDocument(collection: "Note", documentID: documentID, data: data)
    }
}
