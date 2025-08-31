import Foundation
import RealmSwift
import SwiftUI

@MainActor
class MeasuresViewModel: ObservableObject, @preconcurrency BaseViewModelProtocol,
                        @preconcurrency CRUDViewModelProtocol, @preconcurrency FirebaseSyncable {
    typealias EntityType = Measures
    @Published var measuresList: [Measures] = []
    @Published var memos: [Memo] = []
    @Published var isLoading: Bool = false
    @Published var currentError: SportsNoteError?
    @Published var showingErrorAlert: Bool = false

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
            measuresList = try RealmManager.shared.getDataList(clazz: Measures.self)
            hideErrorAlert()
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "MeasuresViewModel-fetchData")
            return .failure(sportsNoteError)
        }
    }

    // MARK: - CRUDViewModelProtocol準拠

    /// 指定IDの対策を取得（プロトコル準拠）
    /// - Parameter id: 対策ID
    /// - Returns: Result
    func fetchById(id: String) async -> Result<Measures?, SportsNoteError> {
        do {
            let measures = try RealmManager.shared.getObjectById(id: id, type: Measures.self)
            return .success(measures)
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "MeasuresViewModel-fetchById")
            return .failure(sportsNoteError)
        }
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
        try? RealmManager.shared.saveItem(measures)

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
        let _ = await fetchData()
    }

    /// 対策保存処理（プロトコル準拠）
    /// - Parameters:
    ///   - entity: 保存するMeasures
    ///   - isUpdate: 更新かどうか
    /// - Returns: Result
    func save(_ entity: Measures, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // 1. Realm操作はMainActorで実行
            try RealmManager.shared.saveItem(entity)

            // 2. Firebase同期はバックグラウンドで実行
            Task {
                let result = await syncEntityToFirebase(entity, isUpdate: isUpdate)
                if case .failure(let error) = result {
                    // Firebase同期エラーは既存エラーがない場合のみ設定
                    await MainActor.run {
                        if currentError == nil {
                            showErrorAlert(error)
                        }
                    }
                }
            }

            // 3. UI更新
            measuresList = try RealmManager.shared.getDataList(clazz: Measures.self)

            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "MeasuresViewModel-save")
            return .failure(sportsNoteError)
        }
    }

    /// 対策削除処理（プロトコル準拠）
    /// - Parameter id: 削除する対策ID
    /// - Returns: Result
    func delete(id: String) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // 1. Realm操作はMainActorで実行
            try RealmManager.shared.logicalDelete(id: id, type: Measures.self)

            // 2. Firebase同期はバックグラウンドで実行
            Task {
                let measureResult = await fetchById(id: id)
                if case .success(let deletedMeasures) = measureResult, let deletedMeasures = deletedMeasures {
                    let result = await syncEntityToFirebase(deletedMeasures, isUpdate: true)
                    if case .failure(let error) = result {
                        await MainActor.run {
                            if currentError == nil {
                                showErrorAlert(error)
                            }
                        }
                    }
                }
            }

            // 3. UI更新
            measuresList.removeAll(where: { $0.measuresID == id })

            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "MeasuresViewModel-delete")
            return .failure(sportsNoteError)
        }
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

    // MARK: - FirebaseSyncable準拠

    /// 指定された対策をFirebaseに同期する
    /// - Parameters:
    ///   - entity: 同期する対策
    ///   - isUpdate: 更新かどうか
    /// - Returns: 同期処理の結果
    func syncEntityToFirebase(_ entity: Measures, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
        guard isOnlineAndLoggedIn else {
            return .success(())
        }

        do {
            if isUpdate {
                try await FirebaseManager.shared.updateMeasures(measures: entity)
            } else {
                try await FirebaseManager.shared.saveMeasures(measures: entity)
            }
            return .success(())
        } catch {
            let sportsNoteError = ErrorMapper.mapFirebaseError(error, context: "MeasuresViewModel-syncEntityToFirebase")
            return .failure(sportsNoteError)
        }
    }

    /// 全ての対策をFirebaseに同期する
    /// - Returns: 同期処理の結果
    func syncToFirebase() async -> Result<Void, SportsNoteError> {
        guard isOnlineAndLoggedIn else {
            return .success(())
        }

        do {
            let allMeasures = try RealmManager.shared.getDataList(clazz: Measures.self)
            for measures in allMeasures {
                let result = await syncEntityToFirebase(measures)
                if case .failure(let error) = result {
                    return .failure(error)
                }
            }
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "MeasuresViewModel-syncToFirebase")
            return .failure(sportsNoteError)
        }
    }
}
