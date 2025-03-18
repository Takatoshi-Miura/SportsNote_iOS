import SwiftUI

struct TaskView: View {
    @Binding var isMenuOpen: Bool
    @State private var isAddGroupPresented = false
    @State private var isAddTaskPresented = false
    @State private var selectedGroupID: String? = nil
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
                    // Group list horizontal scroll
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
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    .background(Color(.systemGroupedBackground))
                    
                    // Task list
                    List {
                        ForEach(taskViewModel.taskListData.filter { task in
                            showCompletedTasks || !(taskViewModel.tasks.first(where: { $0.taskID == task.taskID })?.isComplete ?? false)
                        }, id: \.taskID) { taskList in
                            NavigationLink(destination: TaskDetailView(taskData: taskViewModel.tasks.first(where: { $0.taskID == taskList.taskID })!)) {
                                TaskRow(taskList: taskList, isComplete: taskViewModel.tasks.first(where: { $0.taskID == taskList.taskID })?.isComplete ?? false)
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
                                    let isComplete = taskViewModel.tasks.first(where: { $0.taskID == taskList.taskID })?.isComplete ?? false
                                    Label(isComplete ? "Incomplete" : "Complete", 
                                          systemImage: isComplete ? "xmark.circle" : "checkmark.circle")
                                }
                                .tint(taskViewModel.tasks.first(where: { $0.taskID == taskList.taskID })?.isComplete ?? false ? .orange : .green)
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
    
    private func getGroupColor(for groupID: String) -> Color {
        if let group = viewModel.groups.first(where: { $0.groupID == groupID }) {
            return Color(GroupColor.allCases[Int(group.color)].color)
        }
        return Color(.systemGray)
    }
}

struct GroupChip: View {
    let group: Group
    let isSelected: Bool
    let onTap: () -> Void
    
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
                    .fill(isSelected ? 
                          Color(GroupColor.allCases[Int(group.color)].color).opacity(0.2) : 
                          Color(.tertiarySystemBackground))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? 
                            Color(GroupColor.allCases[Int(group.color)].color) : 
                            Color(.systemGray4), 
                            lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
                
                // 対策を表示
                Text("対策: \(taskList.measures)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}
