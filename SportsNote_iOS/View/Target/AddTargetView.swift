import SwiftUI

/// 目標追加画面
struct AddTargetView: View {
    @Environment(\.dismiss) private var dismiss
    let isYearly: Bool
    let year: Int
    let month: Int
    let onSave: () -> Void
    @State private var title: String = ""
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @ObservedObject var viewModel: TargetViewModel

    init(
        isYearly: Bool,
        year: Int,
        month: Int,
        onSave: @escaping () -> Void,
        viewModel: TargetViewModel
    ) {
        self.isYearly = isYearly
        self.year = year
        self.month = month
        self.onSave = onSave
        self.viewModel = viewModel
        _selectedYear = State(initialValue: year)
        _selectedMonth = State(initialValue: month)
    }

    var body: some View {
        NavigationView {
            Form {
                // タイトル
                Section(header: Text(LocalizedStrings.title)) {
                    TextField(LocalizedStrings.title, text: $title)
                }
                // 期間
                Section(header: Text(LocalizedStrings.period)) {
                    let yearRange = (selectedYear - 5)...(selectedYear + 5)
                    if isYearly {
                        YearPicker(selectedYear: $selectedYear, range: yearRange)
                    } else {
                        HStack {
                            YearPicker(selectedYear: $selectedYear, range: yearRange)
                            MonthPicker(selectedMonth: $selectedMonth)
                        }
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(getNavigationTitle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // キャンセル
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStrings.cancel) {
                        dismiss()
                    }
                }
                // 保存
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.save) {
                        Task {
                            let result = await viewModel.saveTarget(
                                title: title,
                                year: selectedYear,
                                month: selectedMonth,
                                isYearlyTarget: isYearly
                            )
                            switch result {
                            case .success:
                                onSave()
                                dismiss()
                            case .failure(let error):
                                viewModel.showErrorAlert(error)
                            }
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    /// NavigationBarのタイトルを取得
    /// - Returns: タイトル
    private func getNavigationTitle() -> String {
        if isYearly {
            return String(format: LocalizedStrings.addTitle, LocalizedStrings.yearlyTarget)
        } else {
            return String(format: LocalizedStrings.addTitle, LocalizedStrings.monthlyTarget)
        }
    }
}
