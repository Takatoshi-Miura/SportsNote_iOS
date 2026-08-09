//
//  BackgroundSyncTrackerTests.swift
//  SportsNote_iOSTests
//
//  issue #84: ログアウト/アカウント削除時に進行中のバックグラウンドFirebase同期を
//  待たずにRealmを全削除してしまう問題の回帰テスト
//

import Foundation
import Testing

@testable import SportsNote_iOS

@Suite("BackgroundSyncTracker Tests", .serialized)
@MainActor
struct BackgroundSyncTrackerTests {

    @Test("waitForAll - 追跡中のTaskが完了するまで待機する")
    func waitForAll_waitsUntilTrackedTaskCompletes() async {
        actor Flag {
            var value = false
            func set() { value = true }
        }
        let flag = Flag()

        let task = Task<Void, Never> {
            try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒
            await flag.set()
        }
        BackgroundSyncTracker.shared.track(task)

        await BackgroundSyncTracker.shared.waitForAll()

        #expect(await flag.value == true)
    }

    @Test("waitForAll - 複数の追跡Taskすべての完了を待機する")
    func waitForAll_waitsForMultipleTasks() async {
        actor Counter {
            var count = 0
            func increment() { count += 1 }
        }
        let counter = Counter()

        for i in 1...5 {
            let task = Task<Void, Never> {
                try? await Task.sleep(nanoseconds: UInt64(10_000_000 * i))
                await counter.increment()
            }
            BackgroundSyncTracker.shared.track(task)
        }

        await BackgroundSyncTracker.shared.waitForAll()

        #expect(await counter.count == 5)
    }

    @Test("waitForAll - 追跡Taskが無い場合は即座に完了する")
    func waitForAll_returnsImmediatelyWhenNoTasksTracked() async {
        // 前テストの登録が自動クリーンアップされている前提で、極端に時間がかかっていないことを確認する
        let start = Date()
        await BackgroundSyncTracker.shared.waitForAll()
        let elapsed = Date().timeIntervalSince(start)

        #expect(elapsed < 1.0)
    }

    @Test("track - Task完了後は自動的に追跡対象から除去される")
    func track_removesCompletedTaskAutomatically() async {
        let task = Task<Void, Never> {}
        BackgroundSyncTracker.shared.track(task)
        _ = await task.value

        // 除去は登録側のTaskで非同期に行われるため、反映されるまで少し待つ
        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(BackgroundSyncTracker.shared.trackedCountForTesting == 0)
    }
}
