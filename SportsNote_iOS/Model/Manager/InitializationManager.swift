import Firebase
import FirebaseCrashlytics
import Foundation
import SwiftUI

@MainActor
final class InitializationManager {

    static let shared = InitializationManager()

    private init() {}

    /// アプリの初期化
    /// - Parameter isLogin: ログイン済みかどうか
    func initializeApp(isLogin: Bool = false) async {
        let isFirstLaunch = UserDefaultsManager.get(key: UserDefaultsManager.Keys.firstLaunch, defaultValue: true)
        if isFirstLaunch {
            UserDefaultsManager.clearAll()
            UserDefaultsManager.resetUserInfo()
            // userID作成
            let userID = UUID().uuidString
            UserDefaultsManager.set(key: UserDefaultsManager.Keys.userID, value: userID)
            UserDefaultsManager.set(key: UserDefaultsManager.Keys.firstLaunch, value: false)
        }

        // CrashlyticsにuserID情報を付加
        if let userID = UserDefaultsManager.get(key: UserDefaultsManager.Keys.userID, defaultValue: nil) as String? {
            Crashlytics.crashlytics().setUserID(userID)
        }

        if !isLogin {
            // 初期データを作成
            await createFreeNote()
            await createUncategorizedGroup()
        }

        // ログイン済みの場合、アプリ起動時にデータ同期を実行
        if !isFirstLaunch && isUserLoggedIn() && Network.isOnline() {
            await syncAllData()
        }
    }

    /// フリーノートを作成
    /// ※既に存在する場合は作成しない
    private func createFreeNote() async {
        if RealmManager.shared.getFreeNote() != nil {
            return
        }

        Task { @MainActor in
            let noteViewModel = NoteViewModel()
            noteViewModel.saveFreeNote(
                title: LocalizedStrings.freeNote,
                detail: LocalizedStrings.defaltFreeNoteDetail
            )
        }
    }

    /// 未分類グループを作成
    /// ※グループが既に存在する場合は作成しない
    private func createUncategorizedGroup() async {
        do {
            let groups = try RealmManager.shared.getDataList(clazz: Group.self)
            if groups.isEmpty {
                let groupViewModel = GroupViewModel()
                let _ = await groupViewModel.saveGroup(
                    title: LocalizedStrings.uncategorized,
                    color: GroupColor.gray
                )
            }
        } catch {
            print("未分類グループ作成チェックに失敗しました: \(error.localizedDescription)")
        }
    }

    /// データを全削除
    func deleteAllData() async {
        RealmManager.shared.clearAll()
        UserDefaultsManager.clearAll()
    }

    /// 全データの同期処理
    func syncAllData() async {
        do {
            try await SyncManager.shared.syncAllData()
        } catch {
            print("データ同期に失敗しました: \(error.localizedDescription)")
        }
    }

    /// ユーザIDの更新処理
    /// - Parameter userId: userId
    func updateAllUserIds(userId: String) async {
        do {
            try RealmManager.shared.updateAllUserIds(userId: userId)
        } catch {
            print("ユーザID更新に失敗しました: \(error.localizedDescription)")
        }
    }

    /// ユーザーのログイン状態をチェック
    /// - Returns: ログイン済みかどうか
    private func isUserLoggedIn() -> Bool {
        return UserDefaultsManager.get(key: UserDefaultsManager.Keys.isLogin, defaultValue: false)
    }
}
