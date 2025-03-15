import SwiftUI

struct TargetView: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        TabTopView(
            isMenuOpen: $isMenuOpen,
            title: LocalizedStrings.target,
            destination: TargetDetailView(),
            leadingItem: {
                MenuButton(isMenuOpen: $isMenuOpen)
            },
            trailingItem: {
                Button(action: {
                    print("Right button tapped")
                }) {
                    Image(systemName: "bell.fill")
                        .imageScale(.large)
                }
            },
            content: {
                AnyView(
                    VStack {
                        Text("Custom Content for Target View")
                        Text("Additional Content")
                    }
                )
            },
            actionItems: [
                (LocalizedStrings.yearlyTarget, {}),
                (LocalizedStrings.monthlyTarget, {})
            ]
        )
    }
}
