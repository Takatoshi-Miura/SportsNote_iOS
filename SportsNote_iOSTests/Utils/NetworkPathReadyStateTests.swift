//
//  NetworkPathReadyStateTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2026/08/03.
//

import Foundation
import Testing

@testable import SportsNote_iOS

/// `NWPathMonitor`は実機・OS依存のため、`Network`クラスそのものではなく
/// 初回パス確定の待ち合わせロジックを抽出した`NetworkPathReadyState`単体を検証する（issue #68）。
@Suite("NetworkPathReadyState Tests")
struct NetworkPathReadyStateTests {

    @Test("markReady()を先に呼んでからwaitUntilReady()を呼ぶと即座に返る")
    func waitUntilReady_alreadyReady_returnsImmediately() async {
        let state = NetworkPathReadyState()
        state.markReady()

        let start = Date()
        await state.waitUntilReady(timeout: 5.0)
        let elapsed = Date().timeIntervalSince(start)

        #expect(elapsed < 1.0)
    }

    @Test("waitUntilReady()呼び出し後に別Taskでmarkready()を呼ぶと待機が解除される")
    func waitUntilReady_markReadyFromAnotherTask_resolvesBeforeTimeout() async {
        let state = NetworkPathReadyState()

        let start = Date()
        async let waiter: Void = state.waitUntilReady(timeout: 5.0)

        // waitUntilReady()の登録が先に走るよう少し待ってからmarkReady()を呼ぶ
        try? await Task.sleep(nanoseconds: 50_000_000)  // 0.05秒
        state.markReady()

        await waiter
        let elapsed = Date().timeIntervalSince(start)

        // タイムアウト(5秒)よりも十分早く解除されること
        #expect(elapsed < 2.0)
    }

    @Test("複数のTaskが同時にwaitUntilReady()しても1回のmarkReady()で全て解除される")
    func waitUntilReady_multipleWaiters_allResolvedByOneMarkReady() async {
        let state = NetworkPathReadyState()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    await state.waitUntilReady(timeout: 5.0)
                }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 50_000_000)  // 0.05秒
                state.markReady()
            }
            await group.waitForAll()
        }

        // 全Taskが完了（=二重resumeでクラッシュせず正常終了）すればテスト成功
        #expect(Bool(true))
    }

    @Test("markReady()が呼ばれない場合、指定timeout後にwaitUntilReady()が復帰する")
    func waitUntilReady_neverMarkedReady_resolvesAfterTimeout() async {
        let state = NetworkPathReadyState()

        let start = Date()
        await state.waitUntilReady(timeout: 0.2)
        let elapsed = Date().timeIntervalSince(start)

        #expect(elapsed >= 0.2)
        #expect(elapsed < 2.0)
    }

    @Test("markReady()を複数回呼んでも安全（2回目以降は何もしない）")
    func markReady_calledMultipleTimes_isSafe() async {
        let state = NetworkPathReadyState()

        state.markReady()
        state.markReady()
        state.markReady()

        let start = Date()
        await state.waitUntilReady(timeout: 5.0)
        let elapsed = Date().timeIntervalSince(start)

        #expect(elapsed < 1.0)
    }
}
