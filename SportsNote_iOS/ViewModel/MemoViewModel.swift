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

    private var cancellables = Set<AnyCancellable>()

    init() {
        // 自動データ取得は削除、View側で明示的に実行
        observeClearAllData(cancellables: &cancellables)
    }

    /// Realmオブジェクトの参照をクリア
    func clearRealmReferences() {
        memoList = []
        measuresMemoList = []
    }

    // MARK: - BaseViewModelProtocol準拠

    /// データを取得（プロトコル準拠）
    /// - Returns: Result
    func fetchData() async -> Result<Void, SportsNoteError> {
        await fetchDataDefault(context: "MemoViewModel-fetchData") {
            // Realm操作はMainActorで実行
            self.memoList = try RealmManager.shared.getDataList(clazz: Memo.self)
        } onSuccess: {
            self.hideErrorAlert()
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
        await saveDefault(entity, isUpdate: isUpdate, context: "MemoViewModel-save") {
            // Firebase同期はバックグラウンドで実行
            self.performBackgroundSync(entity, isUpdate: isUpdate)

            // UI更新
            self.memoList = try RealmManager.shared.getDataList(clazz: Memo.self)
            self.hideErrorAlert()
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

            // Firebase同期はバックグラウンドで実行（論理削除なので更新として扱う）
            if let memo = memoToDelete {
                Task {
                    performBackgroundSync(memo, isUpdate: true)
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
        await fetchByIdDefault(id: id, context: "MemoViewModel-fetchById")
    }

    // MARK: - FirebaseSyncable準拠

    /// 指定されたエンティティをFirebaseに同期する
    /// - Parameters:
    ///   - entity: 同期するエンティティ
    ///   - isUpdate: 更新かどうか
    /// - Returns: 同期処理の結果
    func syncEntityToFirebase(_ entity: Memo, isUpdate: Bool = false) async -> Result<Void, SportsNoteError> {
        await syncEntityToFirebaseDefault(
            isUpdate: isUpdate,
            context: "MemoViewModel-syncEntityToFirebase",
            updateAction: { try await FirebaseManager.shared.updateMemo(memo: entity) },
            saveAction: { try await FirebaseManager.shared.saveMemo(memo: entity) }
        )
    }

    /// Firebaseへの同期処理を実行する
    /// - Returns: 同期処理の結果
    func syncToFirebase() async -> Result<Void, SportsNoteError> {
        await syncToFirebaseDefault(context: "MemoViewModel-syncToFirebase")
    }

    /// 対策IDに紐づくメモを取得（非Reactive版 - 下位互換性のため残す）
    /// - Parameter measuresID: 対策ID
    /// - Returns: Result<[MeasuresMemo], SportsNoteError>
    func getMemosByMeasuresID(measuresID: String) -> Result<[MeasuresMemo], SportsNoteError> {
        let memos = RealmManager.shared.getMemosByMeasuresID(measuresID: measuresID)
        var measuresMemoList = [MeasuresMemo]()

        for memo in memos {
            // noteIDが空文字の場合（旧アプリでノート未紐付けだったメモ）は
            // Noteに依存せず、created_atをフォールバック日付として一覧に含める
            guard !memo.noteID.isEmpty else {
                let measuresMemo = MeasuresMemo(
                    memoID: memo.memoID,
                    measuresID: memo.measuresID,
                    noteID: memo.noteID,
                    detail: memo.detail,
                    date: memo.created_at
                )
                measuresMemoList.append(measuresMemo)
                continue
            }

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

    /// noteID・measuresIDに合致する既存メモを検索し、存在すれば論理削除する
    /// task.memoIDが未確定（課題追加直後、taskReflectionsのDictionaryキーにmemoIDが
    /// 反映されていない）場合でも、Realm上に実際に保存されているメモを確実に削除する
    /// - Parameters:
    ///   - noteID: ノートID
    ///   - measuresID: 対策ID
    /// - Returns: Result<Void, SportsNoteError>（該当メモが存在しない場合も.success(())を返す）
    func deleteMemoByNoteAndMeasures(noteID: String, measuresID: String) async -> Result<Void, SportsNoteError> {
        guard let memo = RealmManager.shared.findMemo(noteID: noteID, measuresID: measuresID) else {
            return .success(())
        }
        return await delete(id: memo.memoID)
    }
}
