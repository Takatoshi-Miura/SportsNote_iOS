import Foundation
import SwiftUI

@MainActor
class InitializationManager {
    
    static let shared = InitializationManager()
    
    private init() {}
    
    /// アプリの初期化
    /// - Parameter isLogin: ログイン済みかどうか
    func initializeApp(isLogin: Bool = false) async {
        RealmManager.shared.initRealm()
        
        let isFirstLaunch = UserDefaultsManager.get(key: UserDefaultsManager.Keys.firstLaunch, defaultValue: true)
        if isFirstLaunch {
            UserDefaultsManager.clearAll()
            UserDefaultsManager.resetUserInfo()
            UserDefaultsManager.set(key: UserDefaultsManager.Keys.firstLaunch, value: false)
        }
        
        if !isLogin {
            // 初期データを作成
            await createFreeNote()
            await createUncategorizedGroup()
        }
    }
    
    /// フリーノートを作成
    /// ※既に存在する場合は作成しない
    private func createFreeNote() async {
        if RealmManager.shared.getFreeNote() != nil {
            return
        }
        
        let noteViewModel = NoteViewModel()
        noteViewModel.saveFreeNote(
            title: LocalizedStrings.freeNote,
            detail: LocalizedStrings.defaltFreeNoteDetail
        )
    }
    
    /// 未分類グループを作成
    /// ※グループが既に存在する場合は作成しない
    private func createUncategorizedGroup() async {
        let groups = RealmManager.shared.getDataList(clazz: Group.self)
        if groups.isEmpty {
            let groupViewModel = GroupViewModel()
            groupViewModel.saveGroup(
                title: LocalizedStrings.uncategorized,
                color: GroupColor.gray
            )
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
        RealmManager.shared.updateAllUserIds(userId: userId)
    }
} 
