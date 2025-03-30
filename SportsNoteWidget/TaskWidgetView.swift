import WidgetKit
import SwiftUI

// ウィジェットのビュー
struct TaskWidgetView: View {
    var entry: TaskWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }
    
    // 小サイズウィジェット
    private var smallWidget: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 10) {
                // ヘッダー
                HStack {
                    Image(systemName: "checklist")
                        .font(.system(size: 14, weight: .semibold))
                    Text("未完了の課題")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                }
                
                // 未完了件数
                Text("\(entry.incompleteTasks)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.blue)
                
                // 最優先課題
                if let topTask = entry.topTasks.first {
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(topTask.color.color))
                            .frame(width: 10, height: 10)
                        
                        Text(topTask.title)
                            .font(.system(size: 13))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .widgetURL(URL(string: "sportsnote://tasks"))
    }
    
    // 中サイズウィジェット
    private var mediumWidget: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                // ヘッダー
                HStack {
                    Image(systemName: "checklist")
                        .font(.headline)
                    Text("未完了の課題: \(entry.incompleteTasks)件")
                        .font(.headline)
                    Spacer()
                }
                
                Divider()
                
                // 課題リスト
                ForEach(entry.topTasks.prefix(4)) { task in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(task.color.color))
                            .frame(width: 10, height: 10)
                        
                        Text(task.title)
                            .font(.subheadline)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
                
                Spacer()
            }
            .padding()
        }
        .widgetURL(URL(string: "sportsnote://tasks"))
    }
}

// プレビュー
struct TaskWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        TaskWidgetView(entry: .placeholder)
            .previewContext(WidgetPreviewContext(family: .systemSmall))

        TaskWidgetView(entry: .placeholder)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}