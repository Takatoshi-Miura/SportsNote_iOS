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
    /// - Parameters:
    ///   - T: Syncable を実装したデータ型
    ///   - getFirebaseData: Firebase からデータを取得する関数
    ///   - getRealmData: Realm からデータを取得する関数
    ///   - saveToFirebase: Firebase にデータを保存する関数
    ///   - updateFirebase: Firebase のデータを更新する関数
    func syncData<T>(
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
        // NOTE: 1件の保存失敗が他エンティティの同期全体を巻き添えでキャンセルしないよう、
        //       個別のエラーは try? で握りつぶす（syncAllData の withThrowingTaskGroup 対策）
        for id in onlyRealmID {
            if let item = realmMap[id] {
                try? await saveToFirebase(item)
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
                try? await updateFirebase(realmItem)
            } else if firebaseItem.updated_at > realmItem.updated_at {
                try? RealmManager.shared.saveItem(firebaseItem)
            }
        }
    }

    /// Group を同期
    /// - Parameters は本番のFirebase/Realm呼び出しをデフォルト値として注入可能にしている。
    ///   テストでは`getFirebaseData`等のみをスタブに差し替え、`getRealmData`は本番実装（`RealmManager`）を
    ///   そのまま経由させることで、実際の同期処理の配線（isDeleted復活バグ対策の実装箇所）を検証できる
    @MainActor
    func syncGroup(
        getFirebaseData: @MainActor () async throws -> [Group] = { try await FirebaseManager.shared.getAllGroup() },
        getRealmData: @MainActor () throws -> [Group] = {
            try RealmManager.shared.getDataListIncludingDeleted(clazz: Group.self)
        },
        saveToFirebase: @MainActor (Group) async throws -> Void = {
            try await FirebaseManager.shared.saveGroup(group: $0)
        },
        updateFirebase: @MainActor (Group) async throws -> Void = {
            try await FirebaseManager.shared.updateGroup(group: $0)
        }
    ) async throws {
        try await syncData(
            getFirebaseData: getFirebaseData,
            getRealmData: getRealmData,
            saveToFirebase: saveToFirebase,
            updateFirebase: updateFirebase
        )
    }

    /// Task を同期（テスト容易性のためデフォルト引数を持つ。syncGroupの説明を参照）
    @MainActor
    func syncTask(
        getFirebaseData: @MainActor () async throws -> [TaskData] = { try await FirebaseManager.shared.getAllTask() },
        getRealmData: @MainActor () throws -> [TaskData] = {
            try RealmManager.shared.getDataListIncludingDeleted(clazz: TaskData.self)
        },
        saveToFirebase: @MainActor (TaskData) async throws -> Void = {
            try await FirebaseManager.shared.saveTask(task: $0)
        },
        updateFirebase: @MainActor (TaskData) async throws -> Void = {
            try await FirebaseManager.shared.updateTask(task: $0)
        }
    ) async throws {
        try await syncData(
            getFirebaseData: getFirebaseData,
            getRealmData: getRealmData,
            saveToFirebase: saveToFirebase,
            updateFirebase: updateFirebase
        )
    }

    /// Measures を同期（テスト容易性のためデフォルト引数を持つ。syncGroupの説明を参照）
    @MainActor
    func syncMeasures(
        getFirebaseData: @MainActor () async throws -> [Measures] = {
            try await FirebaseManager.shared.getAllMeasures()
        },
        getRealmData: @MainActor () throws -> [Measures] = {
            try RealmManager.shared.getDataListIncludingDeleted(clazz: Measures.self)
        },
        saveToFirebase: @MainActor (Measures) async throws -> Void = {
            try await FirebaseManager.shared.saveMeasures(measures: $0)
        },
        updateFirebase: @MainActor (Measures) async throws -> Void = {
            try await FirebaseManager.shared.updateMeasures(measures: $0)
        }
    ) async throws {
        try await syncData(
            getFirebaseData: getFirebaseData,
            getRealmData: getRealmData,
            saveToFirebase: saveToFirebase,
            updateFirebase: updateFirebase
        )
    }

    /// Memo を同期（テスト容易性のためデフォルト引数を持つ。syncGroupの説明を参照）
    @MainActor
    func syncMemo(
        getFirebaseData: @MainActor () async throws -> [Memo] = { try await FirebaseManager.shared.getAllMemo() },
        getRealmData: @MainActor () throws -> [Memo] = {
            try RealmManager.shared.getDataListIncludingDeleted(clazz: Memo.self)
        },
        saveToFirebase: @MainActor (Memo) async throws -> Void = {
            try await FirebaseManager.shared.saveMemo(memo: $0)
        },
        updateFirebase: @MainActor (Memo) async throws -> Void = {
            try await FirebaseManager.shared.updateMemo(memo: $0)
        }
    ) async throws {
        try await syncData(
            getFirebaseData: getFirebaseData,
            getRealmData: getRealmData,
            saveToFirebase: saveToFirebase,
            updateFirebase: updateFirebase
        )
    }

    /// Target を同期（テスト容易性のためデフォルト引数を持つ。syncGroupの説明を参照）
    @MainActor
    func syncTarget(
        getFirebaseData: @MainActor () async throws -> [Target] = { try await FirebaseManager.shared.getAllTarget() },
        getRealmData: @MainActor () throws -> [Target] = {
            try RealmManager.shared.getDataListIncludingDeleted(clazz: Target.self)
        },
        saveToFirebase: @MainActor (Target) async throws -> Void = {
            try await FirebaseManager.shared.saveTarget(target: $0)
        },
        updateFirebase: @MainActor (Target) async throws -> Void = {
            try await FirebaseManager.shared.updateTarget(target: $0)
        }
    ) async throws {
        try await syncData(
            getFirebaseData: getFirebaseData,
            getRealmData: getRealmData,
            saveToFirebase: saveToFirebase,
            updateFirebase: updateFirebase
        )
    }

    /// Note を同期（テスト容易性のためデフォルト引数を持つ。syncGroupの説明を参照）
    @MainActor
    func syncNote(
        getFirebaseData: @MainActor () async throws -> [Note] = { try await FirebaseManager.shared.getAllNote() },
        getRealmData: @MainActor () throws -> [Note] = {
            try RealmManager.shared.getDataListIncludingDeleted(clazz: Note.self)
        },
        saveToFirebase: @MainActor (Note) async throws -> Void = {
            try await FirebaseManager.shared.saveNote(note: $0)
        },
        updateFirebase: @MainActor (Note) async throws -> Void = {
            try await FirebaseManager.shared.updateNote(note: $0)
        }
    ) async throws {
        try await syncData(
            getFirebaseData: getFirebaseData,
            getRealmData: getRealmData,
            saveToFirebase: saveToFirebase,
            updateFirebase: updateFirebase
        )
    }
}
