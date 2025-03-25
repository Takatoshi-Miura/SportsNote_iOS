import SwiftUI
import RealmSwift

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TaskViewModel()
    @State private var taskTitle: String = ""
    @State private var cause: String = ""
    @State private var selectedGroupIndex: Int = 0
    @State private var newMeasureTitle = ""
    @State private var groups: [Group] = []
    @State private var isReorderingMeasures = false
    @State private var showCompletionToggleAlert = false

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
            // 完了状態切り替えアラート
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showCompletionToggleAlert = true
                }) {
                    Image(systemName: "checkmark.circle.fill")
                }
                .alert(isPresented: $showCompletionToggleAlert) {
                    let title = (viewModel.taskDetail?.task.isComplete ?? taskData.isComplete) ?
                    LocalizedStrings.inCompleteMessage : LocalizedStrings.completeMessage
                    return Alert(
                        title: Text(title),
                        primaryButton: .default(Text("OK")) {
                            viewModel.toggleTaskCompletion(taskID: taskData.taskID)
                            dismiss()
                        },
                        secondaryButton: .cancel(Text(LocalizedStrings.cancel))
                    )
                }
            }
        }
        .onAppear {
            loadData()
        }
        .environment(\.editMode, .constant(isReorderingMeasures ? .active : .inactive))
    }

    private func loadData() {
        // グループデータの読み込み
        groups = RealmManager.shared.getDataList(clazz: Group.self)
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

        do {
            let realm = try Realm()
            if let taskToUpdate = realm.object(ofType: TaskData.self, forPrimaryKey: taskData.taskID) {
                try realm.write {
                    taskToUpdate.title = taskTitle
                    taskToUpdate.cause = cause
                    taskToUpdate.groupID = groupID
                    taskToUpdate.updated_at = Date()
                }

                // 詳細情報を更新
                viewModel.fetchTaskDetail(taskID: taskData.taskID)
            }
        } catch {
            print("Error updating task: \(error)")
        }
    }
    
    private func addMeasure() {
        guard !newMeasureTitle.isEmpty else { return }

        viewModel.addMeasure(
            title: newMeasureTitle,
            taskID: taskData.taskID
        )

        // Clear input field
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
                Text("No measures yet")
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
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.deleteMeasure(measuresID: detail.measuresList[index].measuresID)
                        } label: {
                            Label("Delete", systemImage: "trash")
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

// 対策追加コンポーネント
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
