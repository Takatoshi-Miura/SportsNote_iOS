import Foundation

/// 旧データマイグレーション処理専用のエラー型
/// `MigrationManager`の各migrateXxxメソッドが必須フィールドの欠損・型不一致を検知した際にthrowする
enum MigrationError: Error {
    /// 旧Firestoreドキュメントの必須フィールドが欠損・型不一致で変換できなかった
    case invalidData(entity: String, documentID: String)
}
