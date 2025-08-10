import RealmSwift
import SwiftUI

@MainActor
class GroupViewModel: ObservableObject, @preconcurrency BaseViewModelProtocol, @preconcurrency CRUDViewModelProtocol,
    @preconcurrency FirebaseSyncable
{
    typealias EntityType = Group
    @Published var groups: [Group] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentError: SportsNoteError?
    @Published var showingErrorAlert: Bool = false

    init() {
        Task {
            await fetchData()
        }
    }

    /// データを取得する基本メソッド
    func fetchData() async {
        isLoading = true

        do {
            // Realm操作はMainActorで実行
            groups = try RealmManager.shared.getDataList(clazz: Group.self)
        } catch let error {
            if let sportsNoteError = error as? SportsNoteError {
                handleSportsNoteError(sportsNoteError)
            } else {
                let mappedError = ErrorMapper.mapRealmError(error, context: "GroupViewModel-fetchData")
                handleSportsNoteError(mappedError)
            }
        }

        isLoading = false
    }

    /// グループ取得（同期版 - 既存のメソッドとの互換性のため）
    private func fetchGroups() {
        do {
            groups = try RealmManager.shared.getDataList(clazz: Group.self)
        } catch let error {
            if let sportsNoteError = error as? SportsNoteError {
                handleSportsNoteError(sportsNoteError)
            } else {
                let mappedError = ErrorMapper.mapRealmError(error, context: "GroupViewModel-fetchGroups")
                handleSportsNoteError(mappedError)
            }
        }
    }

    /// エンティティを保存（新規作成・更新）する
    func save(_ entity: Group, isUpdate: Bool = false) async throws {
        isLoading = true

        do {
            // 1. Realm操作はMainActorで実行
            try RealmManager.shared.saveItem(entity)

            // 2. Firebase同期のみバックグラウンドで実行
            if isOnlineAndLoggedIn {
                Task.detached {
                    try await FirebaseManager.shared.saveGroup(group: entity)
                }
            }

            // 3. UI更新
            groups = try RealmManager.shared.getDataList(clazz: Group.self)
        } catch let error {
            let sportsNoteError: SportsNoteError
            if let existingSportsNoteError = error as? SportsNoteError {
                sportsNoteError = existingSportsNoteError
            } else {
                sportsNoteError = ErrorMapper.mapRealmError(error, context: "GroupViewModel-save")
            }
            handleSportsNoteError(sportsNoteError)
            throw sportsNoteError
        }

        isLoading = false
    }

    /// グループ保存処理(更新も兼ねる) - 既存インターフェースとの互換性のため
    /// - Parameters:
    ///   - groupID: グループID
    ///   - title: タイトル
    ///   - color: カラー
    ///   - order: 並び順
    ///   - created_at: 作成日時
    func saveGroup(
        groupID: String? = nil,
        title: String,
        color: GroupColor,
        order: Int? = nil,
        created_at: Date? = nil
    ) {
        let newGroupID = groupID ?? UUID().uuidString
        let newOrder =
            order
            ?? {
                do {
                    return try RealmManager.shared.getCount(clazz: Group.self)
                } catch {
                    handleSportsNoteError(
                        ErrorMapper.mapRealmError(error, context: "GroupViewModel-saveGroup-getCount"))
                    return 0
                }
            }()
        let newCreatedAt = created_at ?? Date()

        let group = Group(
            groupID: newGroupID,
            title: title,
            color: color.rawValue,
            order: newOrder,
            created_at: newCreatedAt
        )

        Task {
            do {
                let isUpdate = groupID != nil
                try await save(group, isUpdate: isUpdate)
            } catch {
                handleError(error)
            }
        }
    }

    /// 指定されたIDのエンティティを削除する
    func delete(id: String) async throws {
        isLoading = true

        do {
            // 1. Realm操作はMainActorで実行
            try RealmManager.shared.logicalDelete(id: id, type: Group.self)

            // 2. Firebase同期のみバックグラウンドで実行
            if isOnlineAndLoggedIn {
                if let deletedGroup = try RealmManager.shared.getObjectById(id: id, type: Group.self) {
                    Task.detached {
                        try await FirebaseManager.shared.saveGroup(group: deletedGroup)
                    }
                }
            }

            // 3. UI更新
            groups = try RealmManager.shared.getDataList(clazz: Group.self)
        } catch let error {
            let sportsNoteError: SportsNoteError
            if let existingSportsNoteError = error as? SportsNoteError {
                sportsNoteError = existingSportsNoteError
            } else {
                sportsNoteError = ErrorMapper.mapRealmError(error, context: "GroupViewModel-delete")
            }
            handleSportsNoteError(sportsNoteError)
            throw sportsNoteError
        }

        isLoading = false
    }

    /// グループ削除処理 - 既存インターフェースとの互換性のため
    /// - Parameter id: グループID
    func deleteGroup(id: String) {
        Task {
            do {
                try await delete(id: id)
            } catch {
                handleError(error)
            }
        }
    }

    /// 指定されたIDのエンティティを取得する
    func fetchById(id: String) async -> Group? {
        do {
            return try RealmManager.shared.getObjectById(id: id, type: Group.self)
        } catch let error {
            if let sportsNoteError = error as? SportsNoteError {
                handleSportsNoteError(sportsNoteError)
            } else {
                let mappedError = ErrorMapper.mapRealmError(error, context: "GroupViewModel-fetchById")
                handleSportsNoteError(mappedError)
            }
            return nil
        }
    }

    /// Firebaseへの同期処理を実行する
    func syncToFirebase() async throws {
        guard isOnlineAndLoggedIn else { return }

        let allGroups = try RealmManager.shared.getDataList(clazz: Group.self)

        for group in allGroups {
            try await syncEntityToFirebase(group)
        }
    }

    /// 指定されたエンティティをFirebaseに同期する
    func syncEntityToFirebase(_ entity: Group, isUpdate: Bool = false) async throws {
        guard isOnlineAndLoggedIn else { return }

        if isUpdate {
            try await FirebaseManager.shared.updateGroup(group: entity)
        } else {
            try await FirebaseManager.shared.saveGroup(group: entity)
        }
    }
}
