import RealmSwift
import SwiftUI

@MainActor
class GroupViewModel: ObservableObject, @preconcurrency BaseViewModelProtocol, @preconcurrency CRUDViewModelProtocol,
    @preconcurrency FirebaseSyncable
{
    typealias EntityType = Group
    @Published var groups: [Group] = []
    @Published var isLoading: Bool = false
    @Published var currentError: SportsNoteError?
    @Published var showingErrorAlert: Bool = false

    init() {
        // 初期化のみ実行、データ取得はView側で明示的に実行
    }
    
    // MARK: - CURD処理

    /// データを取得
    /// - Returns: Result
    func fetchData() async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        let result: Result<Void, SportsNoteError>
        do {
            // Realm操作はMainActorで実行
            groups = try RealmManager.shared.getDataList(clazz: Group.self)
            result = .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "GroupViewModel-fetchData")
            result = .failure(sportsNoteError)
        }

        updateErrorState(for: result)
        return result
    }

    /// グループ保存処理(更新も兼ねる) - 既存インターフェースとの互換性のため
    /// - Parameters:
    ///   - groupID: グループID
    ///   - title: タイトル
    ///   - color: カラー
    ///   - order: 並び順
    ///   - created_at: 作成日時
    /// - Returns: Result
    func saveGroup(
        groupID: String? = nil,
        title: String,
        color: GroupColor,
        order: Int? = nil,
        created_at: Date? = nil
    ) async -> Result<Void, SportsNoteError> {
        let newGroupID = groupID ?? UUID().uuidString
        let newOrder = order ?? getDefaultOrder()
        let newCreatedAt = created_at ?? Date()

        let group = Group(
            groupID: newGroupID,
            title: title,
            color: color.rawValue,
            order: newOrder,
            created_at: newCreatedAt
        )

        let isUpdate = groupID != nil
        return await save(group, isUpdate: isUpdate)
    }

    /// デフォルトの並び順を取得する
    /// - Returns: 並び順
    private func getDefaultOrder() -> Int {
        do {
            return try RealmManager.shared.getCount(clazz: Group.self)
        } catch {
            // エラー時は0を返す（デフォルト値）
            return 0
        }
    }

    /// エンティティを保存（新規作成・更新）
    /// - Parameters:
    ///   - entity: エンティティ
    ///   - isUpdate: 更新要否
    /// - Returns: Result
    func save(_ entity: Group, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        let result: Result<Void, SportsNoteError>
        do {
            // Realm操作はMainActorで実行
            try RealmManager.shared.saveItem(entity)

            // Firebase同期のみバックグラウンドで実行
            Task.detached { [weak self] in
                let syncResult = await self?.syncEntityToFirebase(entity, isUpdate: isUpdate)
                if case .failure(let error) = syncResult {
                    await MainActor.run { [weak self] in
                        if self?.currentError == nil {
                            self?.currentError = error
                            self?.showingErrorAlert = true
                        }
                    }
                }
            }

            // UI更新
            groups = try RealmManager.shared.getDataList(clazz: Group.self)
            result = .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "GroupViewModel-save")
            result = .failure(sportsNoteError)
        }

        updateErrorState(for: result)
        return result
    }

    /// エンティティをFirebaseに同期する
    /// - Parameters:
    ///   - entity: エンティティ
    ///   - isUpdate: 更新要否
    func syncEntityToFirebase(_ entity: Group, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
        guard isOnlineAndLoggedIn else { return .success(()) }

        do {
            if isUpdate {
                try await FirebaseManager.shared.updateGroup(group: entity)
            } else {
                try await FirebaseManager.shared.saveGroup(group: entity)
            }
            return .success(())
        } catch {
            let sportsNoteError = ErrorMapper.mapFirebaseError(error, context: "GroupViewModel-syncEntityToFirebase")
            return .failure(sportsNoteError)
        }
    }

    /// 指定されたIDのエンティティを削除
    /// - Parameter id: ID
    /// - Returns: Result
    func delete(id: String) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        let result: Result<Void, SportsNoteError>
        do {
            // 1. Realm操作はMainActorで実行
            try RealmManager.shared.logicalDelete(id: id, type: Group.self)

            // 2. Firebase同期のみバックグラウンドで実行
            if let deletedGroup = try RealmManager.shared.getObjectById(id: id, type: Group.self) {
                Task.detached { [weak self] in
                    let syncResult = await self?.syncEntityToFirebase(deletedGroup, isUpdate: true)
                    if case .failure(let error) = syncResult {
                        await MainActor.run { [weak self] in
                            if self?.currentError == nil {
                                self?.currentError = error
                                self?.showingErrorAlert = true
                            }
                        }
                    }
                }
            }

            // 3. UI更新
            groups = try RealmManager.shared.getDataList(clazz: Group.self)
            result = .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "GroupViewModel-delete")
            result = .failure(sportsNoteError)
        }

        updateErrorState(for: result)
        return result
    }

    /// 指定されたIDのエンティティを取得
    /// - Parameter id: ID
    /// - Returns: Result
    func fetchById(id: String) async -> Result<Group?, SportsNoteError> {
        let result: Result<Group?, SportsNoteError>
        do {
            let group = try RealmManager.shared.getObjectById(id: id, type: Group.self)
            result = .success(group)
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "GroupViewModel-fetchById")
            result = .failure(sportsNoteError)
        }

        // Void型に変換してエラー状態を更新
        let voidResult = result.map { _ in () }
        updateErrorState(for: voidResult)
        return result
    }

    /// Firebaseへの同期処理を実行
    func syncToFirebase() async -> Result<Void, SportsNoteError> {
        guard isOnlineAndLoggedIn else { return .success(()) }

        do {
            let allGroups = try RealmManager.shared.getDataList(clazz: Group.self)

            for group in allGroups {
                let result = await syncEntityToFirebase(group)
                if case .failure(let error) = result {
                    return .failure(error)
                }
            }
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "GroupViewModel-syncToFirebase")
            return .failure(sportsNoteError)
        }
    }
}

extension GroupViewModel {
    
    // MARK: - エラー処理

    /// 結果に基づいてエラー状態を自動更新する
    /// - Parameter result: Result
    private func updateErrorState(for result: Result<Void, SportsNoteError>) {
        switch result {
        case .success:
            currentError = nil
            showingErrorAlert = false
        case .failure(let error):
            currentError = error
            showingErrorAlert = true
        }
    }

}
