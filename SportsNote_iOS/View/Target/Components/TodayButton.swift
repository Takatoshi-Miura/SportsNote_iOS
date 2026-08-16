import SwiftUI

/// 「今日」ボタン
struct TodayButton: View {
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    @Binding var selectedDate: Date?
    @ObservedObject var noteViewModel: NoteViewModel
    @ObservedObject var targetViewModel: TargetViewModel

    var body: some View {
        Button {
            let today = Date()
            selectedYear = today.get(.year)
            selectedMonth = today.get(.month)
            selectedDate = today

            // ViewModelの年月も更新
            targetViewModel.updateCurrentPeriod(year: selectedYear, month: selectedMonth)

            Task { @MainActor in
                noteViewModel.updateNotesByDate(today)
            }
        } label: {
            Text(LocalizedStrings.today)
                .font(.subheadline)
                .foregroundColor(.blue)
        }
    }
}
