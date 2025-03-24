import SwiftUI
import RealmSwift

@MainActor
class TargetViewModel: ObservableObject {
    @Published var targets: [Target] = []
    @Published var selectedTarget: Target?
    @Published var yearlyTargets: [Target] = []
    @Published var monthlyTargets: [Target] = []
    
    init() {
    }
    
    // MARK: - Fetch Methods
    
    func fetchTargets(year: Int, month: Int) {
        targets = RealmManager.shared.getDataList(clazz: Target.self).filter { $0.year == year && $0.month == month }
        updateFilteredTargets()
    }
    
    private func updateFilteredTargets() {
        yearlyTargets = targets.filter { $0.isYearlyTarget }
        monthlyTargets = targets.filter { !$0.isYearlyTarget }
    }
    
    // MARK: - CRUD Operations
    
    /// 目標保存処理
    /// - Parameters:
    ///   - title: タイトル
    ///   - year: 年
    ///   - month: 月
    ///   - isYearlyTarget: 年間目標かどうか
    func saveTarget(
        title: String,
        year: Int,
        month: Int,
        isYearlyTarget: Bool = false
    ) {
        let target = Target(
            title: title,
            year: year,
            month: month,
            isYearlyTarget: isYearlyTarget
        )
        RealmManager.shared.saveItem(target)

        // TODO: Firebaseにも保存する
    }
    
    func deleteTarget(id: String) {
        RealmManager.shared.logicalDelete(id: id, type: Target.self)
        targets.removeAll(where: { $0.targetID == id })
        updateFilteredTargets()
    }
}
