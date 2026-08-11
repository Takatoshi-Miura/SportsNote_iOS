import Foundation

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
