import WidgetKit
import SwiftUI
import RealmSwift

// ウィジェット表示用のエントリデータ
struct TaskWidgetEntry: TimelineEntry, Sendable {
    let date: Date
    let incompleteTasks: Int
    let topTasks: [TaskWidgetItem]
    
    static let placeholder = TaskWidgetEntry(
        date: Date(),
        incompleteTasks: 3,
        topTasks: [
            TaskWidgetItem(id: "1", title: "ダミー課題1", color: .red),
            TaskWidgetItem(id: "2", title: "ダミー課題2", color: .blue),
            TaskWidgetItem(id: "3", title: "ダミー課題3", color: .green)
        ]
    )
}

// ウィジェット内の課題表示用アイテム
struct TaskWidgetItem: Identifiable, Sendable {
    let id: String
    let title: String
    let color: GroupColor
}

// ウィジェットのデータプロバイダ
struct TaskWidgetProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> TaskWidgetEntry {
        return TaskWidgetEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping @Sendable (TaskWidgetEntry) -> Void) {
        // スナップショットはプレビュー用にプレースホルダーを返す
        if context.isPreview {
            completion(TaskWidgetEntry.placeholder)
        } else {
            // 実際のデータを取得
            Task {
                let entry = await getWidgetData()
                // UIスレッドで完結するよう処理
                await MainActor.run {
                    completion(entry)
                }
            }
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<TaskWidgetEntry>) -> Void) {
        // 実際のデータを取得
        Task {
            let entry = await getWidgetData()
            
            // 次回の更新時間（30分後）
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
            
            // タイムラインの作成
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            // UIスレッドで完結するよう処理
            await MainActor.run {
                completion(timeline)
            }
        }
    }
    
    // RealmからTaskデータを取得
    private func getWidgetData() async -> TaskWidgetEntry {
        // Realmを初期化
        var incompleteTasks = 0
        var topTasks: [TaskWidgetItem] = []
        
        // App Group共有ディレクトリのURLを直接取得（RealmManager.sharedに依存しない）
        let fileURL: URL?
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.sportsnote") {
            fileURL = containerURL.appendingPathComponent("sportsnote.realm")
        } else {
            fileURL = nil
        }
        
        do {
            // Realmの設定
            guard let fileURL = fileURL else {
                return TaskWidgetEntry(date: Date(), incompleteTasks: 0, topTasks: [])
            }
            
            let config = Realm.Configuration(
                fileURL: fileURL,
                readOnly: true // ウィジェットからは読み取り専用でアクセス
            )
            
            // MainActor内でRealmを生成して、すぐにデータを取得・変換してRealmを閉じる
            return await MainActor.run {
                do {
                    let realm = try Realm(configuration: config)
                    
                    // 未完了の課題をカウント
                    incompleteTasks = realm.objects(TaskData.self)
                        .filter("isComplete == false AND isDeleted == false")
                        .count
                    
                    // 未完了の課題を優先度順に取得（最大5件）
                    let tasksResults = realm.objects(TaskData.self)
                        .filter("isComplete == false AND isDeleted == false")
                        .sorted(byKeyPath: "order", ascending: true)
                        .prefix(5)
                    
                    // 取得したRealmデータを安全にコピー
                    let tasksCopy = Array(tasksResults)
                    
                    // メモリ内のデータを使ってWidgetItemを作成
                    topTasks = tasksCopy.compactMap { task in
                        guard let group = realm.object(ofType: Group.self, forPrimaryKey: task.groupID) else {
                            return nil
                        }
                        
                        // GroupColorを取得
                        let colorIndex = Int(group.color)
                        let groupColor = GroupColor.allCases.indices.contains(colorIndex) ?
                            GroupColor.allCases[colorIndex] : .gray
                        
                        return TaskWidgetItem(
                            id: task.taskID,
                            title: task.title,
                            color: groupColor
                        )
                    }
                    
                    return TaskWidgetEntry(
                        date: Date(),
                        incompleteTasks: incompleteTasks,
                        topTasks: topTasks
                    )
                } catch {
                    print("Widget Realm error: \(error)")
                    return TaskWidgetEntry(
                        date: Date(),
                        incompleteTasks: 0,
                        topTasks: []
                    )
                }
            }
        } catch {
            print("Widget config error: \(error)")
            return TaskWidgetEntry(
                date: Date(),
                incompleteTasks: 0,
                topTasks: []
            )
        }
    }
}