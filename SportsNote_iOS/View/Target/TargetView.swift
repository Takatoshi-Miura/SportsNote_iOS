import SwiftUI

struct TargetView: View {
    @Binding var isMenuOpen: Bool
    @StateObject private var viewModel = TargetViewModel()
    @StateObject private var noteViewModel = NoteViewModel()
    @State private var isAddYearlyTargetPresented = false
    @State private var isAddMonthlyTargetPresented = false
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedDate: Date?
    
    var body: some View {
        TabTopView(
            title: LocalizedStrings.target,
            isMenuOpen: $isMenuOpen,
            trailingItem: {
            },
            content: {
                VStack(spacing: 0) {
                    // 年間目標と月間目標のセクション
                    TargetDisplaySection(
                        yearlyTargets: viewModel.yearlyTargets,
                        monthlyTargets: viewModel.monthlyTargets,
                        selectedYear: selectedYear,
                        selectedMonth: selectedMonth
                    )
                    
                    // カレンダーセクション
                    CalendarSection(
                        selectedYear: selectedYear,
                        selectedMonth: selectedMonth,
                        selectedDate: $selectedDate,
                        onDateSelected: { date in
                            selectedDate = date
                            noteViewModel.notes = noteViewModel.filterNotesByDate(date)
                        }
                    )
                    
                    // ノートリストセクション
                    if let date = selectedDate {
                        NoteListSection(
                            notes: noteViewModel.notes,
                            date: date
                        )
                        .padding(.top, 16)
                    }
                    
                    Spacer()
                }
            },
            actionItems: [
                (LocalizedStrings.yearlyTarget, { isAddYearlyTargetPresented = true }),
                (LocalizedStrings.monthlyTarget, { isAddMonthlyTargetPresented = true })
            ]
        )
        .sheet(isPresented: $isAddYearlyTargetPresented) {
            AddTargetView(
                isYearly: true,
                year: selectedYear,
                month: selectedMonth,
                onSave: {
                    viewModel.fetchTargets(year: selectedYear, month: selectedMonth)
                }
            )
        }
        .sheet(isPresented: $isAddMonthlyTargetPresented) {
            AddTargetView(
                isYearly: false,
                year: selectedYear,
                month: selectedMonth,
                onSave: {
                    viewModel.fetchTargets(year: selectedYear, month: selectedMonth)
                }
            )
        }
        .onAppear {
            viewModel.fetchTargets(year: selectedYear, month: selectedMonth)
            noteViewModel.fetchNotes()
        }
    }
    
    private func monthName(month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        
        var dateComponents = DateComponents()
        dateComponents.month = month
        
        if let date = Calendar.current.date(from: dateComponents) {
            return dateFormatter.string(from: date)
        }
        
        return ""
    }
}

// 目標表示セクション
struct TargetDisplaySection: View {
    let yearlyTargets: [Target]
    let monthlyTargets: [Target]
    let selectedYear: Int
    let selectedMonth: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 年間目標セクション
            if !yearlyTargets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(selectedYear) \(LocalizedStrings.yearlyTarget)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(yearlyTargets, id: \.targetID) { target in
                        TargetRow(target: target, viewModel: TargetViewModel())
                    }
                }
                .padding(.top, 8)
            }
            
            // 月間目標セクション
            if !monthlyTargets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(selectedYear)/\(selectedMonth) \(LocalizedStrings.monthlyTarget)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(monthlyTargets, id: \.targetID) { target in
                        TargetRow(target: target, viewModel: TargetViewModel())
                    }
                }
                .padding(.top, 8)
            }
            
            // 目標が空の場合
            if yearlyTargets.isEmpty && monthlyTargets.isEmpty {
                VStack(spacing: 16) {
                    Text("No targets set for this period")
                        .font(.title3)
                        .foregroundColor(.gray)                    
                    Text("Tap + to add new targets")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }
}

// カレンダーセクション
struct CalendarSection: View {
    let selectedYear: Int
    let selectedMonth: Int
    @Binding var selectedDate: Date?
    let onDateSelected: (Date) -> Void
    
    @State private var currentMonth: Date = Date()
    
    var body: some View {
        VStack {
            Text("Calendar")
                .font(.headline)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            CalendarView(
                selectedDate: $selectedDate,
                onDateSelected: onDateSelected
            )
            .padding(.horizontal)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// シンプルなカレンダービュー
struct CalendarView: View {
    @Binding var selectedDate: Date?
    let onDateSelected: (Date) -> Void
    
    @State private var currentMonth = Date()
    
    var body: some View {
        VStack {
            // カレンダーヘッダー
            HStack {
                Button(action: {
                    withAnimation {
                        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
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
                        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            
            // 曜日ヘッダー
            HStack {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.bold)
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
        .padding(.bottom)
    }
    
    // 複雑な式を小さな関数に分解
    private func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    private func isSelectedDate(_ date: Date) -> Bool {
        guard let selectedDate = selectedDate else { return false }
        return Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    private func foregroundColorFor(_ date: Date) -> Color {
        if isSelectedDate(date) {
            return .white
        } else if date.get(.weekday) == 1 {
            return .red
        } else if date.get(.weekday) == 7 {
            return .blue
        } else {
            return .primary
        }
    }
    
    @ViewBuilder
    private func backgroundFor(_ date: Date) -> some View {
        if isSelectedDate(date) {
            Circle().fill(Color.blue)
        } else if isToday(date) {
            Circle().stroke(Color.blue, lineWidth: 1)
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

// ノートリストセクション
struct NoteListSection: View {
    let notes: [Note]
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Notes (\(notes.count))")
                .font(.headline)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if notes.isEmpty {
                Text("No notes for this day")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(notes, id: \.noteID) { note in
                            NavigationLink(destination: noteDestination(for: note)) {
                                NoteRow(note: note)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func noteDestination(for note: Note) -> some View {
        switch NoteType(rawValue: note.noteType) {
        case .free:
            Text("Free Note Detail") // Replace with actual free note view
        case .practice:
            Text("Practice Note Detail") // Replace with actual practice note view
        case .tournament:
            Text("Tournament Note Detail") // Replace with actual tournament note view
        case .none:
            Text("Unknown Note")
        }
    }
}

// 既存のTargetRow構造体はそのまま維持
struct TargetRow: View {
    let target: Target
    let viewModel: TargetViewModel
    
    @State private var isEditing = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(target.title)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                HStack {
                    Button(action: {
                        isEditing = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .alert(isPresented: $showDeleteConfirmation) {
                        Alert(
                            title: Text("Delete Target"),
                            message: Text("Are you sure you want to delete this target?"),
                            primaryButton: .destructive(Text("Delete")) {
                                viewModel.deleteTarget(id: target.targetID)
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
        .padding(.vertical, 4)
        .sheet(isPresented: $isEditing) {
            EditTargetView(target: target) {
                // 編集後にデータを更新
                viewModel.fetchTargets(year: target.year, month: target.month)
            }
        }
    }
}

// Date拡張
extension Date {
    func get(_ component: Calendar.Component) -> Int {
        return Calendar.current.component(component, from: self)
    }
}
