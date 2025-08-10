import RealmSwift
import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskViewModel
    @State private var taskTitle: String = ""
    @State private var cause: String = ""
    @State private var selectedGroupIndex: Int = 0
    @State private var newMeasureTitle = ""
    @State private var groups: [Group] = []
    @State private var isReorderingMeasures = false
    @State private var showCompletionToggleAlert = false
    @State private var showDeleteConfirmation = false

    let taskData: TaskData

    var body: some View {
        List {
            // タイトル
            Section(header: Text(LocalizedStrings.title)) {
                TextField(LocalizedStrings.title, text: $taskTitle)
                    .onChange(of: taskTitle) { _ in
                        updateTask()
                    }
            }
            // 原因
            Section(header: Text(LocalizedStrings.cause)) {
                AutoResizingTextEditor(
                    text: $cause,
                    placeholder: LocalizedStrings.cause,
                    minHeight: 50
                )
                .onChange(of: cause) { _ in
                    updateTask()
                }
            }
            // グループ
            Section(header: Text(LocalizedStrings.group)) {
                if !groups.isEmpty {
                    GroupSelectorView(
                        selectedGroupIndex: $selectedGroupIndex,
                        groups: groups,
                        onSelectionChanged: {
                            updateTask()
                        }
                    )
                }
            }
            // 対策
            Section(header: MeasuresSectionHeaderView(isReorderingMeasures: $isReorderingMeasures)) {
                MeasuresListView(viewModel: viewModel, isReorderingMeasures: isReorderingMeasures)
                if viewModel.taskDetail != nil {
                    AddMeasureView(newMeasureTitle: $newMeasureTitle, onAddAction: addMeasure)
                }
            }
        }
        .navigationTitle(String(format: LocalizedStrings.detailTitle, LocalizedStrings.task))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        showCompletionToggleAlert = true
                    }) {
                        Image(systemName: "checkmark.circle")
                    }

                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .alert(isPresented: $showCompletionToggleAlert) {
            let title =
                (viewModel.taskDetail?.task.isComplete ?? taskData.isComplete)
                ? LocalizedStrings.inCompleteMessage : LocalizedStrings.completeMessage
            return Alert(
                title: Text(title),
                primaryButton: .default(Text(LocalizedStrings.ok)) {
                    viewModel.toggleTaskCompletion(taskID: taskData.taskID)
                    dismiss()
                },
                secondaryButton: .cancel(Text(LocalizedStrings.cancel))
            )
        }
        .background(
            EmptyView()
                .alert(isPresented: $showDeleteConfirmation) {
                    Alert(
                        title: Text(LocalizedStrings.delete),
                        message: Text(String(format: LocalizedStrings.deleteTask)),
                        primaryButton: .destructive(Text(LocalizedStrings.delete)) {
                            viewModel.deleteTask(id: taskData.taskID)
                            dismiss()
                        },
                        secondaryButton: .cancel(Text(LocalizedStrings.cancel))
                    )
                }
        )
        .onAppear {
            loadData()
        }
        .onDisappear {
            // 画面が閉じるときに確実に更新通知を送信して親ビューの更新を促す
            viewModel.taskUpdatedPublisher.send()
        }
        .environment(\.editMode, .constant(isReorderingMeasures ? .active : .inactive))
    }

    private func loadData() {
        // グループデータの読み込み
        groups = (try? RealmManager.shared.getDataList(clazz: Group.self)) ?? []
        if groups.isEmpty { return }

        // タスクデータの読み込み
        viewModel.fetchTaskDetail(taskID: taskData.taskID)

        // 初期値をセット
        taskTitle = taskData.title
        cause = taskData.cause

        // 現在のグループを選択
        if let index = groups.firstIndex(where: { $0.groupID == taskData.groupID }) {
            selectedGroupIndex = index
        } else if !groups.isEmpty {
            // グループIDに一致するものがなければ、最初のグループを選択
            selectedGroupIndex = 0
        }
    }

    private func updateTask() {
        guard !groups.isEmpty, !taskTitle.isEmpty else { return }
        guard groups.indices.contains(selectedGroupIndex) else { return }

        let groupID = groups[selectedGroupIndex].groupID

        viewModel.saveTask(
            taskID: taskData.taskID,
            title: taskTitle,
            cause: cause,
            groupID: groupID,
            order: taskData.order,
            isComplete: taskData.isComplete,
            created_at: taskData.created_at
        )
    }

    /// 対策追加処理
    private func addMeasure() {
        guard !newMeasureTitle.isEmpty else { return }

        let measuresViewModel = MeasuresViewModel()
        measuresViewModel.saveMeasures(
            taskID: taskData.taskID,
            title: newMeasureTitle
        )

        // Viewを更新
        viewModel.fetchTaskDetail(taskID: taskData.taskID)

        newMeasureTitle = ""
    }
}

/// 対策セクションのヘッダーコンポーネント
struct MeasuresSectionHeaderView: View {
    @Binding var isReorderingMeasures: Bool

    var body: some View {
        HStack {
            Text(LocalizedStrings.measuresPriority)
            Spacer()
            Button(action: {
                isReorderingMeasures.toggle()
            }) {
                Text(isReorderingMeasures ? LocalizedStrings.complete : LocalizedStrings.sort)
                    .foregroundColor(.blue)
            }
        }
    }
}

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
                        viewModel.updateMeasuresOrder(measures: updatedMeasures)
                    }
                }
            }
        }
    }
}

/// 対策追加コンポーネント
struct AddMeasureView: View {
    @Binding var newMeasureTitle: String
    let onAddAction: () -> Void

    var body: some View {
        HStack {
            TextField(String(format: LocalizedStrings.inputTitle, LocalizedStrings.measures), text: $newMeasureTitle)
            Button(action: onAddAction) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
            }
            .disabled(newMeasureTitle.isEmpty)
        }
    }
}
