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
    
    /// 対策に紐づくメモを取得
    /// - Parameter measuresID: 対策ID
    func fetchMemosByMeasuresID(measuresID: String) {
        memos = RealmManager.shared.getMemosByMeasuresID(measuresID: measuresID)
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
    ///   - created_at: 作成日時
    /// - Returns: 保存した対策
    func saveMeasures(
        measuresID: String? = nil,
        taskID: String,
        title: String,
        order: Int? = nil,
        created_at: Date? = nil
    ) {
        let newMeasuresID = measuresID ?? UUID().uuidString
        let newOrder = order ?? RealmManager.shared.getMeasuresByTaskID(taskID: taskID).count
        let newCreatedAt = created_at ?? Date()
        
        let measures = Measures(
            measuresID: newMeasuresID,
            taskID: taskID,
            title: title,
            order: newOrder,
            created_at: newCreatedAt
        )
        RealmManager.shared.saveItem(measures)
        
        // TODO: Firebaseに保存
        
        // リストを更新
        fetchAllMeasures()
    }
    
    /// 対策を論理削除
    /// - Parameter measuresID: 対策ID
    func deleteMeasures(measuresID: String) {
        RealmManager.shared.logicalDelete(id: measuresID, type: Measures.self)
        
        // TODO: Firebaseに保存
        
        // リストから削除した対策を除外
        measuresList.removeAll(where: { $0.measuresID == measuresID })
        self.objectWillChange.send()
    }
}
