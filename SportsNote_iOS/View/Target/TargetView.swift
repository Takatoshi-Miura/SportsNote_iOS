import SwiftUI

struct TargetView: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        TabTopView(
            title: LocalizedStrings.target,
            isMenuOpen: $isMenuOpen,
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
                        NavigationLink(destination: TargetDetailView()) {
                            Text("Go to Target Detail")
                        }
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
