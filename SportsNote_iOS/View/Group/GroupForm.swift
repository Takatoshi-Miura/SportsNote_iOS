import SwiftUI

/// グループの共通フォーム
struct GroupForm: View {
    @Binding var title: String
    @Binding var selectedColor: GroupColor
    var onChange: (() -> Void)? = nil

    var body: some View {
        Form {
            // タイトル
            Section(header: Text(LocalizedStrings.title)) {
                TextField(LocalizedStrings.title, text: $title)
                    .onChange(of: title) { _ in
                        onChange?()
                    }
            }
            // カラー
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
                                onChange?()
                            }
                    }
                }
            }
        }
    }
}

