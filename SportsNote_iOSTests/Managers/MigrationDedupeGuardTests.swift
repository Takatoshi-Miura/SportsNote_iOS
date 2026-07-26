//
//  MigrationDedupeGuardTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2026/07/27.
//

import Foundation
import Testing

@testable import SportsNote_iOS

/// テスト用のエラー
private struct StubError: Error {}

@Suite("MigrationDedupeGuard Tests", .serialized)
@MainActor
struct MigrationDedupeGuardTests {

    init() {
        // 前のテストの残留状態をリセットする
        UserDefaultsManager.clearAll()
    }

    @Test("run - migrate/markDeletedが共に成功すると、完了後はmigrate済みフラグが残らない")
    func run_bothSucceed_clearsFlagAfterCompletion() async throws {
        let guardInstance = MigrationDedupeGuard()
        var migrateCallCount = 0
        var markDeletedCallCount = 0

        try await guardInstance.run(
            entity: "Task",
            documentID: "doc1",
            migrate: { migrateCallCount += 1 },
            markDeleted: { markDeletedCallCount += 1 }
        )

        #expect(migrateCallCount == 1)
        #expect(markDeletedCallCount == 1)
        #expect(guardInstance.isAlreadyMigrated(entity: "Task", documentID: "doc1") == false)

        UserDefaultsManager.clearAll()
    }

    @Test(
        "run - migrate成功後にmarkDeletedだけ失敗して再実行しても、migrateは再実行されない（issue #30の再現・修正確認）"
    )
    func run_markDeletedFailsThenRetried_doesNotDuplicateMigrate() async throws {
        let guardInstance = MigrationDedupeGuard()
        var migrateCallCount = 0
        var markDeletedCallCount = 0

        // 1回目: migrateは成功するが、markDeletedがネットワーク断等で失敗するケースを再現
        await #expect(throws: StubError.self) {
            try await guardInstance.run(
                entity: "Task",
                documentID: "doc1",
                migrate: { migrateCallCount += 1 },
                markDeleted: {
                    markDeletedCallCount += 1
                    throw StubError()
                }
            )
        }

        #expect(migrateCallCount == 1)
        #expect(markDeletedCallCount == 1)
        // markDeletedが失敗した時点では、migrate済みフラグが残っていること（次回のスキップ判定に使われる）
        #expect(guardInstance.isAlreadyMigrated(entity: "Task", documentID: "doc1") == true)

        // 2回目: 次回のmigrateAll()再実行を模す。今度はmarkDeletedが成功する
        try await guardInstance.run(
            entity: "Task",
            documentID: "doc1",
            migrate: { migrateCallCount += 1 },
            markDeleted: { markDeletedCallCount += 1 }
        )

        // ガードがなければここでmigrateCallCountは2になり重複変換が発生してしまう
        #expect(migrateCallCount == 1)
        #expect(markDeletedCallCount == 2)
        // 最終的に成功したので、フラグは掃除されていること
        #expect(guardInstance.isAlreadyMigrated(entity: "Task", documentID: "doc1") == false)

        UserDefaultsManager.clearAll()
    }

    @Test("run - migrate自体が失敗した場合はフラグが立たず、次回もmigrateから再実行される")
    func run_migrateFails_doesNotMarkAsMigrated() async throws {
        let guardInstance = MigrationDedupeGuard()
        var migrateCallCount = 0
        var markDeletedCallCount = 0

        await #expect(throws: StubError.self) {
            try await guardInstance.run(
                entity: "Task",
                documentID: "doc1",
                migrate: {
                    migrateCallCount += 1
                    throw StubError()
                },
                markDeleted: { markDeletedCallCount += 1 }
            )
        }

        #expect(migrateCallCount == 1)
        // migrateが失敗した場合、markDeletedは呼ばれない
        #expect(markDeletedCallCount == 0)
        #expect(guardInstance.isAlreadyMigrated(entity: "Task", documentID: "doc1") == false)

        // 次回再実行時も、migrateから再度実行されること
        try await guardInstance.run(
            entity: "Task",
            documentID: "doc1",
            migrate: { migrateCallCount += 1 },
            markDeleted: { markDeletedCallCount += 1 }
        )

        #expect(migrateCallCount == 2)
        #expect(markDeletedCallCount == 1)

        UserDefaultsManager.clearAll()
    }

    @Test("run - entityが異なれば同じdocumentIDでも独立してガードされる")
    func run_differentEntitySameDocumentID_isIndependentlyGuarded() async throws {
        let guardInstance = MigrationDedupeGuard()
        var taskMigrateCallCount = 0
        var targetMigrateCallCount = 0

        // Task側はmarkDeletedが失敗してフラグが残る
        await #expect(throws: StubError.self) {
            try await guardInstance.run(
                entity: "Task",
                documentID: "sameID",
                migrate: { taskMigrateCallCount += 1 },
                markDeleted: { throw StubError() }
            )
        }

        // Target側は同じdocumentIDだが、Taskとは無関係にmigrateが実行されること
        try await guardInstance.run(
            entity: "Target",
            documentID: "sameID",
            migrate: { targetMigrateCallCount += 1 },
            markDeleted: {}
        )

        #expect(taskMigrateCallCount == 1)
        #expect(targetMigrateCallCount == 1)
        #expect(guardInstance.isAlreadyMigrated(entity: "Task", documentID: "sameID") == true)
        #expect(guardInstance.isAlreadyMigrated(entity: "Target", documentID: "sameID") == false)

        UserDefaultsManager.clearAll()
    }
}
