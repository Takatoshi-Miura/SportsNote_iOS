//
//  FirebaseManagerDocumentIDTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2026/08/04.
//

import Foundation
import Testing

@testable import SportsNote_iOS

/// `FirebaseManager`はFirebaseFirestoreに直接依存し、Firebase未設定のテスト環境では
/// インスタンス化する（`.shared`にアクセスする等）だけでクラッシュするため、
/// `FirebaseManager`のインスタンスには一切触れず、Firestoreに触れない
/// `static func buildDocumentID(userID:entityID:)`のみを検証する（issue #74）。
///
/// issue #74は、更新系メソッド（`updateTask`等）がドキュメントID組み立てに
/// 「現在のUserDefaults上のuserID」ではなく「エンティティ自身が保持するuserID」を
/// 使用しなければならない、という規約違反（バグ）を修正するものである。
/// 以下のテストは、アカウント作成直後にUserDefaults上のuserIDが新IDへ切り替わった後でも、
/// Realm上にまだ旧IDのまま残っているエンティティに対しては、
/// 旧ID基準のドキュメントID（Firestore上の実データと一致するID）が組み立てられることを検証する。
@Suite("FirebaseManager buildDocumentID Tests")
@MainActor
struct FirebaseManagerDocumentIDTests {

    private let oldUserID = "old-user-ABC"
    private let newUserID = "new-user-XYZ"

    @Test("buildDocumentIDはuserIDとentityIDから\"userID_entityID\"形式のIDを組み立てる")
    func buildDocumentID_returnsUnderscoreJoinedID() {
        let documentID = FirebaseManager.buildDocumentID(userID: "user1", entityID: "entity1")
        #expect(documentID == "user1_entity1")
    }

    @Test(
        "アカウント作成直後にuserIDが切り替わった状態でも、エンティティ自身の（旧）userIDを使ってドキュメントIDが組み立てられる",
        arguments: [
            ("task-1", "TaskData"),
            ("group-1", "Group"),
            ("measures-1", "Measures"),
            ("memo-1", "Memo"),
            ("target-1", "Target"),
            ("note-1", "Note"),
        ]
    )
    func buildDocumentID_usesEntityOwnUserID_notCurrentUserID(entityID: String, entityName: String) {
        // Realm上のエンティティのuserIDはまだ旧IDのまま（updateAllUserIds完了前を想定）
        let documentID = FirebaseManager.buildDocumentID(userID: oldUserID, entityID: entityID)

        // Firestore上の実データと一致する「旧userID_entityID」が組み立てられること
        #expect(documentID == "\(oldUserID)_\(entityID)")
        // 現在UserDefaultsに切り替わっている新userIDを使った誤ったIDにはならないこと
        #expect(documentID != "\(newUserID)_\(entityID)")
    }

    @Test("TaskDataエンティティ自身のuserIDプロパティを使ってドキュメントIDが組み立てられる")
    func buildDocumentID_withTaskDataEntity_usesTaskUserID() {
        let task = TaskData()
        task.taskID = "task-abc"
        task.userID = oldUserID

        let documentID = FirebaseManager.buildDocumentID(userID: task.userID, entityID: task.taskID)

        #expect(documentID == "\(oldUserID)_task-abc")
    }

    @Test("Groupエンティティ自身のuserIDプロパティを使ってドキュメントIDが組み立てられる")
    func buildDocumentID_withGroupEntity_usesGroupUserID() {
        let group = Group()
        group.groupID = "group-abc"
        group.userID = oldUserID

        let documentID = FirebaseManager.buildDocumentID(userID: group.userID, entityID: group.groupID)

        #expect(documentID == "\(oldUserID)_group-abc")
    }
}
