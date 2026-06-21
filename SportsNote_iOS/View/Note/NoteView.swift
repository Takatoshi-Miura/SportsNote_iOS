import SwiftUI

struct NoteView: View {
    @Binding var isMenuOpen: Bool
    @StateObject private var viewModel = NoteViewModel()
    @State private var isPracticeNotePresented = false
    @State private var isTournamentNotePresented = false
    @State private var searchQuery = ""

    /// フリーノート以外のノートが存在するか
    private var hasPagingNotes: Bool {
        viewModel.notes.contains { $0.noteType != NoteType.free.rawValue }
    }

    var body: some View {
        TabTopView(
            title: LocalizedStrings.note,
            isMenuOpen: $isMenuOpen,
            trailingItem: {
                NavigationLink(destination: NotePageView()) {
                    Image(systemName: "doc.plaintext")
                }
                .disabled(!hasPagingNotes)
            },
            content: {
                ZStack {
                    Color(.secondarySystemBackground)
                        .edgesIgnoringSafeArea(.all)
                        .dismissKeyboardOnTap()

                    VStack(spacing: 0) {
                        SearchBarView(searchText: $searchQuery) {
                            Task {
                                let result = await viewModel.fetchData()
                                if case .failure(let error) = result {
                                    viewModel.showErrorAlert(error)
                                }
                            }
                        }
                        NoteListView(viewModel: viewModel)
                            .background(Color(.systemBackground))
                            .refreshable {
                                if !searchQuery.isEmpty {
                                    viewModel.searchNotes(query: searchQuery)
                                } else {
                                    Task {
                                        let result = await viewModel.fetchData()
                                        if case .failure(let error) = result {
                                            viewModel.showErrorAlert(error)
                                        }
                                    }
                                }
                            }

                        // AdMobバナー広告
                        AdMobBannerView()
                            .frame(height: 50)
                            .background(Color(.systemBackground))
                    }
                    .onChange(of: searchQuery) { newValue in
                        if !newValue.isEmpty {
                            viewModel.searchNotes(query: newValue)
                        } else {
                            Task {
                                let result = await viewModel.fetchData()
                                if case .failure(let error) = result {
                                    viewModel.showErrorAlert(error)
                                }
                            }
                        }
                    }
                }
            },
            actionItems: [
                (LocalizedStrings.practiceNote, { isPracticeNotePresented = true }),
                (LocalizedStrings.tournamentNote, { isTournamentNotePresented = true }),
            ]
        )
        .sheet(isPresented: $isPracticeNotePresented) {
            AddPracticeNoteView(onSave: {
                Task {
                    let result = await viewModel.fetchData()
                    if case .failure(let error) = result {
                        viewModel.showErrorAlert(error)
                    }
                }
            })
        }
        .sheet(isPresented: $isTournamentNotePresented) {
            AddTournamentNoteView(onSave: {
                Task {
                    let result = await viewModel.fetchData()
                    if case .failure(let error) = result {
                        viewModel.showErrorAlert(error)
                    }
                }
            })
        }
        .task {
            let result = await viewModel.fetchData()
            if case .failure(let error) = result {
                viewModel.showErrorAlert(error)
            }
        }
        .errorAlert(
            currentError: $viewModel.currentError,
            showingAlert: $viewModel.showingErrorAlert
        )
    }
}
