import SwiftUI

/// ノートページング表示（読み取り専用）
struct NotePageView: View {
    @StateObject private var viewModel = NoteViewModel()
    @StateObject private var taskViewModel = TaskViewModel()
    @State private var currentNoteID: String?

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            VStack {
                Text(LocalizedStrings.loading)
                    .foregroundColor(.gray)
                    .italic()
                ProgressView()
            }
        } else if viewModel.notes.isEmpty {
            Text(LocalizedStrings.noNotesFound)
                .foregroundColor(.gray)
                .italic()
        } else {
            TabView(selection: $currentNoteID) {
                ForEach(viewModel.notes, id: \.noteID) { note in
                    NotePageContentView(
                        note: note,
                        noteViewModel: viewModel,
                        taskViewModel: taskViewModel,
                        memos: viewModel.getMemosByNoteID(noteID: note.noteID)
                    )
                    .tag(note.noteID as String?)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    /// 現在表示中のノート
    private var currentNote: Note? {
        viewModel.notes.first(where: { $0.noteID == currentNoteID })
    }

    /// 現在表示中のノート種別
    private var currentNoteType: NoteType {
        guard let note = currentNote else { return .practice }
        return NoteType(rawValue: note.noteType) ?? .practice
    }

    /// Navigationヘッダー用のノート種別表示
    private var noteTypeNavigationTitle: some View {
        let indicatorColor = Color(
            currentNote.map { viewModel.getNoteIndicatorColor(noteID: $0.noteID, noteType: currentNoteType) }
            ?? UIColor.systemBlue
        )
        return HStack(spacing: 6) {
            Image(systemName: currentNoteType.icon)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(indicatorColor)
                .cornerRadius(5)

            Text(currentNoteType.title)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }

    var body: some View {
        contentView
            .ignoresSafeArea(edges: .bottom)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                noteTypeNavigationTitle
            }
        }
        .task {
            let result = await viewModel.fetchNotesExcludingFree()
            if case .success = result, let first = viewModel.notes.first {
                currentNoteID = first.noteID
            }
            _ = await taskViewModel.fetchData()
        }
        .errorAlert(
            currentError: $viewModel.currentError,
            showingAlert: $viewModel.showingErrorAlert
        )
    }
}

/// ノートページの読み取り専用コンテンツ
struct NotePageContentView: View {
    let note: Note
    let noteViewModel: NoteViewModel
    let taskViewModel: TaskViewModel
    let memos: [Memo]

    private var noteType: NoteType {
        NoteType(rawValue: note.noteType) ?? .practice
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 基本情報（日付・天気・気温）
                readOnlyBasicInfoSection

                // 体調
                readOnlyTextSection(title: LocalizedStrings.condition, text: note.condition)

                // ノート種別に応じたセクション
                if noteType == .practice {
                    practiceNoteSections
                } else {
                    tournamentNoteSections
                }

                // 反省
                readOnlyTextSection(title: LocalizedStrings.reflection, text: note.reflection)

                // ページインジケータとの重なり防止
                Spacer().frame(height: 40)
            }
            .padding()
        }
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - 基本情報セクション（読み取り専用）

    private var readOnlyBasicInfoSection: some View {
        let weather = Weather(rawValue: note.weather) ?? .sunny
        return VStack(alignment: .leading, spacing: 0) {
            sectionHeader(LocalizedStrings.basicInfo)
                .padding(.top, 8)

            HStack(spacing: 8) {
                // 日付
                Text(DateFormatterUtil.formatDateWithDayOfWeek(note.date))
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                // 天気・気温（ワンセット）
                Image(systemName: weather.icon)
                    .foregroundColor(weather.color)
                Text("\(note.temperature)°C")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
    }

    // MARK: - 練習ノート固有セクション

    private var practiceNoteSections: some View {
        SwiftUI.Group {
            // 目的
            readOnlyTextSection(title: LocalizedStrings.purpose, text: note.purpose)

            // 練習内容
            readOnlyTextSection(title: LocalizedStrings.practiceDetail, text: note.detail)

            // 取り組んだ課題
            readOnlyTaskSection
        }
    }

    // MARK: - 大会ノート固有セクション

    private var tournamentNoteSections: some View {
        SwiftUI.Group {
            // 目標
            readOnlyTextSection(title: LocalizedStrings.target, text: note.target)

            // 意識すること
            readOnlyTextSection(title: LocalizedStrings.consciousness, text: note.consciousness)

            // 結果
            readOnlyTextSection(title: LocalizedStrings.result, text: note.result)
        }
    }

    // MARK: - 課題セクション（読み取り専用）

    /// PracticeNoteViewと同じロジックでタスク-メモペアを構築
    private var taskReflectionPairs: [(task: TaskListData, detail: String)] {
        var result: [String: (task: TaskListData, detail: String)] = [:]
        let noteMemos = memos.filter { !$0.isDeleted }

        for memo in noteMemos {
            if let task = taskViewModel.taskListData.first(where: { $0.measuresID == memo.measuresID }) {
                // taskIDベースで重複排除（PracticeNoteViewの辞書と同じ挙動）
                result[task.taskID] = (task: task, detail: memo.detail)
            }
        }

        return Array(result.values)
    }

    private var readOnlyTaskSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(LocalizedStrings.taskReflection)

            VStack(spacing: 0) {
                let pairs = taskReflectionPairs
                if pairs.isEmpty {
                    Text(LocalizedStrings.noTasksWorkedOn)
                        .foregroundColor(.gray)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(Array(pairs.enumerated()), id: \.element.task.taskID) { index, pair in
                        if index > 0 {
                            Divider()
                        }
                        readOnlyTaskItem(task: pair.task, detail: pair.detail)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
    }

    /// 課題アイテム（読み取り専用）
    private func readOnlyTaskItem(task: TaskListData, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TaskRow(taskList: task, isComplete: false)
                .padding(.horizontal, 4)

            if !detail.isEmpty {
                Text(detail)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    // MARK: - 共通コンポーネント

    /// セクションヘッダー
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
    }

    /// 読み取り専用テキストセクション
    private func readOnlyTextSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title)

            Text(text.isEmpty ? "-" : text)
                .font(.body)
                .foregroundColor(text.isEmpty ? .gray : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(10)
        }
    }

    /// 読み取り専用の行（キー: 値）
    private func readOnlyRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
