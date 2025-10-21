import SwiftUI

/// 対策リスト表示コンポーネント
struct MeasuresListView: View {
    @ObservedObject var viewModel: TaskViewModel
    let isReorderingMeasures: Bool

    var body: some View {
        if let detail = viewModel.taskDetail {
            if detail.measuresList.isEmpty {
                Text(LocalizedStrings.noMeasures)
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ForEach(detail.measuresList.indices, id: \.self) { index in
                    NavigationLink(destination: MeasureDetailView(measure: detail.measuresList[index])) {
                        HStack {
                            Text(detail.measuresList[index].title)
                                .font(.body)
                                .lineLimit(2)
                                .padding(.vertical, 4)
                            Spacer()
                        }
                    }
                }
                .onMove { source, destination in
                    if isReorderingMeasures {
                        var updatedMeasures = detail.measuresList
                        updatedMeasures.move(fromOffsets: source, toOffset: destination)
                        Task {
                            _ = await viewModel.updateMeasuresOrder(measures: updatedMeasures)
                        }
                    }
                }
            }
        }
    }
}
