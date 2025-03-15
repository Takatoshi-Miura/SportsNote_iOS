import SwiftUI

struct NoteView: View {
    var body: some View {
        TabTopView(
            title: LocalizedStrings.note,
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
