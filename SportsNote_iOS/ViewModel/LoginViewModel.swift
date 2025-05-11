import Foundation
import Combine
import FirebaseAuth
import FirebaseCore

class LoginViewModel: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var showingAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let auth = Auth.auth()
    
    init() {
        checkLoginStatus()
    }
    
    /// ログイン処理
    /// - Parameters:
    ///   - onSuccess: 成功時の処理
    ///   - onFailure: 失敗時の処理
    func login(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        // 未入力エラー
        if email.isEmpty || password.isEmpty {
            alertMessage = LocalizedStrings.pleaseEnterEmailAndPassword
            showingAlert = true
            onFailure()
            return
        }
        
        // オフラインエラー
        if !Network.isOnline() {
            alertMessage = LocalizedStrings.internetError
            showingAlert = true
            onFailure()
            return
        }
        
        isLoading = true
        
        // ログイン処理
        auth.signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.handleAuthError(error)
                onFailure()
                return
            }
            
            if authResult?.user != nil {
                // データ全削除
                Task.detached {
                    await InitializationManager.shared.deleteAllData()
                }
                
                // ユーザー情報の保存
                UserDefaultsManager.set(key: UserDefaultsManager.Keys.firstLaunch, value: false)
                UserDefaultsManager.set(key: UserDefaultsManager.Keys.userID, value: authResult?.user.uid ?? "")
                UserDefaultsManager.set(key: UserDefaultsManager.Keys.address, value: self.email)
                UserDefaultsManager.set(key: UserDefaultsManager.Keys.password, value: self.password)
                UserDefaultsManager.set(key: UserDefaultsManager.Keys.isLogin, value: true)
                
                // データ初期化と同期処理
                Task.detached {
                    await InitializationManager.shared.initializeApp(isLogin: true)
                    await InitializationManager.shared.syncAllData()
                }
                
                self.isLoggedIn = true
                self.alertMessage = LocalizedStrings.loginSuccessful
                self.showingAlert = true
                onSuccess()
            } else {
                self.alertMessage = LocalizedStrings.loginFailed
                self.showingAlert = true
                onFailure()
            }
        }
    }
    
    /// ログアウト処理
    /// - Parameters:
    ///   - onSuccess: 成功時の処理
    ///   - onFailure: 失敗時の処理
    func logout(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        // オフラインエラー
        if !Network.isOnline() {
            alertMessage = LocalizedStrings.internetError
            showingAlert = true
            onFailure()
            return
        }
        
        do {
            try auth.signOut()
            
            // データの削除と初期化
            Task.detached {
                await InitializationManager.shared.deleteAllData()
                await InitializationManager.shared.initializeApp(isLogin: false)
            }
            
            isLoggedIn = false
            email = ""
            password = ""
            alertMessage = LocalizedStrings.logoutSuccessful
            showingAlert = true
            onSuccess()
        } catch {
            alertMessage = LocalizedStrings.logoutFailed
            showingAlert = true
            onFailure()
        }
    }
    
    /// パスワードリセット処理
    /// - Parameters:
    ///   - onSuccess: 成功時の処理
    ///   - onFailure: 失敗時の処理
    func resetPassword(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        // 未入力エラー
        if email.isEmpty {
            alertMessage = LocalizedStrings.pleaseEnterEmail
            showingAlert = true
            onFailure()
            return
        }
        
        // オフラインエラー
        if !Network.isOnline() {
            alertMessage = LocalizedStrings.internetError
            showingAlert = true
            onFailure()
            return
        }
        
        isLoading = true
        
        // パスワードリセット処理
        auth.sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.handleAuthError(error)
                onFailure()
                return
            }
            
            self.alertMessage = LocalizedStrings.passwordResetEmailSent
            self.showingAlert = true
            onSuccess()
        }
    }
    
    /// アカウント作成処理
    /// - Parameters:
    ///   - onSuccess: 成功時の処理
    ///   - onFailure: 失敗時の処理
    func createAccount(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        // 未入力エラー
        if email.isEmpty || password.isEmpty {
            alertMessage = LocalizedStrings.pleaseEnterEmailAndPassword
            showingAlert = true
            onFailure()
            return
        }
        
        // オフラインエラー
        if !Network.isOnline() {
            alertMessage = LocalizedStrings.internetError
            showingAlert = true
            onFailure()
            return
        }
        
        isLoading = true
        
        // アカウント作成処理
        auth.createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.handleAuthError(error)
                onFailure()
                return
            }
            
            if let user = authResult?.user {
                // ユーザー情報の保存
                UserDefaultsManager.set(key: UserDefaultsManager.Keys.userID, value: user.uid)
                UserDefaultsManager.set(key: UserDefaultsManager.Keys.address, value: self.email)
                UserDefaultsManager.set(key: UserDefaultsManager.Keys.password, value: self.password)
                UserDefaultsManager.set(key: UserDefaultsManager.Keys.isLogin, value: true)
                
                // データ同期
                let userId = user.uid
                Task.detached {
                    await InitializationManager.shared.updateAllUserIds(userId: userId)
                    await InitializationManager.shared.syncAllData()
                }
                
                self.isLoggedIn = true
                self.alertMessage = LocalizedStrings.accountCreated
                self.showingAlert = true
                onSuccess()
            } else {
                self.alertMessage = LocalizedStrings.createAccountFailed
                self.showingAlert = true
                onFailure()
            }
        }
    }
    
    /// アカウント削除処理
    /// - Parameters:
    ///   - onSuccess: 成功時の処理
    ///   - onFailure: 失敗時の処理
    func deleteAccount(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        // オフラインエラー
        if !Network.isOnline() {
            alertMessage = LocalizedStrings.internetError
            showingAlert = true
            onFailure()
            return
        }
        
        // 未ログインエラー
        guard let user = auth.currentUser, isLoggedIn else {
            alertMessage = LocalizedStrings.pleaseLogin
            showingAlert = true
            onFailure()
            return
        }
        
        isLoading = true
        
        // アカウント削除処理
        user.delete { [weak self] error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.handleAuthError(error)
                onFailure()
                return
            }
            
            // データの削除と初期化
            Task.detached {
                await InitializationManager.shared.deleteAllData()
                await InitializationManager.shared.initializeApp(isLogin: false)
            }
            
            self.isLoggedIn = false
            self.email = ""
            self.password = ""
            self.alertMessage = LocalizedStrings.accountDeleted
            self.showingAlert = true
            onSuccess()
        }
    }
    
    /// ログイン状態の確認
    private func checkLoginStatus() {
        isLoggedIn = auth.currentUser != nil
        
        if isLoggedIn {
            email = UserDefaultsManager.get(key: UserDefaultsManager.Keys.address, defaultValue: "")
            password = UserDefaultsManager.get(key: UserDefaultsManager.Keys.password, defaultValue: "")
        }
    }
    
    /// Firebaseの認証エラーハンドリング
    private func handleAuthError(_ error: Error) {
        let authError = error as NSError
        
        switch authError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            alertMessage = LocalizedStrings.invalidCredentialsError
        case AuthErrorCode.invalidEmail.rawValue:
            alertMessage = LocalizedStrings.invalidCredentialsError
        case AuthErrorCode.userNotFound.rawValue:
            alertMessage = LocalizedStrings.invalidUserError
        case AuthErrorCode.networkError.rawValue:
            alertMessage = LocalizedStrings.networkError
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            alertMessage = LocalizedStrings.userCollisionError
        case AuthErrorCode.weakPassword.rawValue:
            alertMessage = LocalizedStrings.weakPasswordError
        case AuthErrorCode.requiresRecentLogin.rawValue:
            alertMessage = LocalizedStrings.recentLoginRequiredError
        default:
            alertMessage = error.localizedDescription
        }
        
        showingAlert = true
    }
}

