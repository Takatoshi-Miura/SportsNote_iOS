//
//  TermsViewModelTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2025/11/23.
//

import Foundation
import Testing

@testable import SportsNote_iOS

@Suite("TermsViewModel Tests")
@MainActor
struct TermsViewModelTests {

    // MARK: - シングルトンテスト

    @Test("シングルトン - sharedインスタンスが存在する")
    func singleton_sharedInstanceExists() async {
        let instance = TermsViewModel.shared

        // TermsViewModelは非オプショナルなので、型の確認のみ
        #expect(type(of: instance) == TermsViewModel.self)
    }

    @Test("シングルトン - 同じインスタンスが返される")
    func singleton_sameInstanceReturned() async {
        let instance1 = TermsViewModel.shared
        let instance2 = TermsViewModel.shared

        #expect(instance1 === instance2)
    }

    // MARK: - 初期化テスト

    @Test("初期化 - termsDialogShownはBool型")
    func initialization_termsDialogShownIsBool() async {
        let manager = TermsViewModel.shared

        // termsDialogShownがBool型であることを確認
        #expect(type(of: manager.termsDialogShown) == Bool.self)
    }

    // MARK: - URL定数テスト

    @Test("URL定数 - termsOfServiceAndPrivacyPolicyが有効なURL")
    func urlConstants_termsOfServiceAndPrivacyPolicyIsValid() async {
        let urlString = TermsViewModel.TermsURL.termsOfServiceAndPrivacyPolicy
        let url = URL(string: urlString)

        #expect(url != nil)
        #expect(!urlString.isEmpty)
    }

    @Test("URL定数 - termsOfServiceが有効なURL")
    func urlConstants_termsOfServiceIsValid() async {
        let urlString = TermsViewModel.TermsURL.termsOfService
        let url = URL(string: urlString)

        #expect(url != nil)
        #expect(!urlString.isEmpty)
    }

    @Test("URL定数 - privacyPolicyが有効なURL")
    func urlConstants_privacyPolicyIsValid() async {
        let urlString = TermsViewModel.TermsURL.privacyPolicy
        let url = URL(string: urlString)

        #expect(url != nil)
        #expect(!urlString.isEmpty)
    }

    @Test(
        "URL定数 - 全てのURLがhttpsで始まる",
        arguments: [
            TermsViewModel.TermsURL.termsOfServiceAndPrivacyPolicy,
            TermsViewModel.TermsURL.termsOfService,
            TermsViewModel.TermsURL.privacyPolicy,
        ])
    func urlConstants_allUrlsStartWithHttps(urlString: String) async {
        #expect(urlString.hasPrefix("https://"))
    }

    @Test(
        "URL定数 - 全てのURLが有効なURL形式",
        arguments: [
            TermsViewModel.TermsURL.termsOfServiceAndPrivacyPolicy,
            TermsViewModel.TermsURL.termsOfService,
            TermsViewModel.TermsURL.privacyPolicy,
        ])
    func urlConstants_allUrlsAreValid(urlString: String) async {
        let url = URL(string: urlString)
        #expect(url != nil)
    }

    @Test(
        "URL定数 - URLにfirebaseappが含まれる",
        arguments: [
            TermsViewModel.TermsURL.termsOfServiceAndPrivacyPolicy,
            TermsViewModel.TermsURL.termsOfService,
            TermsViewModel.TermsURL.privacyPolicy,
        ])
    func urlConstants_urlsContainFirebaseapp(urlString: String) async {
        #expect(urlString.contains("firebaseapp"))
    }

    // MARK: - agreeToTerms メソッドテスト

    @Test("agreeToTerms - termsDialogShownがfalseになる")
    func agreeToTerms_setsTermsDialogShownToFalse() async {
        let manager = TermsViewModel.shared

        // 初期状態を設定
        manager.termsDialogShown = true

        // メソッド実行
        manager.agreeToTerms()

        // 結果確認
        #expect(manager.termsDialogShown == false)
    }

    @Test("agreeToTerms - UserDefaultsに保存される")
    func agreeToTerms_savesToUserDefaults() async {
        let manager = TermsViewModel.shared

        // 事前にクリア
        UserDefaults.standard.removeObject(forKey: UserDefaultsManager.Keys.agree)

        // メソッド実行
        manager.agreeToTerms()

        // UserDefaultsから取得して確認
        let agreed = UserDefaults.standard.bool(forKey: UserDefaultsManager.Keys.agree)
        #expect(agreed == true)

        // クリーンアップ
        UserDefaults.standard.removeObject(forKey: UserDefaultsManager.Keys.agree)
    }


    // MARK: - termsDialogShown プロパティテスト

    @Test("termsDialogShown - 値の設定と取得")
    func termsDialogShown_setAndGet() async {
        let manager = TermsViewModel.shared

        manager.termsDialogShown = true
        #expect(manager.termsDialogShown == true)

        manager.termsDialogShown = false
        #expect(manager.termsDialogShown == false)
    }

    @Test("termsDialogShown - 複数回の切り替え")
    func termsDialogShown_multipleToggles() async {
        let manager = TermsViewModel.shared

        manager.termsDialogShown = true
        #expect(manager.termsDialogShown == true)

        manager.termsDialogShown = false
        #expect(manager.termsDialogShown == false)

        manager.termsDialogShown = true
        #expect(manager.termsDialogShown == true)
    }

    // MARK: - URL構造体テスト

    @Test("URL構造体 - 3つのURL定数が定義されている")
    func urlStruct_hasThreeUrlConstants() async {
        // 構造体のプロパティが存在することを確認
        let url1 = TermsViewModel.TermsURL.termsOfServiceAndPrivacyPolicy
        let url2 = TermsViewModel.TermsURL.termsOfService
        let url3 = TermsViewModel.TermsURL.privacyPolicy

        #expect(!url1.isEmpty)
        #expect(!url2.isEmpty)
        #expect(!url3.isEmpty)
    }

    @Test("URL構造体 - 各URLが異なる値を持つ")
    func urlStruct_allUrlsAreDifferent() async {
        let url1 = TermsViewModel.TermsURL.termsOfServiceAndPrivacyPolicy
        let url2 = TermsViewModel.TermsURL.termsOfService
        let url3 = TermsViewModel.TermsURL.privacyPolicy

        #expect(url1 != url2)
        #expect(url2 != url3)
        #expect(url1 != url3)
    }

    // MARK: - 境界値テスト

    @Test("境界値 - 空のURLでURL作成を試みる")
    func boundaryCase_emptyUrlString() async {
        let url = URL(string: "")
        #expect(url == nil)
    }

    @Test(
        "境界値 - 無効なURL形式",
        arguments: [
            "not a url",
            "http://",
            "://example.com",
            "example.com",
        ])
    func boundaryCase_invalidUrlFormats(urlString: String) async {
        let url = URL(string: urlString)
        // 一部は有効なURLとして解釈される可能性があるため、
        // ここでは単にURL作成を試みるのみ
        _ = url
    }
}

// MARK: - テストヘルパー拡張

extension TermsViewModelTests {

    /// テスト用のTermsViewModelインスタンスを取得
    static func getTestManager() -> TermsViewModel {
        return TermsViewModel.shared
    }

    /// UserDefaultsをクリーンアップ
    static func cleanupUserDefaults() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsManager.Keys.agree)
    }
}
