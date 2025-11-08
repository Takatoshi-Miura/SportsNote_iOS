import Combine
import SwiftUI

struct TargetView: View {
    @Binding var isMenuOpen: Bool
    @StateObject private var noteViewModel = NoteViewModel()
    @State private var isAddYearlyTargetPresented = false
    @State private var isAddMonthlyTargetPresented = false
    @State private var selectedYear = Date().get(.year)
    @State private var selectedMonth = Date().get(.month)
    @State private var selectedDate: Date?
    @StateObject var viewModel = TargetViewModel()

    var body: some View {
        TabTopView(
            title: LocalizedStrings.target,
            isMenuOpen: $isMenuOpen,
            trailingItem: {
                //「今日」ボタン
                TodayButton(
                    selectedYear: $selectedYear,
                    selectedMonth: $selectedMonth,
                    selectedDate: $selectedDate,
                    noteViewModel: noteViewModel,
                    targetViewModel: viewModel
                )
            },
            content: {
                VStack(spacing: 0) {
                    // カレンダーセクション（固定）
                    CalendarSection(
                        selectedYear: selectedYear,
                        selectedMonth: selectedMonth,
                        selectedDate: $selectedDate,
                        onDateSelected: { date in
                            selectedDate = date
                            // 選択した日付に対応するノートを取得
                            Task { @MainActor in
                                noteViewModel.updateNotesByDate(date)
                            }
                        },
                        targetViewModel: viewModel,
                        noteViewModel: noteViewModel
                    )
                    .padding(.top, 16)

                    // ノートリストセクション（スクロール可能）
                    if let date = selectedDate {
                        ScrollView {
                            NoteListSection(
                                notes: noteViewModel.notes,
                                date: date
                            )
                            .padding(.vertical, 16)
                        }
                    } else {
                        Spacer()
                    }

                    // AdMobバナー広告
                    AdMobBannerView()
                        .frame(height: 50)
                        .background(Color(.systemBackground))
                }
            },
            actionItems: [
                (LocalizedStrings.yearlyTarget, { isAddYearlyTargetPresented = true }),
                (LocalizedStrings.monthlyTarget, { isAddMonthlyTargetPresented = true }),
            ]
        )
        .sheet(isPresented: $isAddYearlyTargetPresented) {
            // 年間目標追加画面
            AddTargetView(
                isYearly: true,
                year: selectedYear,
                month: selectedMonth,
                onSave: {},
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $isAddMonthlyTargetPresented) {
            // 月間目標追加画面
            AddTargetView(
                isYearly: false,
                year: selectedYear,
                month: selectedMonth,
                onSave: {},
                viewModel: viewModel
            )
        }
        .onAppear {
            // 初期時の年月をViewModelにセット
            viewModel.updateCurrentPeriod(year: selectedYear, month: selectedMonth)

            // selectedDateがあれば常にフィルタリング優先（タブ切り替え時も選択状態を保持）
            if let date = selectedDate {
                noteViewModel.updateNotesByDate(date)
            } else if noteViewModel.notes.isEmpty {
                // 日付未選択 & ノートが空の場合のみ全ノート取得
                Task {
                    let result = await noteViewModel.fetchNotesExcludingFree()
                    if case .failure(let error) = result {
                        noteViewModel.currentError = error
                        noteViewModel.showingErrorAlert = true
                    }
                }
            }
        }
        .onChange(of: selectedYear) { newYear in
            viewModel.updateCurrentPeriod(year: newYear, month: selectedMonth)
        }
        .onChange(of: selectedMonth) { newMonth in
            viewModel.updateCurrentPeriod(year: selectedYear, month: newMonth)
        }
    }
}
