import Foundation
import SwiftUI
import RealmSwift

/// メモ管理用ViewModel
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
    
    /// メモをIDで取得
    /// - Parameter memoID: メモID
    /// - Returns: メモオブジェクト (見つからない場合はnil)
    func getMemoById(memoID: String) -> Memo? {
        return RealmManager.shared.getObjectById(id: memoID, type: Memo.self)
    }
    
    /// メモを保存する
    /// - Parameters:
    ///   - memoID: メモID (新規作成時はnil)
    ///   - measuresID: 対策ID
    ///   - noteID: ノートID
    ///   - detail: メモ内容
    /// - Returns: 保存したメモ
    @discardableResult
    func saveMemo(
        memoID: String? = nil,
        measuresID: String,
        noteID: String,
        detail: String
    ) -> Memo {
        // メモオブジェクトの作成
        let memo: Memo
        if let id = memoID, let existingMemo = getMemoById(memoID: id) {
            // 更新の場合
            do {
                let realm = try Realm()
                try realm.write {
                    existingMemo.detail = detail
                    existingMemo.updated_at = Date()
                }
            } catch {
                print("Error updating memo: \(error)")
            }
            memo = existingMemo
        } else {
            // 新規作成の場合
            memo = Memo(
                measuresID: measuresID,
                noteID: noteID,
                detail: detail
            )
            
            // Realmに保存
            RealmManager.shared.saveItem(memo)
        }
        
        // Firebaseとの同期処理はiOS版の実装に基づいて必要に応じて追加
        
        // リストを更新
        fetchAllMemos()
        
        // 対策に関連するメモリストを更新
        self.measuresMemoList = getMemosByMeasuresID(measuresID: measuresID)
        
        return memo
    }
    
    /// メモを論理削除
    /// - Parameter memoID: メモID
    func deleteMemo(memoID: String) {
        // 削除前に関連する対策IDを取得
        var measuresID: String?
        if let memo = getMemoById(memoID: memoID) {
            measuresID = memo.measuresID
        }
        
        // メモを論理削除
        RealmManager.shared.logicalDelete(id: memoID, type: Memo.self)
        
        // リストから削除したメモを除外
        memoList.removeAll(where: { $0.memoID == memoID })
        
        // 対策に関連するメモリストを更新
        if let id = measuresID {
            self.measuresMemoList = getMemosByMeasuresID(measuresID: id)
        }
        
        self.objectWillChange.send()
        
        // Firebaseとの同期処理はiOS版の実装に基づいて必要に応じて追加
    }
}