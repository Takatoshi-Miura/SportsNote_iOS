import SwiftUI
import RealmSwift

struct AddTargetView: View {
    @Environment(\.dismiss) private var dismiss
    
    let isYearly: Bool
    let year: Int
    let month: Int
    let onSave: () -> Void
    
    @State private var title: String = ""
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    
    init(isYearly: Bool, year: Int, month: Int, onSave: @escaping () -> Void) {
        self.isYearly = isYearly
        self.year = year
        self.month = month
        self.onSave = onSave
        
        // Initialize state properties
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
                    if isYearly {
                        // Year picker
                        Picker("Year", selection: $selectedYear) {
                            ForEach((selectedYear-5)...(selectedYear+5), id: \.self) { year in
                                Text("\(year)")
                                    .tag(year)
                            }
                        }
                        .pickerStyle(.wheel)
                    } else {
                        HStack {
                            // Year picker
                            Picker("Year", selection: $selectedYear) {
                                ForEach((selectedYear-5)...(selectedYear+5), id: \.self) { year in
                                    Text("\(year)")
                                        .tag(year)
                                }
                            }
                            .pickerStyle(.wheel)
                            
                            // Month picker
                            Picker("Month", selection: $selectedMonth) {
                                ForEach(1...12, id: \.self) { month in
                                    Text("\(month)")
                                        .tag(month)
                                }
                            }
                            .pickerStyle(.wheel)
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
                        saveTarget()
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
    
    /// 目標を保存
    private func saveTarget() {
        let target = Target(
            title: title,
            year: selectedYear,
            month: selectedMonth,
            isYearlyTarget: isYearly
        )
        
        RealmManager.shared.saveItem(target)
        onSave()
        dismiss()
    }
}

struct EditTargetView: View {
    @Environment(\.dismiss) private var dismiss
    let target: Target
    let onSave: () -> Void
    
    @State private var title: String
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    
    init(target: Target, onSave: @escaping () -> Void) {
        self.target = target
        self.onSave = onSave
        
        _title = State(initialValue: target.title)
        _selectedYear = State(initialValue: target.year)
        _selectedMonth = State(initialValue: target.month)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("Target", text: $title)
                }
                
                Section(header: Text("Period")) {
                    if target.isYearlyTarget {
                        Picker("Year", selection: $selectedYear) {
                            ForEach((selectedYear-5)...(selectedYear+5), id: \.self) { year in
                                Text("\(year)")
                                    .tag(year)
                            }
                        }
                        .pickerStyle(.wheel)
                    } else {
                        HStack {
                            // Year picker
                            Picker("Year", selection: $selectedYear) {
                                ForEach((selectedYear-5)...(selectedYear+5), id: \.self) { year in
                                    Text("\(year)")
                                        .tag(year)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            
                            // Month picker
                            Picker("Month", selection: $selectedMonth) {
                                ForEach(1...12, id: \.self) { month in
                                    Text("\(month)")
                                        .tag(month)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80)
                        }
                    }
                }
            }
            .navigationTitle("Edit Target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStrings.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.save) {
                        updateTarget()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func updateTarget() {
        do {
            let realm = try Realm()
            if let targetToUpdate = realm.object(ofType: Target.self, forPrimaryKey: target.targetID) {
                try realm.write {
                    targetToUpdate.title = title
                    targetToUpdate.year = selectedYear
                    targetToUpdate.month = selectedMonth
                    targetToUpdate.updated_at = Date()
                }
                onSave()
                dismiss()
            }
        } catch {
            print("Error updating target: \(error)")
        }
    }
}
