//
//  SyncManagerConcurrencyTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2026/07/25.
//

import Foundation
import Testing

@testable import SportsNote_iOS

@Suite("SyncManager 巻き添えキャンセル対策 Tests")
struct SyncManagerConcurrencyTests {

    /// 1つのタスクの保存処理が失敗しても、try? で握りつぶした場合は
    /// withTaskGroup 内の他のタスクがキャンセルされず最後まで完了することを検証する。
    /// SyncManager.syncData 内で saveToFirebase(item) を try? にした場合と同等の構造を模したテスト。
    @Test("try? で握りつぶした場合、他タスクはキャンセルされず完了する")
    func taskGroup_withTryOptional_doesNotCancelSiblings() async {
        actor Completed {
            var ids: [Int] = []
            func add(_ id: Int) { ids.append(id) }
        }
        let completed = Completed()

        await withTaskGroup(of: Void.self) { group in
            for id in 1...6 {
                group.addTask {
                    if id == 3 {
                        // saveToFirebase 相当の失敗を try? で握りつぶす
                        let result: Result<Void, Error> = .failure(
                            NSError(domain: "test", code: 1))
                        try? result.get()
                    }
                    // 他のエンティティ同期に相当する処理は必ず実行される
                    await completed.add(id)
                }
            }
        }

        let ids = await completed.ids
        #expect(ids.count == 6)
        #expect(Set(ids) == Set(1...6))
    }
}
