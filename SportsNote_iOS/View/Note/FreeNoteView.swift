import SwiftUI
import RealmSwift

struct FreeNoteView: View {
    let noteID: String
    @StateObject private var viewModel = NoteViewModel()
    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var isLoading: Bool = true
    @State private var detailMinHeight: CGFloat = 150
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isLoading {
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
                }
            }
        }
        .navigationTitle(LocalizedStrings.freeNote)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadData()
        }
    }
    
    /// フリーノート読み込み
    private func loadData() {
        viewModel.loadNote(id: noteID)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let note = viewModel.selectedNote {
                self.title = note.title
                self.detail = note.detail
            }
            self.isLoading = false
        }
    }
    
    /// フリーノート更新
    private func updateNote() {
        guard !isLoading, let note = viewModel.selectedNote else { return }
        
        do {
            let realm = try Realm()
            if let noteToUpdate = realm.object(ofType: Note.self, forPrimaryKey: note.noteID) {
                try realm.write {
                    noteToUpdate.title = title
                    noteToUpdate.detail = detail
                    noteToUpdate.updated_at = Date()
                }
            }
        } catch {
            print("Error updating free note: \(error)")
        }
    }
}
