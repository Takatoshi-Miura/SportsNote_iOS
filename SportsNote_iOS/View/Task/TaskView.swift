import Combine
import SwiftUI

struct TaskView: View {
    @Binding var isMenuOpen: Bool
    @State private var isAddGroupPresented = false
    @State private var isAddTaskPresented = false
    @State private var selectedGroupID: String? = nil
    @State private var selectedGroupForEdit: Group? = nil
    @State private var navigateToGroupEdit = false
    @State private var showCompletedTasks = false
    @ObservedObject var viewModel = GroupViewModel()
    @ObservedObject var taskViewModel = TaskViewModel()
    @State private var refreshTrigger: Bool = false
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        TabTopView(
            title: LocalizedStrings.task,
            isMenuOpen: $isMenuOpen,
            trailingItem: {
                Menu {
                    Toggle(isOn: $showCompletedTasks) {
                        Text(LocalizedStrings.showCompletedTasks)
                    }
                } label: {
                    Image(
                        systemName: showCompletedTasks
                            ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"
                    )
                    .imageScale(.large)
                }
            },
            content: {
                // refreshTriggerの変更で強制的に再構築させる
                VStack(spacing: 0) {
                    // グループセクション
                    GroupListView(
                        groups: viewModel.groups,
                        selectedGroupID: selectedGroupID,
                        onGroupSelected: { groupID in
                            selectedGroupID = groupID
                            if let id = groupID {
                                taskViewModel.fetchTasksByGroupID(groupID: id)
                            } else {
                                taskViewModel.fetchAllTasks()
                            }
                        },
                        onGroupEdit: { group in
                            selectedGroupForEdit = group
                            navigateToGroupEdit = true
                        }
                    )
                    // 課題セクション
                    TaskListView(
                        taskListData: filteredTaskListData(),
                        tasks: taskViewModel.tasks,
                        onDelete: { taskID in
                            taskViewModel.deleteTask(id: taskID)
                        },
                        onToggleCompletion: { taskID in
                            taskViewModel.toggleTaskCompletion(taskID: taskID)
                        },
                        refreshAction: {
                            Task {
                                let result = await viewModel.fetchData()
                                if case .failure(let error) = result {
                                    viewModel.showErrorAlert(error)
                                }
                                if let id = selectedGroupID {
                                    taskViewModel.fetchTasksByGroupID(groupID: id)
                                } else {
                                    taskViewModel.fetchAllTasks()
                                }
                            }
                        },
                        taskViewModel: taskViewModel
                    )
                }
                .id(refreshTrigger)  // IDを変更することでViewを強制的に再構築
            },
            actionItems: [
                (LocalizedStrings.group, { isAddGroupPresented = true }),
                (LocalizedStrings.task, { isAddTaskPresented = true }),
            ]
        )
        .navigationDestination(isPresented: $navigateToGroupEdit) {
            if let group = selectedGroupForEdit {
                GroupView(group: group, viewModel: viewModel)
            }
        }
        .overlay(TermsDialogView())
        .sheet(isPresented: $isAddGroupPresented) {
            AddGroupView(viewModel: viewModel)
        }
        .sheet(isPresented: $isAddTaskPresented) {
            AddTaskView(viewModel: taskViewModel, groups: viewModel.groups)
        }
        .onAppear {
            // 画面が表示されるたびに最新データを取得
            Task {
                let result = await viewModel.fetchData()
                if case .failure(let error) = result {
                    viewModel.showErrorAlert(error)
                }
                if let id = selectedGroupID {
                    taskViewModel.fetchTasksByGroupID(groupID: id)
                } else {
                    taskViewModel.fetchAllTasks()
                }
            }

            // 画面表示のたびにタスク更新通知を購読し直す
            setupSubscriptions()
        }
        .onDisappear {
            // 画面が非表示になるときに購読をキャンセル
            cancellables.removeAll()
        }
        .errorAlert(
            currentError: $viewModel.currentError,
            showingAlert: $viewModel.showingErrorAlert
        )
    }

    // パブリッシャーの購読処理を行う関数に切り出し
    private func setupSubscriptions() {
        taskViewModel.taskUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // 強制的に画面を再構築するためにトリガーを切り替え
                refreshTrigger.toggle()

                // データも明示的に更新
                if let id = selectedGroupID {
                    taskViewModel.fetchTasksByGroupID(groupID: id)
                } else {
                    taskViewModel.fetchAllTasks()
                }
            }
            .store(in: &cancellables)
    }

    private func filteredTaskListData() -> [TaskListData] {
        return taskViewModel.taskListData.filter { task in
            showCompletedTasks || !isTaskComplete(taskID: task.taskID)
        }
    }

    private func isTaskComplete(taskID: String) -> Bool {
        return taskViewModel.tasks.first(where: { $0.taskID == taskID })?.isComplete ?? false
    }
}

