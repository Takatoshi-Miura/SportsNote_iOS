//
//  TaskViewModelUserIDPreservationTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2026/08/04.
//

import Foundation
import RealmSwift
import Testing

@testable import SportsNote_iOS

/// issue #74の再現シナリオ（アカウント作成直後のuserID切替タイミングでFirebase更新が
/// ドキュメントID不一致により失敗する）を、`TaskViewModel.updateTask`経由で
/// エンドツーエンドに近い形で検証する。
///
/// `TaskViewModel.updateTask`は内部で`createTaskData(basedOn:)`により`TaskData`を
/// 再構築するが、`TaskData`の designated init はUserDefaults上の**現在の**userIDを
/// 読み直すため、再構築されたエンティティのuserIDは常に「現在の」userIDになってしまう。
/// `TaskViewModel.save(_:isUpdate:)`は、更新時にRealmへ永続化済みの（切替前の）userIDへ
/// 明示的に戻す処理を持つべきであり、本テストはそれを検証する。
@Suite("TaskViewModel userID保持 Tests", .serialized)
@MainActor
struct TaskViewModelUserIDPreservationTests {

    init() {
        RealmManager.shared.setupInMemoryRealm()
    }

    @Test(
        "updateTask - アカウント作成直後にUserDefaultsのuserIDが切り替わっても、既存タスクのuserIDは切替前の値のまま保持される"
    )
    func updateTask_afterUserIDSwitch_preservesOriginalUserID() async throws {
        let oldUserID = "old-user-ABC"
        let newUserID = "new-user-XYZ"

        // 1. 旧userIDの状態でタスクを作成する（匿名ユーザー相当）
        UserDefaultsManager.set(key: UserDefaultsManager.Keys.userID, value: oldUserID)

        let viewModel = TaskViewModel()
        let createResult = await viewModel.saveNewTaskWithMeasures(
            title: "Original Title", cause: "Original Cause", groupID: "group-1")

        guard case .success(let createdTask) = createResult else {
            Issue.record("タスクの作成に失敗した")
            return
        }
        #expect(createdTask.userID == oldUserID)

        // 2. アカウント作成により、UserDefaults上のuserIDだけが即座に新IDへ切り替わる
        //    （updateAllUserIdsによるRealm全件書き換えはまだ完了していない状態を模す）
        UserDefaultsManager.set(key: UserDefaultsManager.Keys.userID, value: newUserID)

        // 3. その状態でユーザーが既存タスクを編集する
        let updateResult = await viewModel.updateTask(
            taskID: createdTask.taskID, title: "Updated Title", cause: "Updated Cause", groupID: "group-1")

        guard case .success = updateResult else {
            Issue.record("タスクの更新に失敗した")
            return
        }

        // 4. Realmに永続化されたタスクのuserIDは、切替前の値のまま保持されている必要がある
        //    （切替後の新userIDに上書きされてしまうと、Firebase更新時のドキュメントIDが
        //      Firestore上の実データと一致しなくなる）
        let persistedTask = try RealmManager.shared.getObjectById(id: createdTask.taskID, type: TaskData.self)
        #expect(persistedTask?.userID == oldUserID)
        #expect(persistedTask?.userID != newUserID)
        #expect(persistedTask?.title == "Updated Title")

        // 後始末
        UserDefaultsManager.remove(key: UserDefaultsManager.Keys.userID)
    }
}
