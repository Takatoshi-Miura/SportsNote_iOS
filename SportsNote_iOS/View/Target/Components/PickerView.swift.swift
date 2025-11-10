import SwiftUI

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
