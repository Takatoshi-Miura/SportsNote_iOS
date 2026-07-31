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

    private struct DummyError: Error {}

    /// 修正前の構造の再現: withThrowingTaskGroup 内で1つの子タスクが
    /// try await で例外を投げると、他の未完了タスクがキャンセルされ
    /// 完了できないことを検証する（issueが報告した巻き添えキャンセル現象）。
    @Test("withThrowingTaskGroupでtry awaitのまま失敗すると他タスクが巻き添えキャンセルされる")
    func throwingTaskGroup_withTryAwait_cancelsSiblings() async {
        actor Completed {
            var ids: [Int] = []
            func add(_ id: Int) { ids.append(id) }
        }
        let completed = Completed()

        let thrown: Bool
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for id in 1...6 {
                    group.addTask {
                        if id == 3 {
                            throw DummyError()
                        }
                        // 失敗タスクより後に完了する他エンティティの同期を模す
                        try await Task.sleep(nanoseconds: 100_000_000)
                        try Task.checkCancellation()
                        await completed.add(id)
                    }
                }
                for try await _ in group {}
            }
            thrown = false
        } catch {
            thrown = true
        }

        let ids = await completed.ids
        #expect(thrown)
        // 巻き添えキャンセルにより、失敗した id=3 以外の全件が完了するとは限らない
        #expect(ids.count < 5)
    }

    /// 修正後の構造の検証: 同じ状況で try? を使い例外を握りつぶした場合、
    /// withTaskGroup（非throwing）内の他タスクはキャンセルされず全件完了する。
    /// SyncManager.syncData 内で saveToFirebase(item) 等を try? にした対策と同等の構造。
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
                        try? await Self.throwingWork()
                    } else {
                        try? await Task.sleep(nanoseconds: 100_000_000)
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

    private static func throwingWork() async throws {
        throw DummyError()
    }
}
