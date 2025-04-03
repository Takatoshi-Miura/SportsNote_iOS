import Foundation
import SwiftUI
import RealmSwift

@MainActor
class MemoViewModel: ObservableObject {
    @Published var memoList: [Memo] = []
    @Published var measuresMemoList: [MeasuresMemo] = []
    
    init() {
        fetchAllMemos()
    }
    
    /// 全てのメモを取得
    func fetchAllMemos() {
        memoList = RealmManager.shared.getDataList(clazz: Memo.self)
    }
    
    /// 対策IDに紐づくメモを取得
    /// - Parameter measuresID: 対策ID
    /// - Returns: メモのリスト
    func getMemosByMeasuresID(measuresID: String) -> [MeasuresMemo] {
        let memos = RealmManager.shared.getMemosByMeasuresID(measuresID: measuresID)
        var measuresMemoList = [MeasuresMemo]()
        
        for memo in memos {
            // Noteデータを取得
            if let note = RealmManager.shared.getObjectById(id: memo.noteID, type: Note.self) {
                let measuresMemo = MeasuresMemo(
                    memoID: memo.memoID,
                    measuresID: memo.measuresID,
                    noteID: memo.noteID,
                    detail: memo.detail,
                    date: note.date
                )
                measuresMemoList.append(measuresMemo)
            }
        }
        
        // 日付の降順でソート
        return measuresMemoList.sorted { $0.date > $1.date }
    }
    
    /// メモを保存する
    /// - Parameters:
    ///   - memoID: メモID (新規作成時はnil)
    ///   - measuresID: 対策ID
    ///   - noteID: ノートID
    ///   - detail: メモ内容
    ///   - created_at: 作成日時
    /// - Returns: 保存したメモ
    func saveMemo(
        memoID: String? = nil,
        measuresID: String,
        noteID: String,
        detail: String,
        created_at: Date? = nil
    ) -> Memo {
        let newMemoID = memoID ?? UUID().uuidString
        let newCreatedAt = created_at ?? Date()
        
        // 保存
        let memo = Memo(
            memoID: newMemoID,
            measuresID: measuresID,
            noteID: noteID,
            detail: detail,
            created_at: newCreatedAt
        )
        RealmManager.shared.saveItem(memo)
        
        // TODO: Firebaseの処理を追加
        
        // リストを更新
        fetchAllMemos()
        
        // 対策に関連するメモリストを更新
        measuresMemoList = getMemosByMeasuresID(measuresID: measuresID)
        
        return memo
    }
    
    /// メモを論理削除
    /// - Parameter memoID: メモID
    func deleteMemo(memoID: String) {
        RealmManager.shared.logicalDelete(id: memoID, type: Memo.self)
        
        // TODO: Firebaseの処理を追加
        
        // リストから削除したメモを除外
        memoList.removeAll(where: { $0.memoID == memoID })
        
        self.objectWillChange.send()
    }
}
