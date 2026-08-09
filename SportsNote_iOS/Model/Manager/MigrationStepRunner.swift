import Foundation

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
