import SwiftUI

struct NoteView: View {
    var body: some View {
        TabTopView(
            title: LocalizedStrings.note,
            destination: NoteDetailView(),
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
