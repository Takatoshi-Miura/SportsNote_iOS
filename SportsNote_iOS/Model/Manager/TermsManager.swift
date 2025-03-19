import SwiftUI

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
    func navigateToTermsOfService() {
        guard let url = URL(string: TermsURL.termsOfService) else { return }
        UIApplication.shared.open(url)
    }

    /// プライバシーポリシーページに遷移
    func navigateToPrivacyPolicy() {
        guard let url = URL(string: TermsURL.privacyPolicy) else { return }
        UIApplication.shared.open(url)
    }
}

struct TermsDialogView: View {
    @ObservedObject private var termsManager = TermsManager.shared

    var body: some View {
        EmptyView()
            .alert(isPresented: $termsManager.termsDialogShown) {
                Alert(
                    title: Text(LocalizedStrings.termsOfServiceTitle),
                    message: Text(LocalizedStrings.termsOfServiceMessage),
                    primaryButton: .default(Text(LocalizedStrings.checkTermsOfService)) {
                        termsManager.navigateToTermsOfServiceAndPrivacyPolicy()
                    },
                    secondaryButton: .default(Text(LocalizedStrings.agree)) {
                        UserDefaultsManager.set(key: UserDefaultsManager.Keys.agree, value: true)
                        termsManager.termsDialogShown = false
                    }
                )
            }
    }
}

