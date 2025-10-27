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
            let calendar = Calendar.current
            selectedYear = calendar.component(.year, from: today)
            selectedMonth = calendar.component(.month, from: today)
            selectedDate = today

            // ViewModelの年月も更新
            targetViewModel.updateCurrentPeriod(year: selectedYear, month: selectedMonth)

            NotificationCenter.default.post(
                name: NSNotification.Name("MoveToToday"),
                object: nil
            )

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
