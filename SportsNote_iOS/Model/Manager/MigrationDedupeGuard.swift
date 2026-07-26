import Foundation

/// 旧ドキュメント単位でのマイグレーション重複実行を防ぐガード
///
/// `MigrationManager.migrateAll()`は「新形式への変換・保存（migrate）」と
/// 「旧ドキュメントの削除フラグ更新（markDeleted）」を別々のFirestore操作として実行しており、
/// migrateが成功した直後にmarkDeletedだけが失敗すると、次回のマイグレーション再実行時に
/// 同一の旧ドキュメントが再度migrateされ、新規IDで重複レコードが作成されてしまう。
///
/// このガードは、旧ドキュメントIDごとに「migrate済みかどうか」をUserDefaultsに記録し、
/// 既にmigrate済みの場合はmigrateをスキップしてmarkDeletedのみ再試行することで、
/// 同一旧ドキュメントに対するmigrateの重複実行を防ぐ。
/// Firestore/Realmのいずれにも依存しないため、単体テストが容易な独立コンポーネントとして切り出している。
/// 呼び出し元の`MigrationManager`が`@MainActor`のため、クロージャの受け渡しで
/// アクター境界を跨がないよう本型自体も`@MainActor`にしている。
@MainActor
struct MigrationDedupeGuard {

    private func key(entity: String, documentID: String) -> String {
        "migratedOldDoc_\(entity)_\(documentID)"
    }

    /// 指定した旧ドキュメントが既にmigrate済みかどうか
    func isAlreadyMigrated(entity: String, documentID: String) -> Bool {
        UserDefaultsManager.get(key: key(entity: entity, documentID: documentID), defaultValue: false)
    }

    /// 指定した旧ドキュメントをmigrate済みとして記録する
    func markMigrated(entity: String, documentID: String) {
        UserDefaultsManager.set(key: key(entity: entity, documentID: documentID), value: true)
    }

    /// 指定した旧ドキュメントのmigrate済みフラグを削除する
    func clearMigrated(entity: String, documentID: String) {
        UserDefaultsManager.remove(key: key(entity: entity, documentID: documentID))
    }

    /// migrate → (成功したら)migrate済みフラグ記録 → markDeleted → (成功したら)フラグ削除、の順で実行する
    ///
    /// 既にmigrate済みフラグが立っている場合はmigrateをスキップし、markDeletedのみ再試行する。
    /// これにより、migrate成功後にmarkDeletedだけが失敗して再実行された場合でも、
    /// migrateが2度実行されることはない。
    ///
    /// - Parameters:
    ///   - entity: エンティティ種別を表す識別子（"Task"/"Target"/"Note"等）。旧ドキュメントIDと組み合わせてフラグキーを構成する
    ///   - documentID: 旧Firestoreドキュメントのドキュメント ID
    ///   - migrate: 新形式への変換・保存処理
    ///   - markDeleted: 旧ドキュメントの削除フラグ更新処理
    func run(
        entity: String,
        documentID: String,
        migrate: () async throws -> Void,
        markDeleted: () async throws -> Void
    ) async throws {
        if !isAlreadyMigrated(entity: entity, documentID: documentID) {
            try await migrate()
            markMigrated(entity: entity, documentID: documentID)
        }
        try await markDeleted()
        clearMigrated(entity: entity, documentID: documentID)
    }
}
