import SwiftUI
import UIKit

/// カレンダー表示（UICalendarViewをラップし、月移動・週の可変行数レイアウトはOS標準に委ねる）
struct CalendarView: UIViewRepresentable {
    @Binding var selectedDate: Date?
    let onDateSelected: (Date) -> Void
    let onMonthChanged: (Date) -> Void
    @ObservedObject var noteViewModel: NoteViewModel

    private let initialDate: Date

    init(
        selectedDate: Binding<Date?>, initialDate: Date = Date(), onDateSelected: @escaping (Date) -> Void,
        onMonthChanged: @escaping (Date) -> Void,
        noteViewModel: NoteViewModel
    ) {
        self._selectedDate = selectedDate
        self.initialDate = initialDate
        self.onDateSelected = onDateSelected
        self.onMonthChanged = onMonthChanged
        self.noteViewModel = noteViewModel
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = Calendar.current
        calendarView.locale = Locale.current
        calendarView.fontDesign = .default
        calendarView.delegate = context.coordinator

        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        selection.setSelected(DateComponents(from: selectedDate ?? initialDate), animated: false)
        calendarView.selectionBehavior = selection
        calendarView.setVisibleDateComponents(DateComponents(from: initialDate), animated: false)

        // 初期表示月のノート日付を反映してから装飾を読み込む（decorationForは生成直後に呼ばれるため、
        // ここでdatesWithPractice/datesWithTournamentを埋めておかないと初期表示時に装飾が出ない）
        context.coordinator.reloadVisibleDecorations(in: calendarView)

        // 初期表示月・選択状態をコールバックへ反映
        onMonthChanged(selectedDate ?? initialDate)

        return calendarView
    }

    // UICalendarViewは明示しない限り自身のintrinsicContentSizeいっぱいに広がろうとし、
    // SwiftUI側のVStackレイアウトを圧迫する（横のはみ出し・縦の伸びすぎ）ため、
    // 横幅はSwiftUIからの提案幅に合わせ、縦は月の週数に応じた実際のコンテンツ高さに従わせる
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UICalendarView, context: Context) -> CGSize? {
        let width = proposal.width ?? UIView.layoutFittingCompressedSize.width
        let targetSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        return uiView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        // bodyの再評価毎に生成される最新のCalendarView（最新のonDateSelected等のクロージャを保持）を反映する
        context.coordinator.parent = self

        // 外部（「今日」ボタン等）からselectedDateが変更された場合のみ、表示月・選択日をUIKit側へ同期する
        guard let selectedDate, selectedDate != context.coordinator.lastKnownSelectedDate else { return }

        context.coordinator.lastKnownSelectedDate = selectedDate
        let components = DateComponents(from: selectedDate)
        (uiView.selectionBehavior as? UICalendarSelectionSingleDate)?.setSelected(components, animated: true)
        uiView.setVisibleDateComponents(components, animated: true)
        context.coordinator.reloadVisibleDecorations(in: uiView)
    }

    final class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: CalendarView
        var lastKnownSelectedDate: Date?
        // DateComponentsはcalendar等の内部プロパティの違いでHashable比較が一致しないことがあるため、
        // year/month/dayを整数キー(例: 20260816)に変換して確実に一致させる
        private var practiceDateKeys: Set<Int> = []
        private var tournamentDateKeys: Set<Int> = []

        init(_ parent: CalendarView) {
            self.parent = parent
            self.lastKnownSelectedDate = parent.selectedDate
        }

        // 選択中の日付が変更された時に呼ばれる
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents, let date = Calendar.current.date(from: dateComponents) else { return }
            lastKnownSelectedDate = date
            parent.selectedDate = date
            parent.onDateSelected(date)
        }

        // 表示中の月が変更された時に呼ばれる（UICalendarViewの標準スワイプ操作による月移動を含む）
        func calendarView(
            _ calendarView: UICalendarView, didChangeVisibleDateComponentsFrom previousDateComponents: DateComponents
        ) {
            guard let visibleDate = Calendar.current.date(from: calendarView.visibleDateComponents) else { return }
            updateNoteDates(around: visibleDate)
            parent.onMonthChanged(visibleDate)
            reloadVisibleDecorations(in: calendarView)
        }

        // 日付ごとの装飾（練習ノート=緑ドット、大会ノート=赤ドット）を返す
        func calendarView(
            _ calendarView: UICalendarView, decorationFor dateComponents: DateComponents
        ) -> UICalendarView.Decoration? {
            guard let key = dateComponents.dateKey else { return nil }
            if tournamentDateKeys.contains(key) {
                return .default(color: .systemRed, size: .medium)
            } else if practiceDateKeys.contains(key) {
                return .default(color: .systemGreen, size: .medium)
            }
            return nil
        }

        func reloadVisibleDecorations(in calendarView: UICalendarView) {
            guard let visibleDate = Calendar.current.date(from: calendarView.visibleDateComponents) else { return }
            let reloadTargets = updateNoteDates(around: visibleDate)
            calendarView.reloadDecorations(forDateComponents: reloadTargets, animated: false)
        }

        // 表示中の月・前月・翌月分のノートがある日付を再計算し、装飾再読込対象のDateComponentsを返す
        @discardableResult
        private func updateNoteDates(around month: Date) -> [DateComponents] {
            practiceDateKeys.removeAll()
            tournamentDateKeys.removeAll()

            let calendar = Calendar.current
            var reloadTargets: [DateComponents] = []
            for offset in -1...1 {
                guard let targetMonth = calendar.date(byAdding: .month, value: offset, to: month) else { continue }
                reloadTargets.append(contentsOf: insertNoteDates(for: targetMonth))
            }
            return reloadTargets
        }

        private func insertNoteDates(for month: Date) -> [DateComponents] {
            let calendar = Calendar.current
            guard let range = calendar.range(of: .day, in: .month, for: month),
                let startDate = calendar.date(
                    from: calendar.dateComponents([.year, .month], from: month))
            else { return [] }

            var components: [DateComponents] = []
            for day in range {
                guard let date = calendar.date(byAdding: .day, value: day - 1, to: startDate) else { continue }
                let notesForDate = parent.noteViewModel.filterNotesByDate(date)
                guard !notesForDate.isEmpty else { continue }

                let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                guard let key = dateComponents.dateKey else { continue }
                components.append(dateComponents)

                for note in notesForDate {
                    switch NoteType(rawValue: note.noteType) {
                    case .practice:
                        practiceDateKeys.insert(key)
                    case .tournament:
                        tournamentDateKeys.insert(key)
                    default:
                        break
                    }
                }
            }
            return components
        }
    }
}

extension DateComponents {
    fileprivate init(from date: Date) {
        self = Calendar.current.dateComponents([.year, .month, .day], from: date)
    }

    /// year/month/dayを1つの整数に変換する（DateComponents自体のHashable比較はcalendar等の
    /// 内部プロパティの違いで一致しないことがあるため、確実に比較できるキーとして使う）
    fileprivate var dateKey: Int? {
        guard let year, let month, let day else { return nil }
        return year * 10000 + month * 100 + day
    }
}
