import SwiftUI

struct TargetView: View {
    @Binding var isMenuOpen: Bool
    @StateObject private var viewModel = TargetViewModel()
    @State private var isAddYearlyTargetPresented = false
    @State private var isAddMonthlyTargetPresented = false
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    
    var body: some View {
        TabTopView(
            title: LocalizedStrings.target,
            isMenuOpen: $isMenuOpen,
            trailingItem: {
                Menu {
                    Picker("Year", selection: $selectedYear) {
                        ForEach((selectedYear-5)...(selectedYear+5), id: \.self) { year in
                            Text("\(year)")
                                .tag(year)
                        }
                    }
                    .onChange(of: selectedYear) { _ in
                        viewModel.fetchTargets(year: selectedYear, month: selectedMonth)
                    }
                    
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(monthName(month: month))
                                .tag(month)
                        }
                    }
                    .onChange(of: selectedMonth) { _ in
                        viewModel.fetchTargets(year: selectedYear, month: selectedMonth)
                    }
                } label: {
                    HStack {
                        Text("\(selectedYear)/\(selectedMonth)")
                        Image(systemName: "calendar")
                    }
                }
            },
            content: {
                VStack(spacing: 0) {
                    // Title for yearly targets
                    if !viewModel.yearlyTargets.isEmpty {
                        HStack {
                            Text("\(selectedYear) \(LocalizedStrings.yearlyTarget)")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top, 16)
                            Spacer()
                        }
                    }
                    
                    // Yearly targets list
                    ForEach(viewModel.yearlyTargets, id: \.targetID) { target in
                        TargetRow(target: target, viewModel: viewModel)
                    }
                    
                    // Title for monthly targets
                    if !viewModel.monthlyTargets.isEmpty {
                        HStack {
                            Text("\(selectedYear)/\(selectedMonth) \(LocalizedStrings.monthlyTarget)")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top, 16)
                            Spacer()
                        }
                    }
                    
                    // Monthly targets list
                    ForEach(viewModel.monthlyTargets, id: \.targetID) { target in
                        TargetRow(target: target, viewModel: viewModel)
                    }
                    
                    // Empty state
                    if viewModel.yearlyTargets.isEmpty && viewModel.monthlyTargets.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            
                            Image(systemName: "target")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No targets set for this period")
                                .font(.title3)
                                .foregroundColor(.gray)
                            
                            Text("Tap + to add new targets")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
