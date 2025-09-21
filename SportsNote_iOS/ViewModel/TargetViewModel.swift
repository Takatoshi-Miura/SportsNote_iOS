import Combine
import RealmSwift
import SwiftUI

@MainActor
class TargetViewModel: ObservableObject, @preconcurrency BaseViewModelProtocol, @preconcurrency CRUDViewModelProtocol,
    @preconcurrency FirebaseSyncable
{
    typealias EntityType = Target
    @Published var yearlyTargets: [Target] = []
    @Published var monthlyTargets: [Target] = []
    @Published var isLoading: Bool = false
    @Published var currentError: SportsNoteError?
    @Published var showingErrorAlert: Bool = false

    // 現在の年月を追跡するプロパティ
    @Published var currentYear: Int = Calendar.current.component(.year, from: Date())
    @Published var currentMonth: Int = Calendar.current.component(.month, from: Date())

    init() {
        // 初期化のみ実行、データ取得はView側で明示的に実行
    }

    // MARK: - BaseViewModelProtocol準拠

    /// データを取得（プロトコル準拠）
    /// - Returns: Result
    func fetchData() async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // Realm操作はMainActorで実行
            let allTargets = try RealmManager.shared.getDataList(clazz: Target.self)

            // 現在の年月に基づいてフィルタリング
            yearlyTargets = allTargets.filter { $0.year == currentYear && $0.isYearlyTarget }
            monthlyTargets = allTargets.filter {
                $0.year == currentYear && $0.month == currentMonth && !$0.isYearlyTarget
            }

            hideErrorAlert()
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "TargetViewModel-fetchData")
            return .failure(sportsNoteError)
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
        isLoading = true
        defer { isLoading = false }

        do {
            // Realm操作はMainActorで実行
            try RealmManager.shared.saveItem(entity)

            // Firebase同期を非同期で実行（MainActorを維持）
            Task {
                let syncResult = await syncEntityToFirebase(entity, isUpdate: isUpdate)
                if case .failure(let error) = syncResult {
                    showErrorAlert(error)
                }
            }

            // UI更新 - 現在の年月のデータを再取得
            let allTargets = try RealmManager.shared.getDataList(clazz: Target.self)
            yearlyTargets = allTargets.filter { $0.year == currentYear && $0.isYearlyTarget }
            monthlyTargets = allTargets.filter {
                $0.year == currentYear && $0.month == currentMonth && !$0.isYearlyTarget
            }

            hideErrorAlert()
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "TargetViewModel-save")
            return .failure(sportsNoteError)
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
            let yearlyTargets = RealmManager.shared.fetchYearlyTargets(year: year)
            for existingTarget in yearlyTargets {
                let deleteResult = await delete(id: existingTarget.targetID)
                if case .failure(let error) = deleteResult {
                    return .failure(error)
                }
            }
        } else {
            let monthlyTargets = RealmManager.shared.fetchTargetsByYearMonth(year: year, month: month)
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
        isLoading = true
        defer { isLoading = false }

        do {
            // 削除対象の目標を取得（Firebase同期用）
            let targetToDelete = try RealmManager.shared.getObjectById(id: id, type: Target.self)

            // Realm操作はMainActorで実行
            try RealmManager.shared.logicalDelete(id: id, type: Target.self)

            // Firebase同期を非同期で実行（MainActorを維持）
            if let target = targetToDelete {
                Task {
                    let syncResult = await syncEntityToFirebase(target, isUpdate: true)  // 論理削除なので更新として扱う
                    if case .failure(let error) = syncResult {
                        showErrorAlert(error)
                    }
                }
            }

            // UI更新 - 配列から削除
            yearlyTargets.removeAll(where: { $0.targetID == id })
            monthlyTargets.removeAll(where: { $0.targetID == id })

            hideErrorAlert()
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "TargetViewModel-delete")
            return .failure(sportsNoteError)
        }
    }

    /// 指定されたIDのエンティティを取得する（プロトコル準拠）
    /// - Parameter id: 取得するエンティティのID
    /// - Returns: Result
    func fetchById(id: String) async -> Result<Target?, SportsNoteError> {
        do {
            let target = try RealmManager.shared.getObjectById(id: id, type: Target.self)
            return .success(target)
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "TargetViewModel-fetchById")
            return .failure(sportsNoteError)
        }
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
        guard isOnlineAndLoggedIn else { return .success(()) }

        do {
            if isUpdate {
                try await FirebaseManager.shared.updateTarget(target: entity)
            } else {
                try await FirebaseManager.shared.saveTarget(target: entity)
            }
            return .success(())
        } catch {
            let sportsNoteError = ErrorMapper.mapFirebaseError(error, context: "TargetViewModel-syncEntityToFirebase")
            return .failure(sportsNoteError)
        }
    }

    /// Firebaseへの同期処理を実行する
    /// - Returns: 同期処理の結果
    func syncToFirebase() async -> Result<Void, SportsNoteError> {
        guard isOnlineAndLoggedIn else { return .success(()) }

        do {
            let allTargets = try RealmManager.shared.getDataList(clazz: Target.self)
            for target in allTargets {
                let syncResult = await syncEntityToFirebase(target)
                if case .failure(let error) = syncResult {
                    return .failure(error)
                }
            }
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "TargetViewModel-syncToFirebase")
            return .failure(sportsNoteError)
        }
    }
}
