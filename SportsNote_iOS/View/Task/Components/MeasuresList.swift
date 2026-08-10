import SwiftUI

/// 対策リスト表示コンポーネント
struct MeasuresListView: View {
    @ObservedObject var viewModel: TaskViewModel
    @ObservedObject var measuresViewModel: MeasuresViewModel
    @ObservedObject var memoViewModel: MemoViewModel
    @ObservedObject var noteViewModel: NoteViewModel
    let isReorderingMeasures: Bool

    var body: some View {
        if let detail = viewModel.taskDetail {
            if detail.measuresList.isEmpty {
                Text(LocalizedStrings.noMeasures)
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ForEach(detail.measuresList, id: \.measuresID) { measure in
                    NavigationLink(
                        destination: MeasureDetailView(
                            measure: measure,
                            measuresViewModel: measuresViewModel,
                            memoViewModel: memoViewModel,
                            noteViewModel: noteViewModel
                        )
                    ) {
                        HStack {
                            Text(measure.title)
                                .font(.body)
                                .lineLimit(2)
                                .padding(.vertical, 4)
                            Spacer()
                        }
                    }
                }
                .onMove { source, destination in
                    if isReorderingMeasures {
                        // 表示上の並び替えは同期的に即座に反映する（issue #165、issue #161と同パターン）。
                        // Task{}でラップすると一瞬元の位置に戻る視覚的不整合が発生するため直接呼ぶ
                        guard let reordered = viewModel.reorderMeasuresListData(from: source, to: destination) else {
                            return
                        }
                        Task {
                            let result = await viewModel.persistMeasuresOrder(reordered)
                            if case .failure(let error) = result {
                                viewModel.showErrorAlert(error)
                            }
                        }
                    }
                }
            }
        }
    }
}
