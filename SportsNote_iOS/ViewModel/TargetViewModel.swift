import Combine
import Foundation
import RealmSwift

@MainActor
class TargetViewModel: ObservableObject, BaseViewModelProtocol, CRUDViewModelProtocol, FirebaseSyncable {
    typealias EntityType = Target
    @Published var yearlyTargets: [Target] = []
    @Published var monthlyTargets: [Target] = []
    @Published var isLoading: Bool = false
    @Published var currentError: SportsNoteError?
    @Published var showingErrorAlert: Bool = false

    // 現在の年月を追跡するプロパティ
    @Published var currentYear: Int = Date().get(.year)
    @Published var currentMonth: Int = Date().get(.month)

    // Combine自動更新用
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 年月が変わったときに自動的にデータを更新する（新Resultパターン対応）
        $currentYear
            .combineLatest($currentMonth)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] year, month in
                Task { @MainActor in
                    let result = await self?.fetchTargetsByYearMonth(year: year, month: month)
                    if case .failure(let error) = result {
                        self?.showErrorAlert(error)
                    }
                }
            }
            .store(in: &cancellables)

        observeClearAllData(cancellables: &cancellables)
    }

    /// Realmオブジェクトの参照をクリア
    func clearRealmReferences() {
        yearlyTargets = []
        monthlyTargets = []
    }

    // MARK: - BaseViewModelProtocol準拠

    /// データを取得（プロトコル準拠）
    /// - Returns: Result
    func fetchData() async -> Result<Void, SportsNoteError> {
        await fetchDataDefault(context: "TargetViewModel-fetchData") {
            // Realm操作はMainActorで実行
            let allTargets = try RealmManager.shared.getDataList(clazz: Target.self)

            // 現在の年月に基づいてフィルタリング
            self.yearlyTargets = allTargets.filter { $0.year == self.currentYear && $0.isYearlyTarget }
            self.monthlyTargets = allTargets.filter {
                $0.year == self.currentYear && $0.month == self.currentMonth && !$0.isYearlyTarget
            }
        } onSuccess: {
            self.hideErrorAlert()
        }
    }

    /// 指定した年月の目標を取得
    /// - Parameters:
    ///   - year: 年
    ///   - month: 月
    /// - Returns: Result
    func fetchTargetsByYearMonth(year: Int, month: Int) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // Realm操作はMainActorで実行
            let allTargets = try RealmManager.shared.getDataList(clazz: Target.self)

            // 指定した年月に基づいてフィルタリング
            yearlyTargets = allTargets.filter { $0.year == year && $0.isYearlyTarget }
            monthlyTargets = allTargets.filter { $0.year == year && $0.month == month && !$0.isYearlyTarget }

            hideErrorAlert()
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "TargetViewModel-fetchTargetsByYearMonth")
            return .failure(sportsNoteError)
        }
    }

    // MARK: - CRUDViewModelProtocol準拠

    /// エンティティを保存（新規作成・更新）
    /// - Parameters:
    ///   - entity: 保存するエンティティ
    ///   - isUpdate: 更新かどうか
    /// - Returns: Result
    func save(_ entity: Target, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
        await saveDefault(entity, isUpdate: isUpdate, context: "TargetViewModel-save") {
            // Firebase同期はバックグラウンドで実行
            self.performBackgroundSync(entity, isUpdate: isUpdate)

            // UI更新 - 現在の年月のデータを再取得
            let allTargets = try RealmManager.shared.getDataList(clazz: Target.self)
            self.yearlyTargets = allTargets.filter { $0.year == self.currentYear && $0.isYearlyTarget }
            self.monthlyTargets = allTargets.filter {
                $0.year == self.currentYear && $0.month == self.currentMonth && !$0.isYearlyTarget
            }

            self.hideErrorAlert()
        }
    }

    /// 目標保存処理（既存インターフェースとの互換性のため）
    /// - Parameters:
    ///   - title: タイトル
    ///   - year: 年
    ///   - month: 月
    ///   - isYearlyTarget: 年間目標かどうか
    /// - Returns: Result
    func saveTarget(
        title: String,
        year: Int,
        month: Int,
        isYearlyTarget: Bool = false
    ) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        // 重複する目標を削除（Realm操作はMainActorで実行）
        if isYearlyTarget {
            let yearlyTargets: [Target]
            do {
                yearlyTargets = try RealmManager.shared.fetchYearlyTargets(year: year)
            } catch {
                return .failure(convertToSportsNoteError(error, context: "TargetViewModel-saveTarget"))
            }
            for existingTarget in yearlyTargets {
                let deleteResult = await delete(id: existingTarget.targetID)
                if case .failure(let error) = deleteResult {
                    return .failure(error)
                }
            }
        } else {
            let monthlyTargets: [Target]
            do {
                monthlyTargets = try RealmManager.shared.fetchTargetsByYearMonth(year: year, month: month)
            } catch {
                return .failure(convertToSportsNoteError(error, context: "TargetViewModel-saveTarget"))
            }
            for existingTarget in monthlyTargets {
                let deleteResult = await delete(id: existingTarget.targetID)
                if case .failure(let error) = deleteResult {
                    return .failure(error)
                }
            }
        }

        // 新しい目標を作成して保存
        let target = Target(
            title: title,
            year: year,
            month: month,
            isYearlyTarget: isYearlyTarget
        )

        let saveResult = await save(target, isUpdate: false)
        return saveResult
    }

    /// 指定されたIDのエンティティを削除する（プロトコル準拠）
    /// - Parameter id: 削除するエンティティのID
    /// - Returns: Result
    func delete(id: String) async -> Result<Void, SportsNoteError> {
        await deleteDefault(
            id: id,
            context: "TargetViewModel-delete",
            removeFromLocalCache: {
                // UI更新 - 配列から削除
                self.yearlyTargets.removeAll(where: { $0.targetID == id })
                self.monthlyTargets.removeAll(where: { $0.targetID == id })
            },
            onSuccess: {
                self.hideErrorAlert()
            }
        )
    }

    /// 指定されたIDのエンティティを取得する（プロトコル準拠）
    /// - Parameter id: 取得するエンティティのID
    /// - Returns: Result
    func fetchById(id: String) async -> Result<Target?, SportsNoteError> {
        await fetchByIdDefault(id: id, context: "TargetViewModel-fetchById")
    }

    /// 現在の年月を更新
    /// - Parameters:
    ///   - year: 年
    ///   - month: 月
    func updateCurrentPeriod(year: Int, month: Int) {
        currentYear = year
        currentMonth = month
    }

    // MARK: - FirebaseSyncable準拠

    /// 指定されたエンティティをFirebaseに同期する
    /// - Parameters:
    ///   - entity: 同期するエンティティ
    ///   - isUpdate: 更新かどうか
    /// - Returns: 同期処理の結果
    func syncEntityToFirebase(_ entity: Target, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
        await syncEntityToFirebaseDefault(
            isUpdate: isUpdate,
            context: "TargetViewModel-syncEntityToFirebase",
            updateAction: { try await FirebaseManager.shared.updateTarget(target: entity) },
            saveAction: { try await FirebaseManager.shared.saveTarget(target: entity) }
        )
    }

    /// Firebaseへの同期処理を実行する
    /// - Returns: 同期処理の結果
    func syncToFirebase() async -> Result<Void, SportsNoteError> {
        await syncToFirebaseDefault(context: "TargetViewModel-syncToFirebase")
    }
}
