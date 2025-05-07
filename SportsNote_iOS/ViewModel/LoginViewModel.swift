import Foundation
import Combine
import FirebaseAuth
import FirebaseCore

class LoginViewModel: ObservableObject {
    // 状態用のパブリッシャー
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var showingAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var isLoading: Bool = false
    
    // Combineのサブスクリプション管理用
    private var cancellables = Set<AnyCancellable>()
    
    // FirebaseAuthのインスタンス
    private let auth = Auth.auth()
    
    init() {
        // 初期化時にログイン状態をチェック
        checkLoginStatus()
    }
    
    // ログイン処理
    func login(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        if email.isEmpty || password.isEmpty {
            alertMessage = LocalizedStrings.pleaseEnterEmailAndPassword
            showingAlert = true
            onFailure()
            return
        }
        
        if !Network.isOnline() {
            alertMessage = LocalizedStrings.internetError
            showingAlert = true
            onFailure()
            return
        }
        
        isLoading = true
        
        auth.signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.handleAuthError(error)
                onFailure()
                return
            }
            
            if authResult?.user != nil {
                // ユーザー情報の保存
                UserDefaultsManager.set(key: UserDefaultsManager.Keys.userID, value: authResult?.user.uid ?? "")
                UserDefaultsManager.set(key: UserDefaultsManager.Keys.address, value: self.email)
                UserDefaultsManager.set(key: UserDefaultsManager.Keys.password, value: self.password)
                UserDefaultsManager.set(key: UserDefaultsManager.Keys.isLogin, value: true)
                
                // データ初期化と同期処理（実際の実装はここに追加）
                self.initializeAppData(isLogin: true)
                self.syncAllData()
                
                self.isLoggedIn = true
                self.alertMessage = LocalizedStrings.loginSuccessful
                self.showingAlert = true
                
                // 成功ハンドラーを呼び出す
                onSuccess()
            } else {
                self.alertMessage = LocalizedStrings.loginFailed
                self.showingAlert = true
                onFailure()
            }
        }
    }
    
    // ログアウト処理
    func logout(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        if !Network.isOnline() {
            alertMessage = LocalizedStrings.internetError
            showingAlert = true
            onFailure()
            return
        }
        
        do {
            try auth.signOut()
            
            // データの削除と初期化
            deleteAllData()
            initializeAppData(isLogin: false)
            
            isLoggedIn = false
            email = ""
            password = ""
            
            alertMessage = LocalizedStrings.logoutSuccessful
            showingAlert = true
            
            // 成功ハンドラーを呼び出す
            onSuccess()
        } catch {
            alertMessage = LocalizedStrings.logoutFailed
            showingAlert = true
            onFailure()
        }
    }
    
    // パスワードリセット
    func resetPassword(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        if email.isEmpty {
            alertMessage = LocalizedStrings.pleaseEnterEmail
            showingAlert = true
            onFailure()
            return
        }
        
        if !Network.isOnline() {
            alertMessage = LocalizedStrings.internetError
            showingAlert = true
            onFailure()
            return
        }
        
        isLoading = true
        
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
    
    // アカウント作成
    func createAccount(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        if email.isEmpty || password.isEmpty {
            alertMessage = LocalizedStrings.pleaseEnterEmailAndPassword
            showingAlert = true
            onFailure()
            return
        }
        
        if !Network.isOnline() {
            alertMessage = LocalizedStrings.internetError
            showingAlert = true
            onFailure()
            return
        }
        
        isLoading = true
        
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
                
                // RealmデータのuserIDを更新する処理（実際の実装はここに追加）
                self.updateAllUserIds(userId: user.uid)
                
                // データ同期
                self.syncAllData()
                
                self.isLoggedIn = true
                self.alertMessage = LocalizedStrings.accountCreated
                self.showingAlert = true
                
                // 成功ハンドラーを呼び出す
                onSuccess()
            } else {
                self.alertMessage = LocalizedStrings.createAccountFailed
                self.showingAlert = true
                onFailure()
            }
        }
    }
    
    // アカウント削除
    func deleteAccount(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        if !Network.isOnline() {
            alertMessage = LocalizedStrings.internetError
            showingAlert = true
            onFailure()
            return
        }
        
        if !isLoggedIn {
            alertMessage = LocalizedStrings.pleaseLogin
            showingAlert = true
            onFailure()
            return
        }
        
        guard let user = auth.currentUser else {
            alertMessage = LocalizedStrings.pleaseLogin
            showingAlert = true
            onFailure()
            return
        }
        
        isLoading = true
        
        user.delete { [weak self] error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.handleAuthError(error)
                onFailure()
                return
            }
            
            // データの削除と初期化
            self.deleteAllData()
            self.initializeAppData(isLogin: false)
            
            self.isLoggedIn = false
            self.email = ""
            self.password = ""
            
            self.alertMessage = LocalizedStrings.accountDeleted
            self.showingAlert = true
            onSuccess()
        }
    }
    
    // ログイン状態の確認
    private func checkLoginStatus() {
        isLoggedIn = auth.currentUser != nil
        
        if isLoggedIn {
            email = UserDefaultsManager.get(key: UserDefaultsManager.Keys.address, defaultValue: "")
            password = UserDefaultsManager.get(key: UserDefaultsManager.Keys.password, defaultValue: "")
        }
    }
    
    // Firebaseの認証エラーハンドリング
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
    
    // データの削除（実際の実装はInitializationManagerなどで行う）
    private func deleteAllData() {
        // ここにデータ削除のコードを実装
    }
    
    // アプリの初期化（実際の実装はInitializationManagerなどで行う）
    private func initializeAppData(isLogin: Bool) {
        // ここにアプリ初期化のコードを実装
    }
    
    // 全データの同期（実際の実装はSyncManagerなどで行う）
    private func syncAllData() {
        // ここにデータ同期のコードを実装
    }
    
    // ユーザーIDの更新（実際の実装はRealmManagerなどで行う）
    private func updateAllUserIds(userId: String) {
        // ここにユーザーID更新のコードを実装
    }
}
