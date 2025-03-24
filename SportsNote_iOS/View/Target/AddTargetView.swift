import SwiftUI
import RealmSwift

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
                        viewModel.saveTarget(
                            title: title,
                            year: year,
                            month: month,
                            isYearlyTarget: isYearly
                        )
                        dismiss()
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

/// 年を選択するPicker
struct YearPicker: View {
    @Binding var selectedYear: Int
    var range: ClosedRange<Int>

    var body: some View {
        Picker("Year", selection: $selectedYear) {
            ForEach(range, id: \.self) { year in
                Text("\(year)")
                    .tag(year)
            }
        }
        .pickerStyle(.wheel)
    }
}

/// 月を選択するPicker
struct MonthPicker: View {
    @Binding var selectedMonth: Int

    var body: some View {
        Picker("Month", selection: $selectedMonth) {
            ForEach(1...12, id: \.self) { month in
                Text("\(month)")
                    .tag(month)
            }
        }
        .pickerStyle(.wheel)
    }
}
