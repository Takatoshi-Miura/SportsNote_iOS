import SwiftUI

/// カレンダー表示
struct CalendarView: View {
    @Binding var selectedDate: Date?
    let onDateSelected: (Date) -> Void
    let onMonthChanged: (Date) -> Void

    @State private var currentMonth: Date
    @GestureState private var dragOffset: CGFloat = 0
    @State private var slideDirection: CGFloat = 0  // スライド方向（-1: 左, 1: 右）
    @State private var isAnimating: Bool = false  // アニメーション中かどうか
    @ObservedObject var noteViewModel: NoteViewModel  // 親から渡されるNoteViewModel
    @State private var datesWithNotes: Set<Date> = []  // ノートがある日付のセット

    // 曜日の配列（日曜始まり）
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    init(
        selectedDate: Binding<Date?>, initialDate: Date = Date(), onDateSelected: @escaping (Date) -> Void,
        onMonthChanged: @escaping (Date) -> Void,
        noteViewModel: NoteViewModel
    ) {
        self._selectedDate = selectedDate
        self.onDateSelected = onDateSelected
        self.onMonthChanged = onMonthChanged
        self._currentMonth = State(initialValue: initialDate)
        self.noteViewModel = noteViewModel
    }

    var body: some View {
        VStack {
            // カレンダーヘッダー
            HStack {
                Button(action: {
                    changeMonth(isPrevious: true)
                }) {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                let monthYear = currentMonth.formatted(.dateTime.month().year())
                Text(monthYear)
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: {
                    changeMonth(isPrevious: false)
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 5)

            // カレンダーコンテンツ（スワイプ可能）
            ZStack {
                calendarContent
                    .offset(x: isAnimating ? -slideDirection * UIScreen.main.bounds.width : 0)
                    .offset(x: dragOffset)
                    .animation(isAnimating ? .easeInOut(duration: 0.3) : nil, value: isAnimating)

                if isAnimating {
                    // 新しい月のカレンダーを表示（スライド方向に基づいて配置）
                    calendarContent
                        .offset(x: slideDirection * UIScreen.main.bounds.width - (slideDirection * dragOffset))
                }
            }
            .clipped()
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.width > threshold {
                            // 右スワイプ - 前月
                            changeMonth(isPrevious: true)
                        } else if value.translation.width < -threshold {
                            // 左スワイプ - 翌月
                            changeMonth(isPrevious: false)
                        }
                    }
            )
        }
        .padding(.bottom)
        .onAppear {
            // 初期表示時にもコールバックを呼び出し
            onMonthChanged(currentMonth)

            // 当月のノートがある日付を取得
            updateDatesWithNotes()

            // 「今日」ボタンの通知を受け取る
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("MoveToToday"),
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    // 現在の月が今日の月と異なる場合は月を切り替える
                    let today = Date()
                    let calendar = Calendar.current
                    let currentMonthValue = calendar.component(.month, from: self.currentMonth)
                    let currentYearValue = calendar.component(.year, from: self.currentMonth)
                    let todayMonthValue = calendar.component(.month, from: today)
                    let todayYearValue = calendar.component(.year, from: today)

                    if currentMonthValue != todayMonthValue || currentYearValue != todayYearValue {
                        // アニメーションなしで今日の月に直接移動
                        self.currentMonth =
                            calendar.date(from: DateComponents(year: todayYearValue, month: todayMonthValue, day: 1))
                            ?? today
                        self.onMonthChanged(self.currentMonth)

                        // ノートの更新
                        self.updateDatesWithNotes()
                    }
                }
            }
        }
        .onDisappear {
            // 通知の登録解除
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("MoveToToday"),
                object: nil
            )
        }
    }

    // 月の切り替えを行う関数
    private func changeMonth(isPrevious: Bool) {
        isAnimating = true
        slideDirection = isPrevious ? -1 : 1  // 前月なら左から右へ、次月なら右から左へ

        // アニメーション完了後の処理
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 月を実際に変更
            withAnimation(nil) {
                let newMonth =
                    Calendar.current.date(
                        byAdding: .month,
                        value: isPrevious ? -1 : 1,
                        to: currentMonth
                    ) ?? currentMonth

                currentMonth = newMonth
                onMonthChanged(currentMonth)

                // アニメーションをリセット
                isAnimating = false
                slideDirection = 0

                // 新しい月のノートがある日付を取得
                updateDatesWithNotes()
            }
        }
    }

    // 表示中の月のノートがある日付を更新
    private func updateDatesWithNotes() {
        datesWithNotes.removeAll()

        // 表示している月の初日と末日を取得
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentMonth)
        let month = calendar.component(.month, from: currentMonth)

        if let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
            let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate)
        {

            // 月の初日から末日までの間の全ての日のノートを確認
            var date = startDate
            while date <= endDate {
                let notesForDate = noteViewModel.filterNotesByDate(date)
                if !notesForDate.isEmpty {
                    // この日にノートがある場合、セットに追加
                    datesWithNotes.insert(calendar.startOfDay(for: date))
                }
                date = calendar.date(byAdding: .day, value: 1, to: date)!
            }
        }
    }

    // カレンダーコンテンツ部分を分離
    private var calendarContent: some View {
        VStack {
            // 曜日ヘッダー
            HStack {
                ForEach(0..<7, id: \.self) { index in
                    Text(weekdays[index])
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(colorForWeekdayHeader(index))
                        .frame(maxWidth: .infinity)
                }
            }

            // 日付グリッド
            let days = extractDates()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(days, id: \.self) { date in
                    VStack {
                        if date.get(.month) == currentMonth.get(.month) {
                            Text("\(date.get(.day))")
                                .fontWeight(isToday(date) ? .bold : .regular)
                                .foregroundColor(foregroundColorFor(date))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(backgroundFor(date))
                        } else {
                            Text("\(date.get(.day))")
                                .foregroundColor(.gray.opacity(0.5))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(height: 40)
                    .onTapGesture {
                        if date.get(.month) == currentMonth.get(.month) {
                            selectedDate = date
                            onDateSelected(date)
                        }
                    }
                }
            }
        }
    }

    // 曜日ヘッダーの色を返す関数（0=Sunday, 6=Saturday）
    private func colorForWeekdayHeader(_ weekday: Int) -> Color {
        switch weekday {
        case 0:  // Sunday
            return .red
        case 6:  // Saturday
            return .blue
        default:
            return .primary
        }
    }

    // 曜日に応じた色を返す関数（日付セルの色）
    private func colorForWeekday(_ weekday: Int) -> Color {
        switch weekday {
        case 0:  // Sunday
            return .red
        case 6:  // Saturday
            return .blue
        default:
            return .primary
        }
    }

    private func isToday(_ date: Date) -> Bool {
        return date.isToday
    }

    private func isSelectedDate(_ date: Date) -> Bool {
        guard let selectedDate = selectedDate else { return false }
        return date.isSameDay(as: selectedDate)
    }

    private func hasNoteForDate(_ date: Date) -> Bool {
        let startOfDay = date.startOfDay
        return datesWithNotes.contains(startOfDay)
    }

    private func foregroundColorFor(_ date: Date) -> Color {
        if isSelectedDate(date) {
            return .white
        } else if JapaneseHolidayChecker.isJapaneseHoliday(date) {
            // 日本の祝日の場合は赤色で表示
            return .red
        } else if date.get(.weekday) == 1 {  // 日曜日は1
            return .red
        } else if date.get(.weekday) == 7 {  // 土曜日は7
            return .blue
        } else {
            return .primary
        }
    }

    @ViewBuilder
    private func backgroundFor(_ date: Date) -> some View {
        // 選択中の日付 > 今日 > ノートがある日付 の優先順位で背景を決定
        if isSelectedDate(date) {
            Circle().fill(Color.blue)
        } else if isToday(date) {
            Circle().stroke(Color.blue, lineWidth: 1)
        } else if hasNoteForDate(date) {
            // ノートがある日付は緑色の背景
            Circle().fill(Color.green.opacity(0.3))
        } else {
            EmptyView()
        }
    }

    private func extractDates() -> [Date] {
        let calendar = Calendar.current
        let startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = calendar.component(.weekday, from: startDate)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!.count

        var days: [Date] = []

        // Add days from previous month
        let daysFromPreviousMonth = firstWeekday - 1
        if daysFromPreviousMonth > 0 {
            for day in (1...daysFromPreviousMonth).reversed() {
                if let date = calendar.date(byAdding: .day, value: -day, to: startDate) {
                    days.append(date)
                }
            }
        }

        // Add days from current month
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: startDate) {
                days.append(date)
            }
        }

        // Add days from next month to complete the grid
        let remainingDays = 7 - (days.count % 7)
        if remainingDays < 7 {
            for day in 0..<remainingDays {
                if let date = calendar.date(byAdding: .day, value: daysInMonth + day, to: startDate) {
                    days.append(date)
                }
            }
        }

        return days
    }
}
