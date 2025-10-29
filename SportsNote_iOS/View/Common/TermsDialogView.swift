import SwiftUI

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
                        termsManager.agreeToTerms()
                    }
                )
            }
    }
}
