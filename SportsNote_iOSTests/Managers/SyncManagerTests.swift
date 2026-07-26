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
        // テストごとにインメモリRealmを設定（syncData内でRealmManager.shared.saveItemが呼ばれる分岐を検証するため）
        RealmManager.shared.setupInMemoryRealm()
    }

    // MARK: - issue #26: 削除の同期伝播テスト

    @Test(
        "syncData - ローカルでオフライン削除されたレコード（isDeleted=true, updated_atが新しい）は、Firebase側の古い未削除コピーで上書きされず、削除がFirebaseへ反映される"
    )
    func syncData_localDeletionNewerThanFirebase_propagatesDeleteToFirebase() async throws {
        let id = "g-local-delete"
        let oldDate = Date().addingTimeInterval(-3600)
        let newDate = Date()

        // Firebase側はまだ削除前の古いコピー
        let firebaseGroup = Group(groupID: id, title: "G", color: 0, order: 0, created_at: oldDate)
        firebaseGroup.updated_at = oldDate
        firebaseGroup.isDeleted = false

        // ローカルはオフラインで論理削除済み（markAsDeletedによりupdated_atが更新されている想定）
        let realmGroup = Group(groupID: id, title: "G", color: 0, order: 0, created_at: oldDate)
        realmGroup.updated_at = newDate
        realmGroup.isDeleted = true

        var updateFirebaseCalledWith: Group?
        var saveToFirebaseCalled = false

        try await syncManager.syncData(
            getFirebaseData: { [firebaseGroup] },
            getRealmData: { [realmGroup] },
            saveToFirebase: { _ in saveToFirebaseCalled = true },
            updateFirebase: { item in updateFirebaseCalledWith = item }
        )

        // Realm側の削除済みレコード（isDeleted=true）がFirebaseへの更新として反映される
        #expect(updateFirebaseCalledWith != nil)
        #expect(updateFirebaseCalledWith?.isDeleted == true)
        #expect(saveToFirebaseCalled == false)
    }

    @Test(
        "syncData - Firebase側で削除された（isDeleted=true, updated_atが新しい）レコードは、Realm側にも削除として反映される（saveItem経由でisDeletedを含めて上書きされる）"
    )
    func syncData_firebaseDeletionNewerThanRealm_propagatesDeleteToRealm() async throws {
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

        try await syncManager.syncData(
            getFirebaseData: { [firebaseGroup] },
            getRealmData: { try RealmManager.shared.getDataListIncludingDeleted(clazz: Group.self) },
            saveToFirebase: { _ in Issue.record("saveToFirebaseは呼ばれないはず") },
            updateFirebase: { _ in Issue.record("updateFirebaseは呼ばれないはず") }
        )

        // Realm側にFirebaseの削除済みコピーが保存され、isDeleted=trueとなる
        let rawGroup = RealmManager.shared.getRawObjectById(id: id, type: Group.self)
        #expect(rawGroup != nil)
        #expect(rawGroup?.isDeleted == true)

        RealmManager.shared.clearAll()
    }

    @Test("syncData - Realmにのみ存在する新規データはFirebaseへ保存される（既存ロジックの回帰確認）")
    func syncData_onlyInRealm_savesToFirebase() async throws {
        let realmOnlyGroup = Group(groupID: "g-only-realm", title: "G", color: 0, order: 0, created_at: Date())

        var saveToFirebaseCalledWith: Group?

        try await syncManager.syncData(
            getFirebaseData: { [] },
            getRealmData: { [realmOnlyGroup] },
            saveToFirebase: { item in saveToFirebaseCalledWith = item },
            updateFirebase: { _ in Issue.record("updateFirebaseは呼ばれないはず") }
        )

        #expect(saveToFirebaseCalledWith?.groupID == "g-only-realm")
    }

    @Test("syncData - Firebaseにのみ存在するデータはRealmへ保存される（既存ロジックの回帰確認）")
    func syncData_onlyInFirebase_savesToRealm() async throws {
        let firebaseOnlyGroup = Group(groupID: "g-only-firebase", title: "G", color: 0, order: 0, created_at: Date())

        try await syncManager.syncData(
            getFirebaseData: { [firebaseOnlyGroup] },
            getRealmData: { [] },
            saveToFirebase: { _ in Issue.record("saveToFirebaseは呼ばれないはず") },
            updateFirebase: { _ in Issue.record("updateFirebaseは呼ばれないはず") }
        )

        let rawGroup = RealmManager.shared.getRawObjectById(id: "g-only-firebase", type: Group.self)
        #expect(rawGroup != nil)
        #expect(rawGroup?.groupID == "g-only-firebase")

        RealmManager.shared.clearAll()
    }
}
