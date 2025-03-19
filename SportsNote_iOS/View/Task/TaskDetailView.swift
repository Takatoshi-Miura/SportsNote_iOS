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
    @State private var causeTextHeight: CGFloat = 50  // Default height for TextEditor
    @State private var textEditorWidth: CGFloat = 0   // TextEditorの幅を保存するための変数
    
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
                TextEditor(text: $cause)
                    .frame(height: max(50, causeTextHeight))  // Use dynamic height with a minimum of 50
                    .cornerRadius(8)
                    .onChange(of: cause) { _ in
                        updateTask()
                        calculateTextHeight()
                    }
                    .background(
                        GeometryReader { geometry in
                            Color.clear.onAppear {
                                textEditorWidth = geometry.size.width
                                calculateTextHeight()
                            }
                            .onChange(of: geometry.size.width) { newWidth in
                                textEditorWidth = newWidth
                                calculateTextHeight()
                            }
                        }
                    )
            }
            // グループ
            Section(header: Text(LocalizedStrings.group)) {
                if groups.isEmpty {
                    Text("グループが登録されていません")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    HStack {
                        Circle()
                            .fill(getGroupColor(for: selectedGroupIndex))
                            .frame(width: 16, height: 16)
                        Text(groups.indices.contains(selectedGroupIndex) ? groups[selectedGroupIndex].title : "")
                        Spacer()
                        Menu {
                            ForEach(0..<groups.count, id: \.self) { index in
                                Button(action: {
                                    selectedGroupIndex = index
                                    updateTask()
                                }) {
                                    HStack {
                                        Circle()
                                            .fill(getGroupColor(for: index))
                                            .frame(width: 16, height: 16)
                                        Text(groups[index].title)
                                        if selectedGroupIndex == index {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Text(LocalizedStrings.select)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            // 対策
            Section(header: 
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
            ) {
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
                    // 対策の追加
                    HStack {
                        TextField(String(format: LocalizedStrings.inputTitle, LocalizedStrings.measures), text: $newMeasureTitle)
                        
                        Button(action: {
                            addMeasure()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newMeasureTitle.isEmpty)
                    }
                }
            }
        }
        .navigationTitle(LocalizedStrings.taskDetail)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadData()
        }
        .environment(\.editMode, .constant(isReorderingMeasures ? .active : .inactive))
    }
    
    // TextEditorの高さを計算する改良版
    private func calculateTextHeight() {
        guard !cause.isEmpty else {
            causeTextHeight = 50 // 空の場合はデフォルト高さ
            return
        }
        
        // 1文字あたりの平均幅（ポイント単位）
        let averageCharWidth: CGFloat = 8.0
        
        // 1行あたりの高さ（ポイント単位）
        let lineHeight: CGFloat = 25.0
        
        // TextEditorの内部パディング
        let padding: CGFloat = 16.0
        
        // 利用可能な幅（TextEditor内でテキストが表示される実際の幅）
        // TextEditorのパディングを考慮
        let availableWidth = max(textEditorWidth - 10, 1) // 0除算を避けるため最小値を1とする
        
        var totalLines = 0
        
        // 各段落（改行で区切られたテキスト）を処理
        let paragraphs = cause.components(separatedBy: "\n")
        for paragraph in paragraphs {
            if paragraph.isEmpty {
                // 空の段落は1行としてカウント
                totalLines += 1
            } else {
                // 段落内の文字数から推定される行数を計算
                let charactersPerLine = availableWidth / averageCharWidth
                let estimatedLines = max(1, ceil(CGFloat(paragraph.count) / charactersPerLine))
                totalLines += Int(estimatedLines)
            }
        }
        
        // 最終的な高さを計算（最低1行分を確保）
        causeTextHeight = CGFloat(max(1, totalLines)) * lineHeight + padding
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
    
    /// グループの色を取得
    /// - Parameter index: Index
    /// - Returns: グループの色
    private func getGroupColor(for index: Int) -> Color {
        guard groups.indices.contains(index) else { return Color.gray }
        let colorIndex = Int(groups[index].color)
        
        if GroupColor.allCases.indices.contains(colorIndex) {
            return Color(GroupColor.allCases[colorIndex].color)
        } else {
            return Color.gray
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
}
