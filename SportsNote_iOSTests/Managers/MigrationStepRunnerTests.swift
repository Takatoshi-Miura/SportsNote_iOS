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
@Suite("MigrationStepRunner Tests")
@MainActor
struct MigrationStepRunnerTests {

    private enum StubError: Error {
        case network
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
