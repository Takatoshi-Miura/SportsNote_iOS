import Foundation

/// `FirebaseSyncable.performBackgroundSync`が起動したバックグラウンドFirebase同期Taskを追跡し、
/// ログアウト/アカウント削除等でRealmを全削除する前に、起動済みの同期処理の完了を待機できるようにするためのシングルトン。
///
/// NOTE: `performBackgroundSync`のFire-and-forget起動パターン自体は変更しない。
/// 起動済みTaskハンドルを本トラッカーに登録するだけの最小限の追加とする（Issue #84対応）。
@MainActor
final class BackgroundSyncTracker {

    static let shared = BackgroundSyncTracker()

    private init() {}

    private var trackedTasks: [UUID: Task<Void, Never>] = [:]

    /// バックグラウンド同期Taskを追跡対象に登録する
    /// Task完了時には自動的に追跡対象から取り除かれる（メモリリーク防止）
    /// - Parameter task: 追跡対象のTaskハンドル
    func track(_ task: Task<Void, Never>) {
        let id = UUID()
        trackedTasks[id] = task

        Task { [weak self] in
            _ = await task.value
            self?.trackedTasks.removeValue(forKey: id)
        }
    }

    /// 呼び出し時点で追跡中の全Taskの完了を待機する
    /// （待機開始後に新規登録されたTaskは対象外。Realm全削除の直前に呼ぶことを想定）
    func waitForAll() async {
        let tasks = Array(trackedTasks.values)
        for task in tasks {
            _ = await task.value
        }
    }

    #if DEBUG
        /// テスト用: 現在追跡中のTask数
        var trackedCountForTesting: Int { trackedTasks.count }
    #endif
}
