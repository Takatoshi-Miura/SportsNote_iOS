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
                        ForEach(taskViewModel.tasks.filter { task in
                            showCompletedTasks || !task.isComplete
                        }, id: \.taskID) { task in
                            NavigationLink(destination: TaskDetailView(taskData: task)) {
                                TaskRow(task: task, groupColor: getGroupColor(for: task.groupID))
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    taskViewModel.deleteTask(id: task.taskID)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    taskViewModel.toggleTaskCompletion(task: task)
                                } label: {
                                    Label(task.isComplete ? "Incomplete" : "Complete", 
                                          systemImage: task.isComplete ? "xmark.circle" : "checkmark.circle")
                                }
                                .tint(task.isComplete ? .orange : .green)
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
    let task: TaskData
    let groupColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(groupColor)
                .frame(width: 10, height: 10)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isComplete)
                    .foregroundColor(task.isComplete ? .gray : .primary)
                
                if !task.cause.isEmpty {
                    Text(task.cause)
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
