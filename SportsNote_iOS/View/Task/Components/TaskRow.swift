import SwiftUI

/// 課題セル
struct TaskRow: View {
    let taskList: TaskListData
    let isComplete: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            GroupColorCircle(color: Color(taskList.groupColor.color))

            VStack(alignment: .leading, spacing: 6) {
                Text(taskList.title)
                    .font(.headline)
                    .strikethrough(isComplete)
                    .foregroundColor(isComplete ? .gray : .primary)

                Text("\(LocalizedStrings.measures): \(taskList.measures)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
