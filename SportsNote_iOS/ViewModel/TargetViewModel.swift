import SwiftUI
import RealmSwift
import Combine

@MainActor
class TargetViewModel: ObservableObject {
    @Published var targets: [Target] = []
    @Published var selectedTarget: Target?
    @Published var yearlyTargets: [Target] = []
    @Published var monthlyTargets: [Target] = []
    
    // 現在の年月を追跡するプロパティ
    @Published var currentYear: Int = Calendar.current.component(.year, from: Date())
    @Published var currentMonth: Int = Calendar.current.component(.month, from: Date())
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 年月が変わったときに自動的にデータを更新する
        $currentYear
            .combineLatest($currentMonth)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] year, month in
                self?.fetchTargets(year: year, month: month)
            }
            .store(in: &cancellables)
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
        // 重複する目標を削除
        let fetchedTargets = RealmManager.shared.fetchTargetsByYearMonth(year: year, month: month)
        if isYearlyTarget {
            let yearlyTargets = fetchedTargets.filter { $0.isYearlyTarget == true }
            yearlyTargets.forEach {
                deleteTarget(id: $0.targetID)
            }
        } else {
            let monthlyTargets = fetchedTargets.filter { $0.isYearlyTarget == false }
            monthlyTargets.forEach {
                deleteTarget(id: $0.targetID)
            }
        }
        
        // 保存
        let target = Target(
            title: title,
            year: year,
            month: month,
            isYearlyTarget: isYearlyTarget
        )
        RealmManager.shared.saveItem(target)
        
        // 保存後に同じ年月のデータを再取得して状態を更新
        if year == currentYear && month == currentMonth {
            fetchTargets(year: year, month: month)
        }

        // TODO: Firebaseにも保存する
    }
    
    /// 目標を削除
    /// - Parameter id: targetID
    private func deleteTarget(id: String) {
        RealmManager.shared.logicalDelete(id: id, type: Target.self)
        targets.removeAll(where: { $0.targetID == id })
        updateFilteredTargets()
    }
    
    /// 現在の年月を更新
    /// - Parameters:
    ///   - year: 年
    ///   - month: 月
    func updateCurrentPeriod(year: Int, month: Int) {
        currentYear = year
        currentMonth = month
    }
}
