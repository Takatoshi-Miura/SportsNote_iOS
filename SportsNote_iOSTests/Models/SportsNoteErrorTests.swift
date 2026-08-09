//
//  SportsNoteErrorTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2026/08/01.
//

import Foundation
import Testing

@testable import SportsNote_iOS

@Suite("ErrorMapper.mapFirebaseError Tests")
struct SportsNoteErrorTests {

    // MARK: - NSURLErrorDomain（issue #53: ネットワークエラー分類）

    @Test("mapFirebaseError - 未接続エラーはnetworkUnavailableに分類される")
    func mapFirebaseError_notConnectedToInternet_returnsNetworkUnavailable() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let result = ErrorMapper.mapFirebaseError(error)

        guard case .networkUnavailable = result else {
            Issue.record("Expected .networkUnavailable but got \(result)")
            return
        }
    }

    @Test("mapFirebaseError - タイムアウトエラーはnetworkTimeoutに分類される")
    func mapFirebaseError_timedOut_returnsNetworkTimeout() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        let result = ErrorMapper.mapFirebaseError(error)

        guard case .networkTimeout = result else {
            Issue.record("Expected .networkTimeout but got \(result)")
            return
        }
    }

    @Test(
        "mapFirebaseError - その他のNSURLErrorDomainコードはfirebaseNetworkErrorに分類される",
        arguments: [
            NSURLErrorNetworkConnectionLost, NSURLErrorCannotConnectToHost, NSURLErrorDNSLookupFailed,
        ])
    func mapFirebaseError_otherURLErrors_returnsFirebaseNetworkError(code: Int) {
        let error = NSError(domain: NSURLErrorDomain, code: code)
        let result = ErrorMapper.mapFirebaseError(error)

        guard case .firebaseNetworkError = result else {
            Issue.record("Expected .firebaseNetworkError but got \(result)")
            return
        }
    }

    // MARK: - Firestore固有コード（回帰防止: 既存分類の維持確認）

    @Test(
        "mapFirebaseError - Firestore固有コードは従来通り分類される",
        arguments: [
            (7, "firebasePermissionDenied"),
            (5, "firebaseDocumentNotFound"),
            (14, "firebaseNetworkError"),
            (8, "firebaseQuotaExceeded"),
            (16, "firebaseAuthenticationFailed"),
            (13, "firebaseServerError"),
            (4, "networkTimeout"),
        ])
    func mapFirebaseError_firestoreCodes_returnsExpectedCase(code: Int, expected: String) {
        // FirestoreのNSErrorはdomainがNSURLErrorDomain以外（実際はFIRFirestoreErrorDomain相当）であることを模擬
        let error = NSError(domain: "FIRFirestoreErrorDomain", code: code)
        let result = ErrorMapper.mapFirebaseError(error)

        #expect(describeCase(result) == expected)
    }

    // MARK: - 未知・予期しないエラー

    @Test("mapFirebaseError - 1000以上の未知コードはcriticalErrorに分類される")
    func mapFirebaseError_unknownHighCode_returnsCriticalError() {
        let error = NSError(domain: "SomeOtherDomain", code: 1234)
        let result = ErrorMapper.mapFirebaseError(error, context: "test")

        guard case .criticalError = result else {
            Issue.record("Expected .criticalError but got \(result)")
            return
        }
    }

    @Test("mapFirebaseError - 未知の低コードはunexpectedErrorに分類される")
    func mapFirebaseError_unknownLowCode_returnsUnexpectedError() {
        let error = NSError(domain: "SomeOtherDomain", code: 999)
        let result = ErrorMapper.mapFirebaseError(error)

        guard case .unexpectedError = result else {
            Issue.record("Expected .unexpectedError but got \(result)")
            return
        }
    }
}

/// SportsNoteErrorがEquatable未準拠（一部caseがError型を保持するため自動合成不可）のためのcase比較用ヘルパー
private func describeCase(_ error: SportsNoteError) -> String {
    switch error {
    case .firebasePermissionDenied: return "firebasePermissionDenied"
    case .firebaseDocumentNotFound: return "firebaseDocumentNotFound"
    case .firebaseNetworkError: return "firebaseNetworkError"
    case .firebaseQuotaExceeded: return "firebaseQuotaExceeded"
    case .firebaseAuthenticationFailed: return "firebaseAuthenticationFailed"
    case .firebaseServerError: return "firebaseServerError"
    case .networkTimeout: return "networkTimeout"
    default: return "other"
    }
}
