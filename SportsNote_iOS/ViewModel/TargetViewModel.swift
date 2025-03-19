import SwiftUI
import RealmSwift

@MainActor
class TargetViewModel: ObservableObject {
    @Published var targets: [Target] = []
    @Published var selectedTarget: Target?
    @Published var yearlyTargets: [Target] = []
    @Published var monthlyTargets: [Target] = []
    
    private let realmManager = RealmManager.shared
    
    init() {
    }
    
    // MARK: - Fetch Methods
    
    func fetchTargets(year: Int, month: Int) {
        targets = realmManager.getDataList(clazz: Target.self).filter { $0.year == year && $0.month == month }
        updateFilteredTargets()
    }
    
    private func updateFilteredTargets() {
        yearlyTargets = targets.filter { $0.isYearlyTarget }
        monthlyTargets = targets.filter { !$0.isYearlyTarget }
    }
    
    // MARK: - CRUD Operations
    
    func createTarget(title: String, year: Int, month: Int, isYearlyTarget: Bool = false) {
        let target = Target()
        target.title = title
        target.year = year
        target.month = month
        target.isYearlyTarget = isYearlyTarget
        
        realmManager.saveItem(target)
    }
    
    func updateTarget(_ target: Target, title: String, year: Int, month: Int, isYearlyTarget: Bool = false) {
        target.title = title
        target.year = year
        target.month = month
        target.isYearlyTarget = isYearlyTarget
        
        realmManager.saveItem(target)
    }
    
    func deleteTarget(id: String) {
        realmManager.logicalDelete(id: id, type: Target.self)
        targets.removeAll(where: { $0.targetID == id })
        updateFilteredTargets()
    }
    
    // MARK: - Target Detail Methods
    
    func loadTarget(id: String) {
        selectedTarget = realmManager.getObjectById(id: id, type: Target.self)
    }
}
