import SwiftUI

struct NoteView: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        TabTopView(
            title: LocalizedStrings.note,
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
                        NavigationLink(destination: NoteDetailView()) {
                            Text("Go to Note Detail")
                        }
                        Text("Custom Content for Note View")
                        Text("Additional Content")
                    }
                )
            },
            actionItems: [
                (LocalizedStrings.practiceNote, {}),
                (LocalizedStrings.tournamentNote, {})
            ]
        )
    }
}
