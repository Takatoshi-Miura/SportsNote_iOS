import WidgetKit
import SwiftUI

// 課題ウィジェットの定義
struct TaskWidget: Widget {
    let kind: String = "TaskWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskWidgetProvider()) { entry in
            TaskWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("課題ウィジェット")
        .description("未完了の課題と優先度の高い課題を表示します")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}