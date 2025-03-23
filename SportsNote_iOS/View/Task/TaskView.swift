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
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.groups, id: \.groupID) { group in
                                GroupChip(
                                    group: group,
                                    isSelected: selectedGroupID == group.groupID,
                                    onTap: {
                                        // Toggle selection
                                        if selectedGroupID == group.groupID {
                                            selectedGroupID = nil
                                        } else {
                                            selectedGroupID = group.groupID
                                        }
                                        
                                        // Update tasks
                                        if let id = selectedGroupID {
                                            taskViewModel.fetchTasksByGroupID(groupID: id)
                                        } else {
                                            taskViewModel.fetchAllTasks()
                                        }
                                    },
                                    onEditTap: {
                                        selectedGroupForEdit = group
                                        navigateToGroupEdit = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    
                    // Task list
                    List {
                        ForEach(filteredTaskListData(), id: \.taskID) { taskList in
                            NavigationLink(destination: getTaskDetailView(for: taskList)) {
                                TaskRow(
                                    taskList: taskList,
                                    isComplete: isTaskComplete(taskID: taskList.taskID)
                                )
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    taskViewModel.deleteTask(id: taskList.taskID)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    taskViewModel.toggleTaskCompletion(taskID: taskList.taskID)
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
                        viewModel.fetchGroups()
                        if let id = selectedGroupID {
                            taskViewModel.fetchTasksByGroupID(groupID: id)
                        } else {
                            taskViewModel.fetchAllTasks()
                        }
                    }
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
    
    // MARK: - Helper Methods
    
    private func filteredTaskListData() -> [TaskListData] {
        return taskViewModel.taskListData.filter { task in
            showCompletedTasks || !isTaskComplete(taskID: task.taskID)
        }
    }
    
    private func isTaskComplete(taskID: String) -> Bool {
        return taskViewModel.tasks.first(where: { $0.taskID == taskID })?.isComplete ?? false
    }
    
    private func getTaskDetailView(for taskList: TaskListData) -> AnyView {
        if let task = taskViewModel.tasks.first(where: { $0.taskID == taskList.taskID }) {
            return TaskDetailView(taskData: task).eraseToAnyView()
        } else {
            // フォールバック（理論的にはここには達しない）
            return Text("Task not found").eraseToAnyView()
        }
    }
    
    private func getGroupColor(for groupID: String) -> Color {
        if let group = viewModel.groups.first(where: { $0.groupID == groupID }) {
            return Color(GroupColor.allCases[Int(group.color)].color)
        }
        return Color(.systemGray)
    }
}

extension View {
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }
}

struct GroupChip: View {
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
