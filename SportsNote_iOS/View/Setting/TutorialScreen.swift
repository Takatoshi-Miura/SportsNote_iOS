import SwiftUI

struct TutorialScreen: View {
    var onDismiss: () -> Void

    var body: some View {
        TutorialView()
            .onDisappear {
                onDismiss()
            }
    }
}
