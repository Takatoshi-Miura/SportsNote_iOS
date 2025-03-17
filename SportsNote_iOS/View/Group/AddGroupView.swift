import UIKit
import SwiftUI

struct AddGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var selectedColor: GroupColor = .red
    @ObservedObject var viewModel: GroupViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                GroupFormContent(
                    title: $title,
                    selectedColor: $selectedColor
                )
                Spacer()
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
                        guard !title.isEmpty else {
                            // Show alert for empty title (could be improved)
                            print("Title cannot be empty")
                            return
                        }
                        viewModel.saveGroup(title: title, color: selectedColor)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GroupFormContent: View {
    @Binding var title: String
    @Binding var selectedColor: GroupColor
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStrings.title)
                    .font(.headline)
                TextField("", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 10) {
                    ForEach(GroupColor.allCases, id: \.self) { color in
                        Circle()
                            .fill(Color(color.color))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                    .padding(1)
                            )
                            .onTapGesture {
                                selectedColor = color
                            }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.top)
    }
}
