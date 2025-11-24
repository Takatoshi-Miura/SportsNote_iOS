//
//  LoginViewModelTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2025/11/23.
//

import Foundation
import Testing

@testable import SportsNote_iOS

@Suite("LoginViewModel Tests")
@MainActor
struct LoginViewModelTests {
    
    // MARK: - 初期化テスト
    
    @Test("初期化 - プロパティが正しく初期化される")
    func initialization_propertiesAreInitializedCorrectly() async {
        let viewModel = LoginViewModel()
        
        // Note: checkLoginStatus()が呼ばれるため、実際の値は認証状態に依存
        // ここでは基本的なプロパティの型確認のみ
        #expect(type(of: viewModel.email) == String.self)
        #expect(type(of: viewModel.password) == String.self)
        #expect(viewModel.showingAlert == false)
        #expect(viewModel.alertMessage == "")
        #expect(viewModel.isLoading == false)
    }
    
    // MARK: - バリデーションテスト
    
    @Test("バリデーション - 空のメールアドレスでエラー")
    func validation_emptyEmailShowsError() async {
        let viewModel = LoginViewModel()
        viewModel.email = ""
        viewModel.password = "password123"
        
        var failureCalled = false
        viewModel.login(
            onSuccess: {},
            onFailure: { failureCalled = true }
        )
        
        #expect(failureCalled == true)
        #expect(viewModel.showingAlert == true)
        #expect(!viewModel.alertMessage.isEmpty)
    }
    
    @Test("バリデーション - 空のパスワードでエラー")
    func validation_emptyPasswordShowsError() async {
        let viewModel = LoginViewModel()
        viewModel.email = "test@example.com"
        viewModel.password = ""
        
        var failureCalled = false
        viewModel.login(
            onSuccess: {},
            onFailure: { failureCalled = true }
        )
        
        #expect(failureCalled == true)
        #expect(viewModel.showingAlert == true)
        #expect(!viewModel.alertMessage.isEmpty)
    }
    
    @Test("バリデーション - メールとパスワード両方が空でエラー")
    func validation_bothEmptyShowsError() async {
        let viewModel = LoginViewModel()
        viewModel.email = ""
        viewModel.password = ""
        
        var failureCalled = false
        viewModel.login(
            onSuccess: {},
            onFailure: { failureCalled = true }
        )
        
        #expect(failureCalled == true)
        #expect(viewModel.showingAlert == true)
    }
    
    @Test("バリデーション - パスワードリセット時の空メールでエラー")
    func validation_resetPasswordWithEmptyEmail() async {
        let viewModel = LoginViewModel()
        viewModel.email = ""
        
        var failureCalled = false
        viewModel.resetPassword(
            onSuccess: {},
            onFailure: { failureCalled = true }
        )
        
        #expect(failureCalled == true)
        #expect(viewModel.showingAlert == true)
    }
    
    // MARK: - clearEmail メソッドテスト
    
    @Test("clearEmail - メールアドレスがクリアされる")
    func clearEmail_clearsEmailAddress() async {
        let viewModel = LoginViewModel()
        viewModel.email = "test@example.com"
        
        viewModel.clearEmail()
        
        #expect(viewModel.email == "")
    }
    
    @Test("clearEmail - 既に空の場合も問題なく動作")
    func clearEmail_worksWhenAlreadyEmpty() async {
        let viewModel = LoginViewModel()
        viewModel.email = ""
        
        viewModel.clearEmail()
        
        #expect(viewModel.email == "")
    }
    
    // MARK: - プロパティテスト
    
    @Test("プロパティ - email設定と取得")
    func property_emailSetAndGet() async {
        let viewModel = LoginViewModel()
        let testEmail = "test@example.com"
        
        viewModel.email = testEmail
        
        #expect(viewModel.email == testEmail)
    }
    
    @Test("プロパティ - password設定と取得")
    func property_passwordSetAndGet() async {
        let viewModel = LoginViewModel()
        let testPassword = "securePassword123"
        
        viewModel.password = testPassword
        
        #expect(viewModel.password == testPassword)
    }
    
    @Test("プロパティ - 複数のメールアドレス形式", 
          arguments: [
            "test@example.com",
            "user.name@example.co.jp",
            "test+tag@example.com",
            "123@test.com",
            "a@b.c"
          ])
    func property_variousEmailFormats(email: String) async {
        let viewModel = LoginViewModel()
        
        viewModel.email = email
        
        #expect(viewModel.email == email)
    }
    
    @Test("プロパティ - 様々なパスワード長", 
          arguments: [
            "short",
            "mediumPassword",
            "veryLongPasswordWith123Numbers",
            String(repeating: "a", count: 100)
          ])
    func property_variousPasswordLengths(password: String) async {
        let viewModel = LoginViewModel()
        
        viewModel.password = password
        
        #expect(viewModel.password == password)
    }
    
    // MARK: - アラート状態テスト
    
    @Test("アラート - showingAlertの初期状態はfalse")
    func alert_initialShowingAlertIsFalse() async {
        let viewModel = LoginViewModel()
        
        #expect(viewModel.showingAlert == false)
    }
    
    @Test("アラート - alertMessageの初期状態は空文字")
    func alert_initialAlertMessageIsEmpty() async {
        let viewModel = LoginViewModel()
        
        #expect(viewModel.alertMessage == "")
    }
    