extension View {
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }
}

/// グループセクション
private struct GroupListView: View {
    let groups: [Group]
    let selectedGroupID: String?
    let onGroupSelected: (String?) -> Void
    let onGroupEdit: (Group) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(groups, id: \.groupID) { group in
                    GroupChip(
                        group: group,
                        isSelected: selectedGroupID == group.groupID,
                        onTap: {
                            if selectedGroupID == group.groupID {
                                onGroupSelected(nil)
                            } else {
                                onGroupSelected(group.groupID)
                            }
                        },
                        onEditTap: { onGroupEdit(group) }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
    }
}

private struct GroupChip: View {
    let group: Group
    let isSelected: Bool
    let onTap: () -> Void
    let onEditTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                GroupColorCircle(color: Color(GroupColor.allCases[Int(group.color)].color))

                Text(group.title)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(chipBackgroundColor())
            )
            .overlay(
                Capsule()
                    .stroke(chipStrokeColor(), lineWidth: 1)
            )
        }
        .contextMenu {
            Button(action: onEditTap) {
                Label(LocalizedStrings.edit, systemImage: "pencil")
            }
        }
    }

    private func chipBackgroundColor() -> Color {
        if isSelected {
            return Color(GroupColor.allCases[Int(group.color)].color).opacity(0.2)
        } else {
            return Color(.tertiarySystemBackground)
        }
    }

    private func chipStrokeColor() -> Color {
        if isSelected {
            return Color(GroupColor.allCases[Int(group.color)].color)
        } else {
            return Color(.systemGray4)
        }
    }
}

/// グループカラーサークルコンポーネント
struct GroupColorCircle: View {
    let color: Color
    let size: CGFloat

    init(color: Color, size: CGFloat = 16) {
        self.color = color
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }
}

/// 課題セクション
private struct TaskListView: View {
    let taskListData: [TaskListData]
    let tasks: [TaskData]
    let onDelete: (String) -> Void
    let onToggleCompletion: (String) -> Void
    let refreshAction: () async -> Void
    // TaskViewModelを受け取るように追加
    let taskViewModel: TaskViewModel
    @State private var showDeleteConfirmation = false
    @State private var taskToDelete: String? = nil

    var body: some View {
        List {
            ForEach(taskListData, id: \.taskID) { taskList in
                NavigationLink(destination: getTaskDetailView(for: taskList)) {
                    TaskRow(
                        taskList: taskList,
                        isComplete: isTaskComplete(taskID: taskList.taskID)
                    )
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        taskToDelete = taskList.taskID
                        showDeleteConfirmation = true
                    } label: {
                        Label(LocalizedStrings.delete, systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        onToggleCompletion(taskList.taskID)
                    } label: {
                        let isComplete = isTaskComplete(taskID: taskList.taskID)
                        Label(
                            isComplete ? "Incomplete" : "Complete",
                            systemImage: isComplete ? "xmark.circle" : "checkmark.circle"
                        )
                    }
                    .tint(isTaskComplete(taskID: taskList.taskID) ? .orange : .green)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await refreshAction()
        }
        .alert(
            LocalizedStrings.delete,
            isPresented: $showDeleteConfirmation,
            actions: {
                Button(LocalizedStrings.cancel, role: .cancel) {}
                Button(LocalizedStrings.delete, role: .destructive) {
                    if let taskID = taskToDelete {
                        onDelete(taskID)
                    }
                }
            },
            message: {
                Text(LocalizedStrings.deleteTask)
            }
        )
    }

    private func isTaskComplete(taskID: String) -> Bool {
        return tasks.first(where: { $0.taskID == taskID })?.isComplete ?? false
    }

    private func getTaskDetailView(for taskList: TaskListData) -> AnyView {
        if let task = tasks.first(where: { $0.taskID == taskList.taskID }) {
            // シンプルに共有ViewModelを渡すのみで良い
            return TaskDetailView(viewModel: taskViewModel, taskData: task).eraseToAnyView()
        } else {
            return Text("Task not found").eraseToAnyView()
        }
    }
}

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
