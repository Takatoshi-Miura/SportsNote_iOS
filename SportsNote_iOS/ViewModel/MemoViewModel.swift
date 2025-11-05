import Combine
import Foundation
import RealmSwift

@MainActor
class MemoViewModel: ObservableObject, BaseViewModelProtocol, CRUDViewModelProtocol, FirebaseSyncable {
    typealias EntityType = Memo
    @Published var memoList: [Memo] = []
    @Published var measuresMemoList: [MeasuresMemo] = []
    @Published var isLoading: Bool = false
    @Published var currentError: SportsNoteError?
    @Published var showingErrorAlert: Bool = false

    init() {
        // 自動データ取得は削除、View側で明示的に実行
    }

    // MARK: - BaseViewModelProtocol準拠

    /// データを取得（プロトコル準拠）
    /// - Returns: Result
    func fetchData() async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // Realm操作はMainActorで実行
            memoList = try RealmManager.shared.getDataList(clazz: Memo.self)
            hideErrorAlert()
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "MemoViewModel-fetchData")
            return .failure(sportsNoteError)
        }
    }

    /// 全てのメモを取得（既存インターフェースとの互換性のため）
    func fetchAllMemos() async -> Result<Void, SportsNoteError> {
        return await fetchData()
    }

    // MARK: - CRUDViewModelProtocol準拠

    /// エンティティを保存（新規作成・更新）
    /// - Parameters:
    ///   - entity: 保存するエンティティ
    ///   - isUpdate: 更新かどうか
    /// - Returns: Result
    func save(_ entity: Memo, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
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

            // UI更新
            memoList = try RealmManager.shared.getDataList(clazz: Memo.self)
            hideErrorAlert()
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "MemoViewModel-save")
            return .failure(sportsNoteError)
        }
    }

    /// 指定されたIDのエンティティを削除する（プロトコル準拠）
    /// - Parameter id: 削除するエンティティのID
    /// - Returns: Result
    func delete(id: String) async -> Result<Void, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        do {
            // 削除対象のメモを取得（Firebase同期用）
            let memoToDelete = try RealmManager.shared.getObjectById(id: id, type: Memo.self)

            // Realm操作はMainActorで実行
            try RealmManager.shared.logicalDelete(id: id, type: Memo.self)

            // Firebase同期を非同期で実行（MainActorを維持）
            if let memo = memoToDelete {
                Task {
                    let syncResult = await syncEntityToFirebase(memo, isUpdate: true)  // 論理削除なので更新として扱う
                    if case .failure(let error) = syncResult {
                        showErrorAlert(error)
                    }
                }
            }

            // UI更新 - 配列から削除
            memoList.removeAll(where: { $0.memoID == id })
            hideErrorAlert()
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "MemoViewModel-delete")
            return .failure(sportsNoteError)
        }
    }

    /// 指定されたIDのエンティティを取得する（プロトコル準拠）
    /// - Parameter id: 取得するエンティティのID
    /// - Returns: Result
    func fetchById(id: String) async -> Result<Memo?, SportsNoteError> {
        do {
            let memo = try RealmManager.shared.getObjectById(id: id, type: Memo.self)
            return .success(memo)
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "MemoViewModel-fetchById")
            return .failure(sportsNoteError)
        }
    }

    // MARK: - FirebaseSyncable準拠

    /// 指定されたエンティティをFirebaseに同期する
    /// - Parameters:
    ///   - entity: 同期するエンティティ
    ///   - isUpdate: 更新かどうか
    /// - Returns: 同期処理の結果
    func syncEntityToFirebase(_ entity: Memo, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
        guard isOnlineAndLoggedIn else { return .success(()) }

        do {
            if isUpdate {
                try await FirebaseManager.shared.updateMemo(memo: entity)
            } else {
                try await FirebaseManager.shared.saveMemo(memo: entity)
            }
            return .success(())
        } catch {
            let sportsNoteError = ErrorMapper.mapFirebaseError(error, context: "MemoViewModel-syncEntityToFirebase")
            return .failure(sportsNoteError)
        }
    }

    /// Firebaseへの同期処理を実行する
    /// - Returns: 同期処理の結果
    func syncToFirebase() async -> Result<Void, SportsNoteError> {
        guard isOnlineAndLoggedIn else { return .success(()) }

        do {
            let allMemos = try RealmManager.shared.getDataList(clazz: Memo.self)
            for memo in allMemos {
                let syncResult = await syncEntityToFirebase(memo)
                if case .failure(let error) = syncResult {
                    return .failure(error)
                }
            }
            return .success(())
        } catch {
            let sportsNoteError = convertToSportsNoteError(error, context: "MemoViewModel-syncToFirebase")
            return .failure(sportsNoteError)
        }
    }

    /// 対策IDに紐づくメモを取得（非Reactive版 - 下位互換性のため残す）
    /// - Parameter measuresID: 対策ID
    /// - Returns: Result<[MeasuresMemo], SportsNoteError>
    func getMemosByMeasuresID(measuresID: String) -> Result<[MeasuresMemo], SportsNoteError> {
        let memos = RealmManager.shared.getMemosByMeasuresID(measuresID: measuresID)
        var measuresMemoList = [MeasuresMemo]()

        for memo in memos {
            do {
                // Noteデータを取得
                if let note = try RealmManager.shared.getObjectById(id: memo.noteID, type: Note.self) {
                    let measuresMemo = MeasuresMemo(
                        memoID: memo.memoID,
                        measuresID: memo.measuresID,
                        noteID: memo.noteID,
                        detail: memo.detail,
                        date: note.date
                    )
                    measuresMemoList.append(measuresMemo)
                }
            } catch {
                // Note取得に失敗した場合はログ出力してスキップ
                print("Failed to get note for memo \(memo.memoID): \(error)")
                continue
            }
        }

        // 日付の降順でソート
        let sortedList = measuresMemoList.sorted { $0.date > $1.date }
        return .success(sortedList)
    }

    /// 対策IDに紐づくメモを取得してmeasuresMemoListを更新（Reactive版）
    /// - Parameter measuresID: 対策ID
    /// - Returns: Result<Void, SportsNoteError>
    func fetchMemosByMeasuresID(measuresID: String) async -> Result<Void, SportsNoteError> {
        let result = getMemosByMeasuresID(measuresID: measuresID)
        switch result {
        case .success(let memos):
            measuresMemoList = memos
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }

    /// メモを保存する（既存インターフェースとの互換性のため）
    /// - Parameters:
    ///   - memoID: メモID (新規作成時はnil)
    ///   - measuresID: 対策ID
    ///   - noteID: ノートID
    ///   - detail: メモ内容
    ///   - created_at: 作成日時
    /// - Returns: Result<Memo, SportsNoteError>
    func saveMemo(
        memoID: String? = nil,
        measuresID: String,
        noteID: String,
        detail: String,
        created_at: Date? = nil
    ) async -> Result<Memo, SportsNoteError> {
        isLoading = true
        defer { isLoading = false }

        let newMemoID = memoID ?? UUIDGenerator.generateID()
        let newCreatedAt = created_at ?? Date()
        let isUpdate = memoID != nil

        // 保存
        let memo = Memo(
            memoID: newMemoID,
            measuresID: measuresID,
            noteID: noteID,
            detail: detail,
            created_at: newCreatedAt
        )

        let saveResult = await save(memo, isUpdate: isUpdate)
        switch saveResult {
        case .success:
            // 対策に関連するメモリストを更新
            let memosResult = getMemosByMeasuresID(measuresID: measuresID)
            switch memosResult {
            case .success(let memos):
                measuresMemoList = memos
            case .failure(let error):
                showErrorAlert(error)
            }
            return .success(memo)
        case .failure(let error):
            return .failure(error)
        }
    }

    /// メモを論理削除（既存インターフェースとの互換性のため）
    /// - Parameter memoID: メモID
    /// - Returns: Result<Void, SportsNoteError>
    func deleteMemo(memoID: String) async -> Result<Void, SportsNoteError> {
        return await delete(id: memoID)
    }
}
