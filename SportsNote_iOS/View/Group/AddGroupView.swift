import UIKit
import SwiftUI

struct AddGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var selectedColor: GroupColor = .red
    @ObservedObject var viewModel: GroupViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizedStrings.title)) {
                    TextField(LocalizedStrings.title, text: $title)
                }
                Section(header: Text(LocalizedStrings.color)) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 10) {
                        ForEach(GroupColor.allCases, id: \.self) { color in
                            Circle()
                                .fill(Color(color.color))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                        .padding(1)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle(String(format: LocalizedStrings.addTitle, LocalizedStrings.group))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStrings.cancel) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.save) {
                        viewModel.saveGroup(title: title, color: selectedColor)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
