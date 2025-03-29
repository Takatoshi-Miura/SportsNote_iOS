import Foundation
import Combine

class LoginViewModel: ObservableObject {
    // 状態用のパブリッシャー
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var showingAlert: Bool = false
    @Published var alertMessage: String = ""
    
    // Combineのサブスクリプション管理用
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 初期化時にログイン状態をチェック
        checkLoginStatus()
    }
    
    // ログイン処理
    func login() {
        // 本来はFirebaseなどの認証処理を行う
        // 成功したらisLoggedInをtrueに設定
        
        // テスト用の簡易処理
        if !email.isEmpty && !password.isEmpty {
            isLoggedIn = true
            alertMessage = LocalizedStrings.loginSuccessful
            showingAlert = true
        } else {
            alertMessage = LocalizedStrings.pleaseEnterEmailAndPassword
            showingAlert = true
        }
    }
    
    // ログアウト処理
    func logout() {
        // 実際のログアウト処理を実装
        isLoggedIn = false
        email = ""
        password = ""
        
        alertMessage = LocalizedStrings.logoutSuccessful
        showingAlert = true
    }
    
    // パスワードリセット
    func resetPassword() {
        if email.isEmpty {
            alertMessage = LocalizedStrings.pleaseEnterEmail
            showingAlert = true
            return
        }
        
        // 実際のパスワードリセットのロジックを実装
        alertMessage = LocalizedStrings.passwordResetEmailSent
        showingAlert = true
    }
    
    // アカウント作成
    func createAccount() {
        if email.isEmpty || password.isEmpty {
            alertMessage = LocalizedStrings.pleaseEnterEmailAndPassword
            showingAlert = true
            return
        }
        
        // 実際のアカウント作成のロジックを実装
        alertMessage = LocalizedStrings.accountCreated
        showingAlert = true
    }
    
    // アカウント削除
    func deleteAccount() {
        // 実際のアカウント削除のロジックを実装
        
        alertMessage = LocalizedStrings.accountDeleted
        showingAlert = true
        isLoggedIn = false
        email = ""
        password = ""
    }
    
    // ログイン状態の確認
    private func checkLoginStatus() {
        // 実際にはFirebaseなどからログイン状態を取得して設定
        // 今回はテスト用の簡易処理
        isLoggedIn = false // 最初は未ログイン状態
    }
}