import Foundation
import UIKit

@MainActor
class TermsManager: ObservableObject {
    static let shared = TermsManager()
    @Published var termsDialogShown = false

    /// 利用規約・プライバシーポリシーのURL
    struct TermsURL {
        static let termsOfServiceAndPrivacyPolicy = "https://sportnote-b2c92.firebaseapp.com/"
        static let termsOfService = "https://sportsnote-terms-of-service.firebaseapp.com/"
        static let privacyPolicy = "https://sportsnote-privacy-policy.firebaseapp.com/"
    }

    /// 利用規約・プライバシーポリシー確認ダイアログを表示
    static func showDialog() {
        DispatchQueue.main.async {
            shared.termsDialogShown = true
        }
    }

    /// 利用規約・プライバシーポリシーページに遷移
    func navigateToTermsOfServiceAndPrivacyPolicy() {
        guard let url = URL(string: TermsURL.termsOfServiceAndPrivacyPolicy) else { return }
        UIApplication.shared.open(url)
    }

    /// 利用規約ページに遷移
    static func navigateToTermsOfService() {
        guard let url = URL(string: TermsURL.termsOfService) else { return }
        UIApplication.shared.open(url)
    }

    /// プライバシーポリシーページに遷移
    static func navigateToPrivacyPolicy() {
        guard let url = URL(string: TermsURL.privacyPolicy) else { return }
        UIApplication.shared.open(url)
    }

    /// 利用規約に同意
    func agreeToTerms() {
        UserDefaultsManager.set(key: UserDefaultsManager.Keys.agree, value: true)
        termsDialogShown = false
    }
}
