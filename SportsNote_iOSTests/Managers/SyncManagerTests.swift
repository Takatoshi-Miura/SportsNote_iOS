//
//  SyncManagerTests.swift
//  SportsNote_iOSTests
//
//  issue #26: オフライン削除後の同期で削除済みデータが復活する不具合の回帰テスト
//

import Foundation
import RealmSwift
import Testing

@testable import SportsNote_iOS

@Suite("SyncManager Tests", .serialized)
@MainActor
struct SyncManagerTests {

    let syncManager = SyncManager.shared

    init() async throws {
        // テストごとにインメモリRealmを設定
        // getFirebaseData/saveToFirebase/updateFirebaseのみスタブに差し替え、
        // getRealmDataは本番実装（RealmManager.shared.getDataListIncludingDeleted）を
        // そのまま経由させることで、SyncManager.syncGroup内の実際の配線（isDeleted復活バグ対策）を検証する
        RealmManager.shared.setupInMemoryRealm()
    }

    // MARK: - issue #26: 削除の同期伝播テスト（syncGroupの本番配線を経由）

    @Test(
        "syncGroup - ローカルでオフライン削除されたレコード（isDeleted=true, updated_atが新しい）は、Firebase側の古い未削除コピーで上書きされず、削除がFirebaseへ反映される"
    )
    func syncGroup_localDeletionNewerThanFirebase_propagatesDeleteToFirebase() async throws {
        let id = "g-local-delete"
        let oldDate = Date().addingTimeInterval(-3600)

        // ローカルはオフラインで論理削除済み（実際にRealmへ保存し、logicalDeleteでupdated_atも更新させる）
        let realmGroup = Group(groupID: id, title: "G", color: 0, order: 0, created_at: oldDate)
        realmGroup.updated_at = oldDate
        try RealmManager.shared.saveItem(realmGroup)
        try RealmManager.shared.logicalDelete(id: id, type: Group.self)

        // Firebase側はまだ削除前の古いコピー（isDeleted=false, updated_atが古いまま）
        let firebaseGroup = Group(groupID: id, title: "G", color: 0, order: 0, created_at: oldDate)
        firebaseGroup.updated_at = oldDate
        firebaseGroup.isDeleted = false

        var updateFirebaseCalledWith: Group?
        var saveToFirebaseCalled = false

        // getRealmDataは本番デフォルト（RealmManager.shared.getDataListIncludingDeleted）をそのまま使う。
        // ここでgetDataList（isDeletedフィルタあり）に戻す退行が起きた場合、
        // ローカル削除済みレコードがrealmMapに含まれなくなりonlyFirebaseID扱いとなって
        // Firebase側の古いコピーで上書き（削除が復活）されるため、本テストは失敗する
        try await syncManager.syncGroup(
            getFirebaseData: { [firebaseGroup] },
            saveToFirebase: { _ in saveToFirebaseCalled = true },
            updateFirebase: { item in updateFirebaseCalledWith = item }
        )

        #expect(updateFirebaseCalledWith != nil)
        #expect(updateFirebaseCalledWith?.isDeleted == true)
        #expect(saveToFirebaseCalled == false)

        // 削除復活バグが起きていないことも直接確認する
        let rawGroup = RealmManager.shared.getRawObjectById(id: id, type: Group.self)
        #expect(rawGroup?.isDeleted == true)

        RealmManager.shared.clearAll()
    }

    @Test(
        "syncGroup - Firebase側で削除された（isDeleted=true, updated_atが新しい）レコードは、Realm側にも削除として反映される（saveItem経由でisDeletedを含めて上書きされる）"
    )
    func syncGroup_firebaseDeletionNewerThanRealm_propagatesDeleteToRealm() async throws {
        let id = "g-firebase-delete"
        let oldDate = Date().addingTimeInterval(-3600)
        let newDate = Date()

        // ローカルはまだ削除前（未削除、古い更新日時）
        let realmGroup = Group(groupID: id, title: "G", color: 0, order: 0, created_at: oldDate)
        realmGroup.updated_at = oldDate
        realmGroup.isDeleted = false
        try RealmManager.shared.saveItem(realmGroup)

        // Firebase側は他デバイスでオンライン削除済み（isDeleted=true, updated_atが新しい）
        let firebaseGroup = Group(groupID: id, title: "G", color: 0, order: 0, created_at: oldDate)
        firebaseGroup.updated_at = newDate
        firebaseGroup.isDeleted = true

        try await syncManager.syncGroup(
            getFirebaseData: { [firebaseGroup] },
            saveToFirebase: { _ in Issue.record("saveToFirebaseは呼ばれないはず") },
            updateFirebase: { _ in Issue.record("updateFirebaseは呼ばれないはず") }
        )

        // Realm側にFirebaseの削除済みコピーが保存され、isDeleted=trueとなる
        let rawGroup = RealmManager.shared.getRawObjectById(id: id, type: Group.self)
        #expect(rawGroup != nil)
        #expect(rawGroup?.isDeleted == true)

        RealmManager.shared.clearAll()
    }

    @Test("syncGroup - Realmにのみ存在する新規データはFirebaseへ保存される（既存ロジックの回帰確認）")
    func syncGroup_onlyInRealm_savesToFirebase() async throws {
        let realmOnlyGroup = Group(groupID: "g-only-realm", title: "G", color: 0, order: 0, created_at: Date())
        try RealmManager.shared.saveItem(realmOnlyGroup)

        var saveToFirebaseCalledWith: Group?

        try await syncManager.syncGroup(
            getFirebaseData: { [] },
            saveToFirebase: { item in saveToFirebaseCalledWith = item },
            updateFirebase: { _ in Issue.record("updateFirebaseは呼ばれないはず") }
        )

        #expect(saveToFirebaseCalledWith?.groupID == "g-only-realm")

        RealmManager.shared.clearAll()
    }

    @Test("syncGroup - Firebaseにのみ存在するデータはRealmへ保存される（既存ロジックの回帰確認）")
    func syncGroup_onlyInFirebase_savesToRealm() async throws {
        let firebaseOnlyGroup = Group(groupID: "g-only-firebase", title: "G", color: 0, order: 0, created_at: Date())

        try await syncManager.syncGroup(
            getFirebaseData: { [firebaseOnlyGroup] },
            saveToFirebase: { _ in Issue.record("saveToFirebaseは呼ばれないはず") },
            updateFirebase: { _ in Issue.record("updateFirebaseは呼ばれないはず") }
        )

        let rawGroup = RealmManager.shared.getRawObjectById(id: "g-only-firebase", type: Group.self)
        #expect(rawGroup != nil)
        #expect(rawGroup?.groupID == "g-only-firebase")

        RealmManager.shared.clearAll()
    }
}
