import SwiftUI

struct NoteView: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        TabTopView(
            isMenuOpen: $isMenuOpen,
            title: LocalizedStrings.note,
            destination: NoteDetailView(),
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
