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
    @State private var isMenuOpen = false
    
    enum Tab: Int {
        case task, note, target
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TaskView(isMenuOpen: $isMenuOpen)
            }
            .tabItem {
                Label("Task", systemImage: "checkmark.circle.fill")
            }
            .tag(Tab.task)
            
            NavigationStack {
                NoteView(isMenuOpen: $isMenuOpen)
            }
            .tabItem {
                Label("Note", systemImage: "note.text")
            }
            .tag(Tab.note)
            
            NavigationStack {
                TargetView(isMenuOpen: $isMenuOpen)
            }
            .tabItem {
                Label("Target", systemImage: "target")
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
