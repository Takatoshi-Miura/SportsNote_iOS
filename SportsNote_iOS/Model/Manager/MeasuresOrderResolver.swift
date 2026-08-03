import Foundation

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