    @Test("アラート - alertMessage設定と取得")
    func alert_messageSetAndGet() async {
        let viewModel = LoginViewModel()
        let testMessage = "テストメッセージ"
        
        viewModel.alertMessage = testMessage
        
        #expect(viewModel.alertMessage == testMessage)
    }
    
    // MARK: - ローディング状態テスト
    
    @Test("ローディング - isLoadingの初期状態はfalse")
    func loading_initialIsLoadingIsFalse() async {
        let viewModel = LoginViewModel()
        
        #expect(viewModel.isLoading == false)
    }
    
    @Test("ローディング - isLoading設定と取得")
    func loading_isLoadingSetAndGet() async {
        let viewModel = LoginViewModel()
        
        viewModel.isLoading = true
        #expect(viewModel.isLoading == true)
        
        viewModel.isLoading = false
        #expect(viewModel.isLoading == false)
    }
    
    // MARK: - 境界値テスト
    
    @Test("境界値 - 非常に長いメールアドレス")
    func boundaryCase_veryLongEmail() async {
        let viewModel = LoginViewModel()
        let longEmail = String(repeating: "a", count: 200) + "@example.com"
        
        viewModel.email = longEmail
        
        #expect(viewModel.email == longEmail)
    }
    
    @Test("境界値 - 特殊文字を含むメールアドレス",
          arguments: [
            "test+tag@example.com",
            "user.name@example.com",
            "user_name@example.com",
            "user-name@example.com"
          ])
    func boundaryCase_specialCharactersInEmail(email: String) async {
        let viewModel = LoginViewModel()
        
        viewModel.email = email
        
        #expect(viewModel.email == email)
    }
    
    @Test("境界値 - 特殊文字を含むパスワード",
          arguments: [
            "Pass@word123",
            "P@ssw0rd!",
            "Test#123$",
            "パスワード123"
          ])
    func boundaryCase_specialCharactersInPassword(password: String) async {
        let viewModel = LoginViewModel()
        
        viewModel.password = password
        
        #expect(viewModel.password == password)
    }
    
    @Test("境界値 - 空白を含むメールアドレス")
    func boundaryCase_emailWithSpaces() async {
        let viewModel = LoginViewModel()
        let emailWithSpaces = " test@example.com "
        
        viewModel.email = emailWithSpaces
        
        #expect(viewModel.email == emailWithSpaces)
    }
    
    @Test("境界値 - 空白を含むパスワード")
    func boundaryCase_passwordWithSpaces() async {
        let viewModel = LoginViewModel()
        let passwordWithSpaces = " password 123 "
        
        viewModel.password = passwordWithSpaces
        
        #expect(viewModel.password == passwordWithSpaces)
    }
    
    // MARK: - 複数プロパティの同時設定テスト
    
    @Test("複数プロパティ - メールとパスワードを同時設定")
    func multipleProperties_setEmailAndPasswordTogether() async {
        let viewModel = LoginViewModel()
        let testEmail = "test@example.com"
        let testPassword = "password123"
        
        viewModel.email = testEmail
        viewModel.password = testPassword
        
        #expect(viewModel.email == testEmail)
        #expect(viewModel.password == testPassword)
    }
    
    @Test("複数プロパティ - 全てのアラート関連プロパティを設定")
    func multipleProperties_setAllAlertProperties() async {
        let viewModel = LoginViewModel()
        
        viewModel.showingAlert = true
        viewModel.alertMessage = "テストアラート"
        
        #expect(viewModel.showingAlert == true)
        #expect(viewModel.alertMessage == "テストアラート")
    }
    
    // MARK: - 状態遷移テスト
    
    @Test("状態遷移 - ログイン状態の変更")
    func stateTransition_loginStateChange() async {
        let viewModel = LoginViewModel()
        
        // 初期状態を確認
        let initialState = viewModel.isLoggedIn
        
        // 状態を変更
        viewModel.isLoggedIn = !initialState
        
        #expect(viewModel.isLoggedIn == !initialState)
    }
    
    @Test("状態遷移 - アラート表示から非表示へ")
    func stateTransition_alertShowToHide() async {
        let viewModel = LoginViewModel()
        
        viewModel.showingAlert = true
        #expect(viewModel.showingAlert == true)
        
        viewModel.showingAlert = false
        #expect(viewModel.showingAlert == false)
    }
    
    @Test("状態遷移 - ローディング開始から終了へ")
    func stateTransition_loadingStartToEnd() async {
        let viewModel = LoginViewModel()
        
        viewModel.isLoading = true
        #expect(viewModel.isLoading == true)
        
        viewModel.isLoading = false
        #expect(viewModel.isLoading == false)
    }
}

// MARK: - テストヘルパー拡張

extension LoginViewModelTests {
    
    /// テスト用の有効なメールアドレスを生成
    static func createValidEmail(prefix: String = "test") -> String {
        return "\(prefix)@example.com"
    }
    
    /// テスト用の有効なパスワードを生成
    static func createValidPassword(length: Int = 8) -> String {
        return String(repeating: "a", count: length)
    }
    
    /// テスト用のLoginViewModelを作成
    static func createTestViewModel(
        email: String = "",
        password: String = ""
    ) -> LoginViewModel {
        let viewModel = LoginViewModel()
        viewModel.email = email
        viewModel.password = password
        return viewModel
    }
}
