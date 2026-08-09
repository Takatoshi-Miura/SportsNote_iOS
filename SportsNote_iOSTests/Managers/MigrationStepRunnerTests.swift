//
//  MigrationStepRunnerTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2026/07/27.
//

import Foundation
import Testing

@testable import SportsNote_iOS

/// `MigrationManager`はFirebaseFirestoreに直接依存し、Firebase未設定のテスト環境では
/// インスタンス化するとクラッシュするため、`MigrationManager`/`FirebaseManager`には一切触れず
/// `MigrationStepRunner`単体をスタブクロージャで検証する（issue #35）。
///
/// issue #30対応（migrate成功後にmarkDeletedだけ失敗した場合の重複作成防止）のガードは
/// UserDefaultsを介して永続化されるため、本Suiteは`@Suite(.serialized)`で同期実行し、
/// 各テストの前後で`UserDefaultsManager.clearAll()`によりガード状態をクリーンな状態に保つ。
@Suite("MigrationStepRunner Tests", .serialized)
@MainActor
struct MigrationStepRunnerTests {

    private enum StubError: Error {
        case network
    }

    init() {
        UserDefaultsManager.clearAll()
    }

    @Test("migrate/markDeletedが共に成功する場合、両方が1回ずつ呼ばれる")
    func run_bothSucceed_callsMigrateAndMarkDeletedOnce() async throws {
        var migrateCallCount = 0
        var markDeletedCallCount = 0
        var loggedMessages: [String] = []

        let runner = MigrationStepRunner(logger: { loggedMessages.append($0) })

        try await runner.run(
            entity: "Task",
            documentID: "doc1",
            migrate: { migrateCallCount += 1 },
            markDeleted: { markDeletedCallCount += 1 }
        )

        #expect(migrateCallCount == 1)
        #expect(markDeletedCallCount == 1)
        #expect(loggedMessages.isEmpty)
    }

    @Test("migrate成功後にmarkDeletedだけ失敗して再実行しても、migrateは再実行されない（issue #30の再現・修正確認）")
    func run_markDeletedFailsThenRetried_doesNotDuplicateMigrate() async throws {
        var migrateCallCount = 0
        var markDeletedCallCount = 0
        var shouldMarkDeletedFail = true

        let runner = MigrationStepRunner()

        // 1回目: migrateは成功するが、markDeletedがネットワーク断等で失敗する
        await #expect(throws: StubError.self) {
            try await runner.run(
                entity: "Task",
                documentID: "doc-dup",
                migrate: { migrateCallCount += 1 },
                markDeleted: {
                    markDeletedCallCount += 1
                    if shouldMarkDeletedFail { throw StubError.network }
                }
            )
        }
        #expect(migrateCallCount == 1)
        #expect(markDeletedCallCount == 1)

        // 2回目（次回起動時の再実行を模す）: 旧ドキュメントのisDeletedが更新されていないため
        // 同一documentIDで再度runが呼ばれるが、migrateは再実行されず、markDeletedのみ再試行される
        shouldMarkDeletedFail = false
        try await runner.run(
            entity: "Task",
            documentID: "doc-dup",
            migrate: { migrateCallCount += 1 },
            markDeleted: { markDeletedCallCount += 1 }
        )

