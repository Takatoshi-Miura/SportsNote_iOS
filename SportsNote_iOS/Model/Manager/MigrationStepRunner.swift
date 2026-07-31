import Foundation

/// 旧データマイグレーションの「変換→旧データ削除」という制御フローを、
/// `MigrationManager`（Firebase依存）から切り離して独立にテストできるようにするための実行役
///
/// 変換（migrate）が`MigrationError`で失敗した場合、旧データ削除（markDeleted）を呼ばずに
/// 旧データを保持したまま処理を継続させる（issue #35: 必須フィールド欠損によるデータ恒久消失の防止）。
/// `MigrationError`以外のエラー（Firestore通信エラー等）はそのままrethrowし、
/// 既存の異常系挙動（`migrateAll()`全体の中断）を変えない。
@MainActor
struct MigrationStepRunner {

    /// ログ出力先（テストでは注入して呼び出し内容を検証する）
    private let logger: (String) -> Void

    init(logger: @escaping (String) -> Void = { print($0) }) {
        self.logger = logger
    }

    /// 1件の旧データについて、変換→旧データ削除を実行する
    /// - Parameters:
    ///   - entity: ログ出力用のエンティティ名（例: "Task"）
    ///   - documentID: ログ出力用の旧ドキュメントID
    ///   - migrate: 変換処理（`MigrationError.invalidData`をthrowした場合はスキップ扱いとする）
    ///   - markDeleted: 変換成功時にのみ実行する旧データ削除処理
    /// - Throws: `migrate`/`markDeleted`が`MigrationError`以外のエラーをthrowした場合、そのまま伝播する
    func run(
        entity: String,
        documentID: String,
        migrate: () async throws -> Void,
        markDeleted: () async throws -> Void
    ) async throws {
        do {
            try await migrate()
        } catch let error as MigrationError {
            logger("旧\(entity)データの変換に失敗したため、旧データを保持します: documentID=\(documentID), error=\(error)")
            return
        }
        try await markDeleted()
    }
}
