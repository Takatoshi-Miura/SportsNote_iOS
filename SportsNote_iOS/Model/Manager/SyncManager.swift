import Foundation
import RealmSwift

/// 同期可能なデータの共通インターフェース
protocol Syncable {
    func getId() -> String
    var updated_at: Date { get set }
}

// Realmモデルに対してSyncableプロトコルを適用する拡張
extension Group: Syncable {
    func getId() -> String {
        return self.groupID
    }
}

extension TaskData: Syncable {
    func getId() -> String {
        return self.taskID
    }
}

extension Measures: Syncable {
    func getId() -> String {
        return self.measuresID
    }
}

extension Memo: Syncable {
    func getId() -> String {
        return self.memoID
    }
}

extension Target: Syncable {
    func getId() -> String {
        return self.targetID
    }
}

extension Note: Syncable {
    func getId() -> String {
        return self.noteID
    }
}

@MainActor
final class SyncManager {
    static let shared = SyncManager()

    private init() {}

    /// Firebase と Realm の全データを同期
    /// 各同期処理は並列に行われ、全ての同期が完了するまで待機する
    func syncAllData() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await self.syncGroup() }
            group.addTask { try await self.syncTask() }
            group.addTask { try await self.syncMeasures() }
            group.addTask { try await self.syncMemo() }
            group.addTask { try await self.syncTarget() }
            group.addTask { try await self.syncNote() }

            // すべてのタスクが完了するまで待機
            for try await _ in group {}
        }
    }

    /// Firebase と Realm のデータを同期する汎用メソッド
    ///
    /// @param T Syncable を実装したデータ型
    /// @param getFirebaseData Firebase からデータを取得する関数
    /// @param getRealmData Realm からデータを取得する関数
    /// @param saveToFirebase Firebase にデータを保存する関数
    /// @param updateFirebase Firebase のデータを更新する関数
    private func syncData<T>(
        getFirebaseData: @MainActor () async throws -> [T],
        getRealmData: @MainActor () throws -> [T],
        saveToFirebase: @MainActor (T) async throws -> Void,
        updateFirebase: @MainActor (T) async throws -> Void
    ) async throws where T: Syncable, T: Object {
        // Firebase と Realm のデータを取得
        let firebaseArray = try await getFirebaseData()
        let realmArray = try getRealmData()

        // ID をキーとしたマップを作成
        let firebaseMap = Dictionary(uniqueKeysWithValues: firebaseArray.map { ($0.getId(), $0) })
        let realmMap = Dictionary(uniqueKeysWithValues: realmArray.map { ($0.getId(), $0) })

        // Firebase もしくは Realm にしか存在しないデータを取得
        let onlyFirebaseID = Set(firebaseMap.keys).subtracting(realmMap.keys)
        let onlyRealmID = Set(realmMap.keys).subtracting(firebaseMap.keys)

        // データの同期処理
        // Realm にしかないデータを Firebase に保存
        for id in onlyRealmID {
            if let item = realmMap[id] {
                try await saveToFirebase(item)
            }
        }

        // Firebase にしかないデータを Realm に保存
        for id in onlyFirebaseID {
            if let item = firebaseMap[id] {
                try? RealmManager.shared.saveItem(item)
            }
        }

        // 両方に存在するデータの更新日時を比較し、新しい方に更新
        for id in Set(firebaseMap.keys).intersection(realmMap.keys) {
            guard let realmItem = realmMap[id], let firebaseItem = firebaseMap[id] else {
                continue
            }

            if realmItem.updated_at > firebaseItem.updated_at {
                try await updateFirebase(realmItem)
            } else if firebaseItem.updated_at > realmItem.updated_at {
                try? RealmManager.shared.saveItem(firebaseItem)
            }
        }
    }

    /// Group を同期
    @MainActor
    private func syncGroup() async throws {
        try await syncData(
            getFirebaseData: { try await FirebaseManager.shared.getAllGroup() },
            getRealmData: { try RealmManager.shared.getDataList(clazz: Group.self) },
            saveToFirebase: { try await FirebaseManager.shared.saveGroup(group: $0) },
            updateFirebase: { try await FirebaseManager.shared.updateGroup(group: $0) }
        )
    }

    /// Task を同期
    @MainActor
    private func syncTask() async throws {
        try await syncData(
            getFirebaseData: { try await FirebaseManager.shared.getAllTask() },
            getRealmData: { try RealmManager.shared.getDataList(clazz: TaskData.self) },
            saveToFirebase: { try await FirebaseManager.shared.saveTask(task: $0) },
            updateFirebase: { try await FirebaseManager.shared.updateTask(task: $0) }
        )
    }

    /// Measures を同期
    @MainActor
    private func syncMeasures() async throws {
        try await syncData(
            getFirebaseData: { try await FirebaseManager.shared.getAllMeasures() },
            getRealmData: { try RealmManager.shared.getDataList(clazz: Measures.self) },
            saveToFirebase: { try await FirebaseManager.shared.saveMeasures(measures: $0) },
            updateFirebase: { try await FirebaseManager.shared.updateMeasures(measures: $0) }
        )
    }

    /// Memo を同期
    @MainActor
    private func syncMemo() async throws {
        try await syncData(
            getFirebaseData: { try await FirebaseManager.shared.getAllMemo() },
            getRealmData: { try RealmManager.shared.getDataList(clazz: Memo.self) },
            saveToFirebase: { try await FirebaseManager.shared.saveMemo(memo: $0) },
            updateFirebase: { try await FirebaseManager.shared.updateMemo(memo: $0) }
        )
    }

    /// Target を同期
    @MainActor
    private func syncTarget() async throws {
        try await syncData(
            getFirebaseData: { try await FirebaseManager.shared.getAllTarget() },
            getRealmData: { try RealmManager.shared.getDataList(clazz: Target.self) },
            saveToFirebase: { try await FirebaseManager.shared.saveTarget(target: $0) },
            updateFirebase: { try await FirebaseManager.shared.updateTarget(target: $0) }
        )
    }

    /// Note を同期
    @MainActor
    private func syncNote() async throws {
        try await syncData(
            getFirebaseData: { try await FirebaseManager.shared.getAllNote() },
            getRealmData: { try RealmManager.shared.getDataList(clazz: Note.self) },
            saveToFirebase: { try await FirebaseManager.shared.saveNote(note: $0) },
            updateFirebase: { try await FirebaseManager.shared.updateNote(note: $0) }
        )
    }
}
