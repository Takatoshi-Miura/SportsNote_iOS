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
    
    var body: some View {
        TabTopView(
            title: LocalizedStrings.task,
            isMenuOpen: $isMenuOpen,
            trailingItem: {
                Menu {
                    Toggle(isOn: $showCompletedTasks) {
                        Text(showCompletedTasks ? "Hide Completed Tasks" : "Show Completed Tasks")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .imageScale(.large)
                }
            },
            content: {
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
                            viewModel.fetchGroups()
                            if let id = selectedGroupID {
                                taskViewModel.fetchTasksByGroupID(groupID: id)
                            } else {
                                taskViewModel.fetchAllTasks()
                            }
                        }
                    )
                }
            },
            actionItems: [
                (LocalizedStrings.group, { isAddGroupPresented = true }),
                (LocalizedStrings.task, { isAddTaskPresented = true })
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
            viewModel.fetchGroups()
            taskViewModel.fetchAllTasks()
        }
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
                Circle()
                    .fill(Color(GroupColor.allCases[Int(group.color)].color))
                    .frame(width: 12, height: 12)

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

/// 課題セクション
private struct TaskListView: View {
    let taskListData: [TaskListData]
    let tasks: [TaskData]
    let onDelete: (String) -> Void
    let onToggleCompletion: (String) -> Void
    let refreshAction: () async -> Void

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
                        onDelete(taskList.taskID)
                    } label: {
                        Label("Delete", systemImage: "trash")
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
    }

    private func isTaskComplete(taskID: String) -> Bool {
        return tasks.first(where: { $0.taskID == taskID })?.isComplete ?? false
    }

    private func getTaskDetailView(for taskList: TaskListData) -> AnyView {
        if let task = tasks.first(where: { $0.taskID == taskList.taskID }) {
            return TaskDetailView(taskData: task).eraseToAnyView()
        } else {
            return Text("Task not found").eraseToAnyView()
        }
    }
}

struct TaskRow: View {
    let taskList: TaskListData
    let isComplete: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(taskList.groupColor.color))
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
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
        .padding(.vertical, 0)
    }
}