        #expect(migrateCallCount == 1)  // 修正前は2（重複作成）になってしまっていた箇所
        #expect(markDeletedCallCount == 2)
    }

    @Test("markDeletedが成功して完了すると、ガード記録がクリアされ以降は独立した新規ドキュメントとして扱われる")
    func run_markDeletedSucceeds_clearsGuardState() async throws {
        var migrateCallCount = 0

        let runner = MigrationStepRunner()

        try await runner.run(
            entity: "Task",
            documentID: "doc-clear",
            migrate: { migrateCallCount += 1 },
            markDeleted: {}
        )
        #expect(migrateCallCount == 1)

        // markDeletedまで成功しているため、同じdocumentIDで再度runを呼んでもガードは残っておらず
        // （実運用ではisDeleted=trueにより再取得されないため到達しないが）migrateは通常通り実行される
        try await runner.run(
            entity: "Task",
            documentID: "doc-clear",
            migrate: { migrateCallCount += 1 },
            markDeleted: {}
        )
        #expect(migrateCallCount == 2)
    }

    @Test("entityが異なれば同じdocumentIDでも独立してガードされる")
    func run_differentEntitiesSameDocumentID_areGuardedIndependently() async throws {
        var taskMigrateCallCount = 0
        var targetMigrateCallCount = 0

        let runner = MigrationStepRunner()

        // Task側: migrate成功・markDeleted失敗でガードが立つ
        await #expect(throws: StubError.self) {
            try await runner.run(
                entity: "Task",
                documentID: "shared-doc-id",
                migrate: { taskMigrateCallCount += 1 },
                markDeleted: { throw StubError.network }
            )
        }
        #expect(taskMigrateCallCount == 1)

        // Target側: 同じdocumentIDだがentityが異なるため、Task側のガードの影響を受けず通常通り実行される
        try await runner.run(
            entity: "Target",
            documentID: "shared-doc-id",
            migrate: { targetMigrateCallCount += 1 },
            markDeleted: {}
        )
        #expect(targetMigrateCallCount == 1)

        // Task側を再実行: ガードが効いてmigrateはスキップされる
        try await runner.run(
            entity: "Task",
            documentID: "shared-doc-id",
            migrate: { taskMigrateCallCount += 1 },
            markDeleted: {}
        )
        #expect(taskMigrateCallCount == 1)
    }

    @Test(
        "migrateがMigrationError.invalidDataをthrowした場合、markDeletedは呼ばれず旧データが保持される",
        arguments: ["Task", "Target", "Note", "FreeNote"]
    )
    func run_migrateThrowsInvalidData_skipsMarkDeletedAndLogs(entity: String) async throws {
        var migrateCallCount = 0
        var markDeletedCallCount = 0
        var loggedMessages: [String] = []

        let runner = MigrationStepRunner(logger: { loggedMessages.append($0) })

        // MigrationErrorはstepRunner内で吸収されるため、run自体はthrowしないことも同時に検証する
        try await runner.run(
            entity: entity,
            documentID: "doc-\(entity)",
            migrate: {
                migrateCallCount += 1
                throw MigrationError.invalidData(entity: entity, documentID: "doc-\(entity)")
            },
            markDeleted: { markDeletedCallCount += 1 }
        )

        #expect(migrateCallCount == 1)
        #expect(markDeletedCallCount == 0)
        #expect(loggedMessages.count == 1)
        #expect(loggedMessages[0].contains(entity))
        #expect(loggedMessages[0].contains("doc-\(entity)"))
    }

    @Test("migrateがMigrationError以外のエラーをthrowした場合、markDeletedは呼ばれずエラーが呼び出し元に伝播する")
    func run_migrateThrowsOtherError_propagatesAndSkipsMarkDeleted() async {
        var migrateCallCount = 0
        var markDeletedCallCount = 0
        var loggedMessages: [String] = []

        let runner = MigrationStepRunner(logger: { loggedMessages.append($0) })

        await #expect(throws: StubError.self) {
            try await runner.run(
                entity: "Task",
                documentID: "doc1",
                migrate: {
                    migrateCallCount += 1
                    throw StubError.network
                },
                markDeleted: { markDeletedCallCount += 1 }
            )
        }

        #expect(migrateCallCount == 1)
        #expect(markDeletedCallCount == 0)
        // Firestore通信エラー等はMigrationErrorではないため、既存の異常系挙動を変えずログ出力もしない
        #expect(loggedMessages.isEmpty)
    }

    @Test("markDeletedがエラーをthrowした場合、そのエラーが呼び出し元に伝播する")
    func run_markDeletedThrows_propagatesError() async {
        var migrateCallCount = 0

        let runner = MigrationStepRunner()

        await #expect(throws: StubError.self) {
            try await runner.run(
                entity: "Task",
                documentID: "doc1",
                migrate: { migrateCallCount += 1 },
                markDeleted: { throw StubError.network }
            )
        }

        #expect(migrateCallCount == 1)
    }
}
