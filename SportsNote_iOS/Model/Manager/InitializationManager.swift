import Foundation
import SwiftUI

@MainActor
class InitializationManager {
    
    static let shared = InitializationManager()
    
    private init() {}
    
    /// アプリの初期化
    /// - Parameter isLogin: ログイン済みかどうか
    func initializeApp(isLogin: Bool = false) async {
        initializePreferences()
        initializeRealm()
        
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
    
    // TODO: 以降の処理を要確認
    
    /**
     * UserDefaults を初期化
     */
    private func initializePreferences() {
        // UserDefaultsManagerはすでに初期化されているため、追加の処理は不要
    }
    
    /**
     * Realm を初期化
     */
    private func initializeRealm() {
        RealmManager.shared.initRealm()
    }
    
    /**
     * フリーノートを作成
     */
    private func createFreeNote() async {
        // フリーノートがすでに存在するか確認
        if RealmManager.shared.getFreeNote() == nil {
            let noteViewModel = NoteViewModel()
            noteViewModel.saveFreeNote(
                title: LocalizedStrings.freeNote,
                detail: LocalizedStrings.defaltFreeNoteDetail
            )
        }
    }
    
    /**
     * 未分類グループを作成
     */
    private func createUncategorizedGroup() async {
        // すでにグループが存在するか確認
        let groups = RealmManager.shared.getDataList(clazz: Group.self)
        if groups.isEmpty {
            let groupViewModel = GroupViewModel()
            groupViewModel.saveGroup(
                title: LocalizedStrings.uncategorized,
                color: GroupColor.gray
            )
        }
    }
    
    /**
     * データを全削除
     */
    func deleteAllData() async {
        RealmManager.shared.clearAll()
        UserDefaultsManager.clearAll()
    }
    
    /**
     * 全データの同期処理
     */
    func syncAllData() async {
        do {
            try await SyncManager.shared.syncAllData()
        } catch {
            print("データ同期に失敗しました: \(error.localizedDescription)")
        }
    }
    
    /**
     * ユーザーIDの更新処理
     */
    func updateAllUserIds(userId: String) async {
        // RealmManagerの機能を使用してユーザーIDを更新
        RealmManager.shared.updateAllUserIds(userId: userId)
    }
} 
