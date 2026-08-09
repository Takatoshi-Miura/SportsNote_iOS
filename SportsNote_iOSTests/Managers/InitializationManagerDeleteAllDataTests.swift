//
//  InitializationManagerDeleteAllDataTests.swift
//  SportsNote_iOSTests
//
//  issue #84: ログアウト/アカウント削除時に進行中のバックグラウンドFirebase同期を
//  待たずにRealmを全削除してしまう問題の回帰テスト
//

import Foundation
import Testing

@testable import SportsNote_iOS

@Suite("InitializationManager deleteAllData Tests", .serialized)
@MainActor
struct InitializationManagerDeleteAllDataTests {

    init() async throws {
        RealmManager.shared.setupInMemoryRealm()
    }

    @Test("deleteAllData - 追跡中のバックグラウンド同期Taskの完了を待ってからRealmを全削除する")
    func deleteAllData_waitsForTrackedSyncBeforeClearingRealm() async {
        actor Order {
            var events: [String] = []
            func record(_ e: String) { events.append(e) }
        }
        let order = Order()

        // Realmに1件保存しておく
        let group = Group(groupID: "test-group", title: "test", color: 0, order: 0, created_at: Date())
        try? RealmManager.shared.saveItem(group)

        // performBackgroundSyncが起動する「未完了の同期Task」を模して追跡登録する
        let task = Task<Void, Never> {
            try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒後に完了
            await order.record("sync_completed")
        }
        BackgroundSyncTracker.shared.track(task)

        await InitializationManager.shared.deleteAllData()
        await order.record("delete_all_data_returned")

        let events = await order.events
        // "sync_completed" が "delete_all_data_returned" より先に記録されている
        // ＝ Realm全削除前に同期Taskの完了を待てていることを検証
        #expect(events == ["sync_completed", "delete_all_data_returned"])

        // Realmが実際に空になっていることも確認
        let groups = (try? RealmManager.shared.getDataList(clazz: Group.self)) ?? []
        #expect(groups.isEmpty)
    }

    @Test("deleteAllData - 追跡中のTaskが無い場合も正常にRealmを全削除する")
    func deleteAllData_clearsRealmWhenNoTrackedTasks() async {
        let group = Group(groupID: "test-group-2", title: "test2", color: 0, order: 0, created_at: Date())
        try? RealmManager.shared.saveItem(group)

        await InitializationManager.shared.deleteAllData()

        let groups = (try? RealmManager.shared.getDataList(clazz: Group.self)) ?? []
        #expect(groups.isEmpty)
    }
}
