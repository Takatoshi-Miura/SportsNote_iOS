import SwiftUI

/// カレンダー表示
struct CalendarView: View {
    @Binding var selectedDate: Date?
    let onDateSelected: (Date) -> Void
    let onMonthChanged: (Date) -> Void

    @State private var currentMonth: Date
    // TabView(.page)による無限ページングのための3ページ・スライディングウィンドウ
    // 0: 前月, 1: 当月(currentMonth), 2: 翌月を常に配置し、選択が変わるたびに
    // currentMonthを更新してselectionを1へ戻すことで、実質無限にスワイプできるようにする
    @State private var selection: Int = 1
    @ObservedObject var noteViewModel: NoteViewModel  // 親から渡されるNoteViewModel
    @State private var datesWithPractice: Set<Date> = []  // 練習ノートがある日付のセット
    @State private var datesWithTournament: Set<Date> = []  // 大会ノートがある日付のセット

    // 曜日の配列（日曜始まり）
    private let weekdays = [
        LocalizedStrings.weekdaySun,
        LocalizedStrings.weekdayMon,
        LocalizedStrings.weekdayTue,
        LocalizedStrings.weekdayWed,
        LocalizedStrings.weekdayThu,
        LocalizedStrings.weekdayFri,
        LocalizedStrings.weekdaySat,
    ]

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
                    withAnimation {
                        selection = 0
                    }
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
                    withAnimation {
                        selection = 2
                    }
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 5)

            // カレンダーコンテンツ（前月・当月・翌月の3ページをTabView(.page)でスワイプ可能に）
            TabView(selection: $selection) {
                calendarContent(for: adjacentMonth(offset: -1))
                    .tag(0)
                calendarContent(for: currentMonth)
                    .tag(1)
                calendarContent(for: adjacentMonth(offset: 1))
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: calendarContentHeight)
            .onChange(of: selection) { newValue in
                // 前月(0)・翌月(2)へページが送られたら中心月を更新し、
                // アニメーションなしでウィンドウを1へ戻して次のスワイプに備える
                guard newValue != 1 else { return }

                let isPrevious = newValue == 0
                currentMonth = adjacentMonth(offset: isPrevious ? -1 : 1)
                onMonthChanged(currentMonth)
                updateDatesWithNotes()

                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    selection = 1
                }
            }
        }
        .padding(.bottom)
        .onAppear {
            // 初期表示時にもコールバックを呼び出し
            onMonthChanged(currentMonth)

            // 当月のノートがある日付を取得
            updateDatesWithNotes()
        }
        // 「今日」ボタンの通知を受け取る（Combineの.onReceiveはViewの生存期間に紐づいて
        // 自動的に購読解除されるため、ブロック型NotificationCenter APIのような
        // 手動でのトークン管理・解除（addObserver/removeObserver）が不要になる）
        .onReceive(NotificationCenter.default.publisher(for: .moveToToday)) { _ in
            // 現在の月が今日の月と異なる場合は月を切り替える
            let today = Date()
            let calendar = Calendar.current
            let currentMonthValue = currentMonth.get(.month)
            let currentYearValue = currentMonth.get(.year)
            let todayMonthValue = today.get(.month)
            let todayYearValue = today.get(.year)

            if currentMonthValue != todayMonthValue || currentYearValue != todayYearValue {
                // アニメーションなしで今日の月に直接移動
                currentMonth =
                    calendar.date(from: DateComponents(year: todayYearValue, month: todayMonthValue, day: 1))
                    ?? today
                onMonthChanged(currentMonth)

                // ノートの更新
                updateDatesWithNotes()
            }
        }
    }

    // currentMonthからoffsetヶ月分ずらした月を返す（前月/翌月ページの算出に使用）
    private func adjacentMonth(offset: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: offset, to: currentMonth) ?? currentMonth
    }

    // 表示中の月・前月・翌月（TabViewの3ページ分）のノートがある日付を更新
    private func updateDatesWithNotes() {
        datesWithPractice.removeAll()
        datesWithTournament.removeAll()

        for month in [adjacentMonth(offset: -1), currentMonth, adjacentMonth(offset: 1)] {
            insertNoteDates(for: month)
        }
    }

    // 指定した月の初日から末日までのノート日付をdatesWithPractice/datesWithTournamentに追加
    private func insertNoteDates(for month: Date) {
        let calendar = Calendar.current
        let year = month.get(.year)
        let monthValue = month.get(.month)

        guard let startDate = calendar.date(from: DateComponents(year: year, month: monthValue, day: 1)),
            let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate)
        else { return }

        // 月の初日から末日までの間の全ての日のノートを確認
        var date = startDate
        while date <= endDate {
            let notesForDate = noteViewModel.filterNotesByDate(date)
            let startOfDay = calendar.startOfDay(for: date)
            for note in notesForDate {
                switch NoteType(rawValue: note.noteType) {
                case .practice:
                    datesWithPractice.insert(startOfDay)
                case .tournament:
                    datesWithTournament.insert(startOfDay)
                default:
                    break
                }
            }
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
    }

    // カレンダーコンテンツ部分を分離（表示対象の月を明示的に受け取る）
    private func calendarContent(for month: Date) -> some View {
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
            let days = extractDates(for: month)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(days, id: \.self) { date in
                    VStack {
                        if date.get(.month) == month.get(.month) {
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
                    .frame(height: calendarWeekRowHeight)
                    .onTapGesture {
                        if date.get(.month) == month.get(.month) {
                            selectedDate = date
                            onDateSelected(date)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: calendarContentHeight)
    }

    // TabView(.page)は各ページの高さが揃っている必要があるため、
    // 月によって変動する週数（5〜6週）を吸収できるよう常に6週分の高さで固定する
    private let calendarWeekRowHeight: CGFloat = 40
    private let calendarWeekdayHeaderHeight: CGFloat = 20
    private var calendarContentHeight: CGFloat {
        calendarWeekdayHeaderHeight + calendarWeekRowHeight * 6
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

    private func isToday(_ date: Date) -> Bool {
        return date.isToday
    }

    private func isSelectedDate(_ date: Date) -> Bool {
        guard let selectedDate = selectedDate else { return false }
        return date.isSameDay(as: selectedDate)
    }

    private func hasPracticeForDate(_ date: Date) -> Bool {
        return datesWithPractice.contains(date.startOfDay)
    }

    private func hasTournamentForDate(_ date: Date) -> Bool {
        return datesWithTournament.contains(date.startOfDay)
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
        // ノート種別: 大会（赤）> 練習（緑）
        if isSelectedDate(date) {
            Circle().fill(Color.blue)
        } else if isToday(date) {
            Circle().stroke(Color.blue, lineWidth: 1)
        } else if hasTournamentForDate(date) {
            Circle().fill(Color.red.opacity(0.3))
        } else if hasPracticeForDate(date) {
            Circle().fill(Color.green.opacity(0.3))
        } else {
            EmptyView()
        }
    }

    private func extractDates(for month: Date) -> [Date] {
        let calendar = Calendar.current
        let startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let firstWeekday = calendar.component(.weekday, from: startDate)
        let daysInMonth = calendar.range(of: .day, in: .month, for: month)!.count

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
