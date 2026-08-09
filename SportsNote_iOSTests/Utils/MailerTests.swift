//
//  MailerTests.swift
//  SportsNote_iOSTests
//

import Foundation
import Testing

@testable import SportsNote_iOS

@Suite("Mailer Tests", .serialized)
@MainActor
struct MailerTests {

    @Test("createMailtoURLString - 件名・本文が二重にパーセントエンコードされない")
    func createMailtoURLString_doesNotDoubleEncode() {
        let result = Mailer.shared.createMailtoURLString(
            email: "test@example.com",
            subject: "Test Subject",
            body: "Test Body"
        )

        #expect(result != nil)
        #expect(result?.contains("%2520") == false)
        #expect(result?.contains("Test%20Subject") == true)
        #expect(result?.contains("Test%20Body") == true)
    }

    @Test("createMailtoURLString - 有効なmailto URLとしてパースできる")
    func createMailtoURLString_generatesValidURL() {
        let result = Mailer.shared.createMailtoURLString(
            email: "test@example.com",
            subject: "Subject",
            body: "Body"
        )

        #expect(result != nil)
        #expect(result?.hasPrefix("mailto:test@example.com?subject=") == true)

        let url = result.flatMap { URL(string: $0) }
        #expect(url != nil)
    }
}
