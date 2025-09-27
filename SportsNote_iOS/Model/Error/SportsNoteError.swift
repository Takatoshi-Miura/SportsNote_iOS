import Foundation
import RealmSwift

/// SportsNoteアプリ専用のエラー型
/// FirebaseとRealmの例外を体系的に管理し、予期しないエラーも含めて対応
enum SportsNoteError: LocalizedError {

    // MARK: - Realmエラー
    case realmInitializationFailed
    case realmWriteFailed(String)
    case realmReadFailed(String)
    case realmDeleteFailed(String)
    case realmMigrationFailed

    // MARK: - Firebaseエラー
    case firebaseNotConnected
    case firebaseAuthenticationFailed
    case firebasePermissionDenied
    case firebaseDocumentNotFound
    case firebaseNetworkError
    case firebaseQuotaExceeded
    case firebaseServerError

    // MARK: - ネットワークエラー
    case networkUnavailable
    case networkTimeout

    // MARK: - 予期しないエラー
    case unexpectedError(Error)  // 予期しない一般的なエラー
    case systemError(String)  // システムレベルのエラー
    case unknownError(String)  // 分類不可能なエラー
    case criticalError(Error, context: String)  // 重大なエラー（コンテキスト情報付き）

    /// ローカライズされたエラーメッセージ
    var errorDescription: String? {
        switch self {
        // Realmエラー
        case .realmInitializationFailed:
            return LocalizedStrings.errorRealmInitFailed
        case .realmWriteFailed(let detail):
            return "\(LocalizedStrings.errorRealmWriteFailed): \(detail)"
        case .realmReadFailed(let detail):
            return "\(LocalizedStrings.errorRealmReadFailed): \(detail)"
        case .realmDeleteFailed(let detail):
            return "\(LocalizedStrings.errorRealmDeleteFailed): \(detail)"
        case .realmMigrationFailed:
            return LocalizedStrings.errorRealmMigrationFailed

        // Firebaseエラー
        case .firebaseNotConnected:
            return LocalizedStrings.errorFirebaseNotConnected
        case .firebaseAuthenticationFailed:
            return LocalizedStrings.errorFirebaseAuthFailed
        case .firebasePermissionDenied:
            return LocalizedStrings.errorFirebasePermissionDenied
        case .firebaseDocumentNotFound:
            return LocalizedStrings.errorFirebaseDocumentNotFound
        case .firebaseNetworkError:
            return LocalizedStrings.errorFirebaseNetworkError
        case .firebaseQuotaExceeded:
            return LocalizedStrings.errorFirebaseQuotaExceeded
        case .firebaseServerError:
            return LocalizedStrings.errorFirebaseServerError

        // ネットワークエラー
        case .networkUnavailable:
            return LocalizedStrings.errorNetworkUnavailable
        case .networkTimeout:
            return LocalizedStrings.errorNetworkTimeout

        // 予期しないエラー
        case .unexpectedError(let error):
            return "\(LocalizedStrings.errorUnexpected): \(error.localizedDescription)"
        case .systemError(let message):
            return "\(LocalizedStrings.errorSystem): \(message)"
        case .unknownError(let message):
            return "\(LocalizedStrings.errorUnknown): \(message)"
        case .criticalError(let error, let context):
            return "\(LocalizedStrings.errorCritical) [\(context)]: \(error.localizedDescription)"
        }
    }

    /// ユーザー向けの回復提案
    var recoverySuggestion: String? {
        switch self {
        // Realmエラーの回復提案
        case .realmWriteFailed, .realmReadFailed, .realmDeleteFailed:
            return LocalizedStrings.errorRealmRecovery
        case .realmInitializationFailed, .realmMigrationFailed:
            return LocalizedStrings.errorRealmInitRecovery

        // Firebaseエラーの回復提案
        case .firebaseNetworkError, .networkUnavailable, .networkTimeout:
            return LocalizedStrings.errorNetworkRecovery
        case .firebaseAuthenticationFailed:
            return LocalizedStrings.errorFirebaseAuthRecovery
        case .firebasePermissionDenied:
            return LocalizedStrings.errorFirebasePermissionRecovery
        case .firebaseQuotaExceeded:
            return LocalizedStrings.errorFirebaseQuotaRecovery
        case .firebaseDocumentNotFound:
            return LocalizedStrings.errorFirebaseDocumentRecovery

        // 予期しないエラーの回復提案
        case .unexpectedError, .systemError, .unknownError:
            return LocalizedStrings.errorUnexpectedRecovery
        case .criticalError:
            return LocalizedStrings.errorCriticalRecovery

        // その他のエラー
        case .firebaseNotConnected, .firebaseServerError:
            return LocalizedStrings.errorFirebaseServerRecovery
        }
    }
}

