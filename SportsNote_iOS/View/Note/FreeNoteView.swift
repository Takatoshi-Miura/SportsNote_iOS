import SwiftUI
import RealmSwift
import Combine

struct FreeNoteView: View {
    let noteID: String
    @StateObject private var viewModel = NoteViewModel()
    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var detailMinHeight: CGFloat = 150
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if viewModel.isLoadingNote {
                    VStack {
                        Text("Loading note...")
                            .foregroundColor(.gray)
                            .italic()
                        ProgressView()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    Form {
                        // タイトル
                        Section(header: Text(LocalizedStrings.title)) {
                            TextField(LocalizedStrings.title, text: $title)
                                .onChange(of: title) { _ in
                                    updateNote()
                                }
                        }
                        
                        // 詳細
                        Section(header: Text(LocalizedStrings.detail)) {
                            AutoResizingTextEditor(text: $detail, placeholder: LocalizedStrings.detail, minHeight: detailMinHeight)
                                .onChange(of: detail) { _ in
                                    updateNote()
                                }
                        }
                    }
                    .onAppear {
                        // 画面下部までの高さを計算してminHeightに設定
                        let titleSectionHeight: CGFloat = 150
                        let formPadding: CGFloat = 30
                        self.detailMinHeight = max(150, geometry.size.height - titleSectionHeight - formPadding)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                }
            }
        }
        .navigationTitle(LocalizedStrings.freeNote)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadData()
        }
        .onChange(of: viewModel.selectedNote) { newNote in
            if let note = newNote {
                self.title = note.title
                self.detail = note.detail
            }
        }
    }
    
    /// フリーノート読み込み
    private func loadData() {
        viewModel.loadNote(id: noteID)
        
        if let note = viewModel.selectedNote {
            self.title = note.title
            self.detail = note.detail
        }
    }
    
    /// フリーノート更新
    private func updateNote() {
        guard !viewModel.isLoadingNote, let note = viewModel.selectedNote else { return }
        
        viewModel.saveFreeNote(
            noteID: note.noteID,
            title: title,
            detail: detail,
            created_at: note.created_at
        )
    }
    
    /// キーボードを閉じる
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
