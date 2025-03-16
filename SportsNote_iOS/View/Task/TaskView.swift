import SwiftUI

struct TaskView: View {
    @Binding var isMenuOpen: Bool
    @State private var isAddGroupPresented = false
    @ObservedObject var viewModel = GroupViewModel()

    var body: some View {
        TabTopView(
            title: LocalizedStrings.task,
            isMenuOpen: $isMenuOpen,
            trailingItem: {},
            content: {
                VStack {
                    NavigationLink(destination: TaskDetailView()) {
                        Text("Go to Task Detail")
                    }
                    Text("Custom Content for Task View")
                    Text("Additional Content")
                }
            },
            actionItems: [
                (LocalizedStrings.group, { isAddGroupPresented = true} ),
                (LocalizedStrings.task, { TermsManager.showDialog() })
            ]
        )
        .overlay(TermsDialogView())
        .sheet(isPresented: $isAddGroupPresented) {
            AddGroupView(viewModel: viewModel)
        }
    }
}
