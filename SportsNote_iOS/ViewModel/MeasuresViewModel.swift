import Foundation
import SwiftUI
import RealmSwift

@MainActor
class MeasuresViewModel: ObservableObject {
    @Published var measuresList: [Measures] = []
    @Published var memos: [Memo] = []
    
    init() {
        fetchAllMeasures()
    }
    
    /// 全ての対策を取得
    func fetchAllMeasures() {
        measuresList = RealmManager.shared.getDataList(clazz: Measures.self)
    }
    
    /// 対策をIDで取得
    /// - Parameter measuresID: 対策ID
    /// - Returns: 対策オブジェクト (見つからない場合はnil)
    func getMeasuresById(measuresID: String) -> Measures? {
        return RealmManager.shared.getObjectById(id: measuresID, type: Measures.self)
    }
    
    /// 課題IDに紐づく対策を取得
    /// - Parameter taskID: 課題ID
    /// - Returns: 対策のリスト
    func getMeasuresByTaskID(taskID: String) -> [Measures] {
        return RealmManager.shared.getMeasuresByTaskID(taskID: taskID)
    }
    
    /// 対策を保存する
    /// - Parameters:
    ///   - measuresID: 対策ID (新規作成時はnil)
    ///   - taskID: 課題ID
    ///   - title: 対策タイトル
    ///   - order: 並び順 (指定しない場合は自動計算)
    /// - Returns: 保存した対策
    @discardableResult
    func saveMeasures(
        measuresID: String? = nil,
        taskID: String,
        title: String,
        order: Int? = nil
    ) -> Measures {
        // 並び順が指定されていない場合は自動計算
        let newOrder = order ?? RealmManager.shared.getMeasuresByTaskID(taskID: taskID).count
        
        // 対策オブジェクトの作成
        let measures: Measures
        if let id = measuresID, let existingMeasures = getMeasuresById(measuresID: id) {
            // 更新の場合
            do {
                let realm = try Realm()
                try realm.write {
                    existingMeasures.title = title
                    existingMeasures.order = newOrder
                    existingMeasures.updated_at = Date()
                }
            } catch {
                print("Error updating measures: \(error)")
            }
            measures = existingMeasures
        } else {
            // 新規作成の場合
            measures = Measures(
                taskID: taskID,
                title: title,
                order: newOrder
            )
            
            // Realmに保存
            RealmManager.shared.saveItem(measures)
        }
        
        // Firebaseとの同期処理はiOS版の実装に基づいて必要に応じて追加
        
        // リストを更新
        fetchAllMeasures()
        
        return measures
    }
    
    /// 対策を論理削除
    /// - Parameter measuresID: 対策ID
    func deleteMeasures(measuresID: String) {
        RealmManager.shared.logicalDelete(id: measuresID, type: Measures.self)
        
        // リストから削除した対策を除外
        measuresList.removeAll(where: { $0.measuresID == measuresID })
        self.objectWillChange.send()
        
        // Firebaseとの同期処理はiOS版の実装に基づいて必要に応じて追加
    }
    
    // MARK: - Memo Management
    func fetchMemosByMeasuresID(measuresID: String) {
        memos = RealmManager.shared.getMemosByMeasuresID(measuresID: measuresID)
    }
    
    func addMemo(measuresID: String, detail: String, noteID: String) {
        let memo = Memo(
            measuresID: measuresID,
            noteID: noteID,
            detail: detail
        )
        
        RealmManager.shared.saveItem(memo)
        fetchMemosByMeasuresID(measuresID: measuresID)
    }
    
    func deleteMemo(id: String, measuresID: String) {
        RealmManager.shared.logicalDelete(id: id, type: Memo.self)
        fetchMemosByMeasuresID(measuresID: measuresID)
    }
    
    // MARK: - Title Update
    func updateTitle(_ newTitle: String, for measure: Measures) async {
        do {
            let realm = try await Realm()
            if let measures = realm.object(ofType: Measures.self, forPrimaryKey: measure.measuresID) {
                try realm.write {
                    measures.title = newTitle
                    measures.updated_at = Date()
                }
            }
        } catch {
            print("Error updating title: \(error)")
        }
    }
}
