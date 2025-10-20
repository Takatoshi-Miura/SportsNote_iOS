import SwiftUI

/// カレンダーセクション
struct CalendarSection: View {
    let selectedYear: Int
    let selectedMonth: Int
    @Binding var selectedDate: Date?
    let onDateSelected: (Date) -> Void
    @State private var currentMonth: Date
    @State private var currentDisplayedYearMonth: (year: Int, month: Int)
    @ObservedObject var targetViewModel: TargetViewModel
    @ObservedObject var noteViewModel: NoteViewModel

    init(
        selectedYear: Int, selectedMonth: Int, selectedDate: Binding<Date?>, onDateSelected: @escaping (Date) -> Void,
        targetViewModel: TargetViewModel,
        noteViewModel: NoteViewModel
    ) {
        self.selectedYear = selectedYear
        self.selectedMonth = selectedMonth
        self._selectedDate = selectedDate
        self.onDateSelected = onDateSelected
        self._currentMonth = State(
            initialValue: {
                let calendar = Calendar.current
                return calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)) ?? Date()
            }())
        self._currentDisplayedYearMonth = State(initialValue: (selectedYear, selectedMonth))
        self.targetViewModel = targetViewModel
        self.noteViewModel = noteViewModel
    }

    var body: some View {
        VStack {
            // 目標表示 - 表示中の年月の目標を使用
            TargetSummaryView(
                yearlyTargets: targetViewModel.yearlyTargets,
                monthlyTargets: targetViewModel.monthlyTargets
            )
            // カレンダー表示
            CalendarView(
                selectedDate: $selectedDate,
                initialDate: currentMonth,
                onDateSelected: onDateSelected,
                onMonthChanged: { newDate in
                    let calendar = Calendar.current
                    let year = calendar.component(.year, from: newDate)
                    let month = calendar.component(.month, from: newDate)

                    // 年月が変わったら表示される月と目標を更新
                    if year != currentDisplayedYearMonth.year || month != currentDisplayedYearMonth.month {
                        currentDisplayedYearMonth = (year, month)
                        currentMonth = newDate

                        // 目標データを更新
                        targetViewModel.updateCurrentPeriod(year: year, month: month)
                    }
                },
                noteViewModel: noteViewModel
            )
            .padding(.horizontal)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .onAppear {
            // 初期表示時にも目標を取得
            targetViewModel.updateCurrentPeriod(
                year: currentDisplayedYearMonth.year,
                month: currentDisplayedYearMonth.month
            )
        }
    }
}
