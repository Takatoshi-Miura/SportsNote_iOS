import Combine
import RealmSwift
import SwiftUI

@MainActor
class TargetViewModel: ObservableObject {
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

    /// カレンダーに表示する年間目標、月間目標を取得
    /// - Parameters:
    ///   - year: 年
    ///   - month: 月
    func fetchTargets(year: Int, month: Int) {
        yearlyTargets = RealmManager.shared.getDataList(clazz: Target.self)
            .filter { $0.year == year && $0.isYearlyTarget }
        monthlyTargets = RealmManager.shared.getDataList(clazz: Target.self)
            .filter { $0.year == year && $0.month == month && !$0.isYearlyTarget }
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
        if isYearlyTarget {
            let yearlyTargets = RealmManager.shared.fetchYearlyTargets(year: year)
            yearlyTargets.forEach {
                deleteTarget(id: $0.targetID)
            }
        } else {
            let monthlyTargets = RealmManager.shared.fetchTargetsByYearMonth(year: year, month: month)
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

        // Firebaseに反映
        if Network.isOnline() && UserDefaultsManager.get(key: UserDefaultsManager.Keys.isLogin, defaultValue: false) {
            Task {
                try await FirebaseManager.shared.saveTarget(target: target)
            }
        }

        // 保存後に同じ年月のデータを再取得して状態を更新
        if year == currentYear && month == currentMonth {
            fetchTargets(year: year, month: month)
        }
    }

    /// 目標を削除
    /// - Parameter id: targetID
    private func deleteTarget(id: String) {
        RealmManager.shared.logicalDelete(id: id, type: Target.self)

        // Firebaseに反映
        if Network.isOnline() && UserDefaultsManager.get(key: UserDefaultsManager.Keys.isLogin, defaultValue: false) {
            Task {
                if let deletedTarget = RealmManager.shared.getObjectById(id: id, type: Target.self) {
                    try await FirebaseManager.shared.updateTarget(target: deletedTarget)
                }
            }
        }

        yearlyTargets.removeAll(where: { $0.targetID == id })
        monthlyTargets.removeAll(where: { $0.targetID == id })
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
