import SwiftUI

#Preview {
    MainTabView()
}

@main
struct SportsNote_iOSApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    setupNavigationBarAppearance()
                }
        }
    }
    
    func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: UIColor.label
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .systemBlue
    }
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .task
    
    enum Tab: Int {
        case task, note, target
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TaskView()
            }
            .tabItem {
                Label(LocalizedStrings.task, systemImage: "checkmark.circle.fill")
            }
            .tag(Tab.task)
            
            NavigationStack {
                NoteView()
            }
            .tabItem {
                Label(LocalizedStrings.note, systemImage: "note.text")
            }
            .tag(Tab.note)
            
            NavigationStack {
                TargetView()
            }
            .tabItem {
                Label(LocalizedStrings.target, systemImage: "target")
            }
            .tag(Tab.target)
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color(.systemBackground), for: .tabBar)
    }
}

struct NoteDetailView: View {
    var body: some View {
        Text("Note Detail View")
            .navigationTitle("Note Detail")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct TargetDetailView: View {
    var body: some View {
        Text("Target Detail View")
            .navigationTitle("Target Detail")
            .navigationBarTitleDisplayMode(.inline)
    }
}
