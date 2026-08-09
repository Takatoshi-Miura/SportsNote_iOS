import SwiftUI

struct TermsDialogView: View {
    @ObservedObject private var termsViewModel = TermsViewModel.shared

    var body: some View {
        EmptyView()
            .alert(isPresented: $termsViewModel.termsDialogShown) {
                Alert(
                    title: Text(LocalizedStrings.termsOfServiceTitle),
                    message: Text(LocalizedStrings.termsOfServiceMessage),
                    primaryButton: .default(Text(LocalizedStrings.checkTermsOfService)) {
                        TermsViewModel.navigateToTermsOfService()
                    },
                    secondaryButton: .default(Text(LocalizedStrings.agree)) {
                        termsViewModel.agreeToTerms()
                    }
                )
            }
    }
}
