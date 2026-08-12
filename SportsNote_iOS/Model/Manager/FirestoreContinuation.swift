@preconcurrency import FirebaseFirestore
import Foundation

/// Firestoreのコールバックベース API（`(Error?) -> Void`）を `async throws` でラップする
/// - Parameter operation: コールバックを受け取り、Firestore操作を実行するクロージャ
/// - Note: `FirebaseManager`/`MigrationManager`がいずれも`@MainActor`のため、
///   呼び出し元と同一Actorに揃えてSendable境界を跨がないようにする
@MainActor
func withFirestoreContinuation(
    _ operation: (@escaping (Error?) -> Void) -> Void
) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        operation { error in
            if let error = error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: ())
            }
        }
    }
}

/// Firestoreのコールバックベース API（`(QuerySnapshot?, Error?) -> Void`）を `async throws` でラップし、
/// 取得した `QueryDocumentSnapshot` の配列を返す
/// - Parameter operation: コールバックを受け取り、Firestoreクエリを実行するクロージャ
/// - Note: `FirebaseManager`/`MigrationManager`がいずれも`@MainActor`のため、
///   呼び出し元と同一Actorに揃えてSendable境界を跨がないようにする
@MainActor
func withFirestoreQueryContinuation(
    _ operation: (@escaping (QuerySnapshot?, Error?) -> Void) -> Void
) async throws -> [QueryDocumentSnapshot] {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[QueryDocumentSnapshot], Error>) in
        operation { snapshot, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: snapshot?.documents ?? [])
            }
        }
    }
}
