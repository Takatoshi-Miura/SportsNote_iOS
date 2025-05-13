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
        
        // Firebaseへの同期
        if Network.isOnline() && UserDefaultsManager.get(key: UserDefaultsManager.Keys.isLogin, defaultValue: false) {
            Task {
                let isUpdate = measuresID != nil
                if isUpdate {
                    try await FirebaseManager.shared.updateMeasures(measures: measures)
                } else {
                    try await FirebaseManager.shared.saveMeasures(measures: measures)
                }
            }
        }
        
        // リストを更新
        fetchAllMeasures()
    }
    
    /// 対策を論理削除
    /// - Parameter id: 対策ID
    func deleteMeasures(id: String) {
        RealmManager.shared.logicalDelete(id: id, type: Measures.self)
        
        // Firebaseへの同期
        if Network.isOnline() && UserDefaultsManager.get(key: UserDefaultsManager.Keys.isLogin, defaultValue: false) {
            Task {
                if let deletedMeasures = RealmManager.shared.getObjectById(id: id, type: Measures.self) {
                    try await FirebaseManager.shared.updateMeasures(measures: deletedMeasures)
                }
            }
        }
        
        // リストから削除した対策を除外
        measuresList.removeAll(where: { $0.measuresID == id })
        self.objectWillChange.send()
    }
    
    /// 対策の並び順を更新
    /// - Parameter measures: 並び替え後の対策リスト
    func updateMeasuresOrder(measures: [Measures]) {
        guard !measures.isEmpty else { return }
        
        for (index, measure) in measures.enumerated() {
            saveMeasures(
                measuresID: measure.measuresID,
                taskID: measure.taskID,
                title: measure.title,
                order: index,
                created_at: measure.created_at
            )
        }
    }
}
