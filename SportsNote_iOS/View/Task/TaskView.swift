import Combine
import SwiftUI

struct TaskView: View {
    @Binding var isMenuOpen: Bool
    @State private var isAddGroupPresented = false
    @State private var isAddTaskPresented = false
    @State private var selectedGroupID: String? = nil
    @State private var selectedGroupForEdit: Group? = nil
    @State private var navigateToGroupEdit = false
    @StateObject private var viewModel = GroupViewModel()
    @StateObject private var taskViewModel = TaskViewModel()
    @State private var refreshTrigger: Bool = false
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        TabTopView(
            title: LocalizedStrings.task,
            isMenuOpen: $isMenuOpen,
            trailingItem: {
                FilterMenuButton(showCompletedTasks: $taskViewModel.showCompletedTasks)
            },
            content: {
                // refreshTriggerの変更で強制的に再構築させる
                VStack(spacing: 0) {
                    // グループセクション
                    GroupListSection(
                        groups: viewModel.groups,
                        selectedGroupID: selectedGroupID,
                        onGroupSelected: { groupID in
                            selectedGroupID = groupID
                            Task {
                                let result: Result<Void, SportsNoteError>
                                if let id = groupID {
                                    result = await taskViewModel.fetchTasksByGroupID(groupID: id)
                                } else {
                                    result = await taskViewModel.fetchData()
                                }
                                if case .failure(let error) = result {
                                    taskViewModel.showErrorAlert(error)
                                }
                            }
                        },
                        onGroupEdit: { group in
                            selectedGroupForEdit = group
                            navigateToGroupEdit = true
                        }
                    )
                    // 課題セクション
                    MainTaskList(
                        taskListData: taskViewModel.filteredTaskListData,
                        tasks: taskViewModel.tasks,
                        onDelete: { taskID in
                            Task {
                                let result = await taskViewModel.delete(id: taskID)
                                if case .failure(let error) = result {
                                    taskViewModel.showErrorAlert(error)
                                }
                            }
                        },
                        onToggleCompletion: { taskID in
                            Task {
                                let result = await taskViewModel.toggleTaskCompletion(taskID: taskID)
                                if case .failure(let error) = result {
                                    taskViewModel.showErrorAlert(error)
                                }
                            }
                        },
                        refreshAction: {
                            Task {
                                let result = await viewModel.fetchData()
                                if case .failure(let error) = result {
                                    viewModel.showErrorAlert(error)
                                }

                                let taskResult: Result<Void, SportsNoteError>
                                if let id = selectedGroupID {
                                    taskResult = await taskViewModel.fetchTasksByGroupID(groupID: id)
                                } else {
                                    taskResult = await taskViewModel.fetchData()
                                }
                                if case .failure(let error) = taskResult {
                                    taskViewModel.showErrorAlert(error)
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

                let taskResult: Result<Void, SportsNoteError>
                if let id = selectedGroupID {
                    taskResult = await taskViewModel.fetchTasksByGroupID(groupID: id)
                } else {
                    taskResult = await taskViewModel.fetchData()
                }
                if case .failure(let error) = taskResult {
                    taskViewModel.showErrorAlert(error)
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
        .errorAlert(
            currentError: $taskViewModel.currentError,
            showingAlert: $taskViewModel.showingErrorAlert
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
                Task {
                    let result: Result<Void, SportsNoteError>
                    if let id = selectedGroupID {
                        result = await taskViewModel.fetchTasksByGroupID(groupID: id)
                    } else {
                        result = await taskViewModel.fetchData()
                    }
                    if case .failure(let error) = result {
                        taskViewModel.showErrorAlert(error)
                    }
                }
            }
            .store(in: &cancellables)
    }
}

extension View {
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
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
