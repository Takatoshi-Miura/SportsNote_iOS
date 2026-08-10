import SwiftUI

/// ノート種別に応じた遷移先Viewを返す共通コンポーネント
@MainActor
@ViewBuilder
func noteDestinationView(noteType: NoteType, noteID: String) -> some View {
    switch noteType {
    case .free:
        FreeNoteView(noteID: noteID)
    case .practice:
        PracticeNoteView(noteID: noteID)
    case .tournament:
        TournamentNoteView(noteID: noteID)
    }
}