// MARK: - ErrorMapper
/// FirebaseとRealmのエラーをSportsNoteErrorに変換するヘルパー
struct ErrorMapper {

    /// RealmエラーをSportsNoteErrorに変換
    /// - Parameters:
    ///   - error: 発生したエラー
    ///   - context: エラーが発生したコンテキスト情報
    /// - Returns: 変換されたSportsNoteError
    static func mapRealmError(_ error: Error, context: String = "") -> SportsNoteError {
        // Realmの既知エラー判定
        if let realmError = error as? Realm.Error {
            switch realmError.code {
            case .fail:
                return .realmWriteFailed("Realm Error: \(realmError.localizedDescription)")
            case .fileNotFound:
                return .realmInitializationFailed
            case .filePermissionDenied:
                return .realmReadFailed("Permission denied: \(realmError.localizedDescription)")
            default:
                return .realmInitializationFailed
            }
        }

        // NSErrorの場合の処理
        if let nsError = error as NSError? {
            // ファイルシステムエラー
            if nsError.domain == NSCocoaErrorDomain {
                switch nsError.code {
                case NSFileReadNoPermissionError, NSFileWriteNoPermissionError:
                    return .realmReadFailed("File permission error")
                case NSFileNoSuchFileError:
                    return .realmInitializationFailed
                default:
                    break
                }
            }
        }

        // メモリ関連のエラーチェック
        if error.localizedDescription.lowercased().contains("memory") {
            return .criticalError(error, context: "Realm-Memory-\(context)")
        }

        // 予期しないRealmエラー
        return .unexpectedError(error)
    }

    /// FirebaseエラーをSportsNoteErrorに変換
    /// - Parameters:
    ///   - error: 発生したエラー
    ///   - context: エラーが発生したコンテキスト情報
    /// - Returns: 変換されたSportsNoteError
    static func mapFirebaseError(_ error: Error, context: String = "") -> SportsNoteError {
        // FirebaseのNSError処理
        if let nsError = error as NSError? {
            // Firestore エラーコード
            switch nsError.code {
            case 7:  // PERMISSION_DENIED
                return .firebasePermissionDenied
            case 5:  // NOT_FOUND
                return .firebaseDocumentNotFound
            case 14:  // UNAVAILABLE
                return .firebaseNetworkError
            case 8:  // RESOURCE_EXHAUSTED
                return .firebaseQuotaExceeded
            case 16:  // UNAUTHENTICATED
                return .firebaseAuthenticationFailed
            case 13:  // INTERNAL
                return .firebaseServerError
            case 4:  // DEADLINE_EXCEEDED
                return .networkTimeout
            default:
                // 予期しないFirebaseエラー
                if nsError.code >= 1000 {
                    return .criticalError(error, context: "Firebase-\(context)")
                }
                return .unexpectedError(error)
            }
        }

        // ネットワーク関連のエラーチェック
        if let nsError = error as NSError?, nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return .networkUnavailable
            case NSURLErrorTimedOut:
                return .networkTimeout
            default:
                return .firebaseNetworkError
            }
        }

        // 完全に不明なエラー
        return .unknownError("Firebase Error: \(error.localizedDescription)")
    }

    /// システムエラーを統一的にマッピング
    /// - Parameters:
    ///   - error: 発生したエラー
    ///   - context: エラーが発生したコンテキスト
    /// - Returns: 変換されたSportsNoteError
    static func mapSystemError(_ error: Error, context: String) -> SportsNoteError {
        let errorDescription = error.localizedDescription.lowercased()

        // メモリ不足エラー
        if errorDescription.contains("memory") || errorDescription.contains("malloc") {
            return .criticalError(error, context: "Memory-\(context)")
        }

        // ファイルシステムエラー
        if errorDescription.contains("file") || errorDescription.contains("disk") {
            return .systemError("FileSystem-\(context): \(error.localizedDescription)")
        }

        // その他のシステムエラー
        return .systemError("\(context): \(error.localizedDescription)")
    }
}
