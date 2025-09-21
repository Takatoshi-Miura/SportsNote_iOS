import RealmSwift
import SwiftUI

struct TaskDetailView: View {
    private enum AlertType {
        case completionToggle
        case deleteConfirmation
        case error
    }

    private struct AlertItem: Identifiable {
        let type: AlertType

        var id: String {
            switch type {
            case .completionToggle:
                return "completionToggle"
            case .deleteConfirmation:
                return "deleteConfirmation"
            case .error:
                return "error"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskViewModel
    @State private var taskTitle: String = ""
    @State private var cause: String = ""
    @State private var selectedGroupIndex: Int = 0
    @State private var newMeasureTitle = ""
    @State private var groups: [Group] = []
    @State private var isReorderingMeasures = false
    @State private var alertType: AlertType?

    let taskData: TaskData

    var body: some View {
        List {
            // タイトル
            Section(header: Text(LocalizedStrings.title)) {
                TextField(LocalizedStrings.title, text: $taskTitle)
                    .onChange(of: taskTitle) { _ in
                        Task {
                            guard !groups.isEmpty, groups.indices.contains(selectedGroupIndex) else { return }
                            let result = await viewModel.updateTask(
                                taskID: taskData.taskID,
                                title: taskTitle,
                                cause: cause,
                                groupID: groups[selectedGroupIndex].groupID
                            )
                            if case .failure(let error) = result {
                                viewModel.showErrorAlert(error)
                            }
                        }
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
                    Task {
                        guard !groups.isEmpty, groups.indices.contains(selectedGroupIndex) else { return }
                        let result = await viewModel.updateTask(
                            taskID: taskData.taskID,
                            title: taskTitle,
                            cause: cause,
                            groupID: groups[selectedGroupIndex].groupID
                        )
                        if case .failure(let error) = result {
                            viewModel.showErrorAlert(error)
                        }
                    }
                }
            }
            // グループ
            Section(header: Text(LocalizedStrings.group)) {
                if !groups.isEmpty {
                    GroupSelectorView(
                        selectedGroupIndex: $selectedGroupIndex,
                        groups: groups,
                        onSelectionChanged: {
                            Task {
                                guard !groups.isEmpty, groups.indices.contains(selectedGroupIndex) else { return }
                                let result = await viewModel.updateTask(
                                    taskID: taskData.taskID,
                                    title: taskTitle,
                                    cause: cause,
                                    groupID: groups[selectedGroupIndex].groupID
                                )
                                if case .failure(let error) = result {
                                    viewModel.showErrorAlert(error)
                                }
                            }
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
                        alertType = .completionToggle
                    }) {
                        Image(systemName: "checkmark.circle")
                    }

                    Button(action: {
                        alertType = .deleteConfirmation
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .alert(
            item: Binding<AlertItem?>(
                get: { alertType.map(AlertItem.init) },
                set: { _ in alertType = nil }
            )
        ) { alertItem in
            switch alertItem.type {
            case .completionToggle:
                // 完了状態を切り替え
                let title =
                    (viewModel.taskDetail?.task.isComplete ?? taskData.isComplete)
                    ? LocalizedStrings.inCompleteMessage : LocalizedStrings.completeMessage
                return Alert(
                    title: Text(title),
                    primaryButton: .default(Text(LocalizedStrings.ok)) {
                        Task {
                            let result = await viewModel.toggleTaskCompletion(taskID: taskData.taskID)
                            await MainActor.run {
                                switch result {
                                case .success:
                                    dismiss()
                                case .failure(let error):
                                    viewModel.showErrorAlert(error)
                                }
                            }
                        }
                    },
                    secondaryButton: .cancel(Text(LocalizedStrings.cancel))
                )
            case .deleteConfirmation:
                // 削除確認
                return Alert(
                    title: Text(LocalizedStrings.delete),
                    message: Text(String(format: LocalizedStrings.deleteTask)),
                    primaryButton: .destructive(Text(LocalizedStrings.delete)) {
                        Task {
                            let result = await viewModel.delete(id: taskData.taskID)
                            await MainActor.run {
                                switch result {
                                case .success:
                                    dismiss()
                                case .failure(let error):
                                    viewModel.showErrorAlert(error)
                                }
                            }
                        }
                    },
                    secondaryButton: .cancel(Text(LocalizedStrings.cancel))
                )
            case .error:
                // エラー
                return Alert(
                    title: Text(LocalizedStrings.error),
                    message: Text(viewModel.currentError?.localizedDescription ?? LocalizedStrings.errorUnknown),
                    dismissButton: .default(Text(LocalizedStrings.ok))
                )
            }
        }
        .onAppear {
            loadData()
        }
        .onDisappear {
            // 画面が閉じるときに確実に更新通知を送信して親ビューの更新を促す
            viewModel.taskUpdatedPublisher.send()
        }
        .environment(\.editMode, .constant(isReorderingMeasures ? .active : .inactive))
        .onChange(of: viewModel.showingErrorAlert) { showingAlert in
            if showingAlert {
                alertType = .error
            }
        }
        .onChange(of: alertType) { newAlertType in
            if newAlertType == nil {
                // アラートが閉じられたらエラー状態をクリア
                viewModel.hideErrorAlert()
            }
        }
    }

    private func loadData() {
        // グループデータの読み込み
        groups = (try? RealmManager.shared.getDataList(clazz: Group.self)) ?? []
        if groups.isEmpty { return }

        // タスクデータの読み込み
        Task {
            _ = await viewModel.fetchTaskDetail(taskID: taskData.taskID)
        }

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

    /// 対策追加処理
    private func addMeasure() {
        guard !newMeasureTitle.isEmpty else { return }

        // 対策の保存は非同期のため、タイトルをコピーしておかないと保存前にクリアされてしまう
        let titleToSave = newMeasureTitle
        
        // 次の行を空欄で表示するためにクリアする
        newMeasureTitle = ""

        let measuresViewModel = MeasuresViewModel()
        Task {
            let result = await measuresViewModel.saveMeasures(
                taskID: taskData.taskID,
                title: titleToSave
            )

            await MainActor.run {
                if case .failure(let error) = result {
                    // エラー時は入力値を復元
                    newMeasureTitle = titleToSave
                    measuresViewModel.showErrorAlert(error)
                } else {
                    // 成功時のみViewを更新
                    Task {
                        _ = await viewModel.fetchTaskDetail(taskID: taskData.taskID)
                    }
                }
            }
        }
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
                        Task {
                            _ = await viewModel.updateMeasuresOrder(measures: updatedMeasures)
                        }
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
