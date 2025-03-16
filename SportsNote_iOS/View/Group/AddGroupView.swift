import UIKit
import SwiftUI

struct AddGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var color: Int = Color.red.hashValue
    @ObservedObject var viewModel: GroupViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                GroupFormContent(
                    title: $title,
                    color: $color
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
                        Task {
                            guard !title.isEmpty else {
                                print("Title cannot be empty")
                                return
                            }
                            viewModel.saveGroup(title: title, colorId: color, order: nil)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct GroupFormContent: View {
    @Binding var title: String
    @Binding var color: Int
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStrings.title)
                TextField("Enter title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Select Color")
                ColorPicker("", selection: Binding(
                    get: { Color(UIColor.systemRed) },
                    set: { newColor in color = newColor.hashValue }
                ))
            }
            .padding(.horizontal)
        }
    }
}

class GroupViewModel: ObservableObject {
    func saveGroup(title: String, colorId: Int, order: Int?) {
        // データ保存処理
    }
}

