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

struct TabTopView<Content: View, Leading: View, Trailing: View>: View {
    @Binding var isMenuOpen: Bool
    let title: String
    let destination: Content
    let leadingItem: Leading
    let trailingItem: Trailing
    let content: () -> AnyView
    
    init(
        isMenuOpen: Binding<Bool>,
        title: String,
        destination: Content,
        @ViewBuilder leadingItem: () -> Leading,
        @ViewBuilder trailingItem: () -> Trailing,
        @ViewBuilder content: @escaping () -> some View
    ) {
        self._isMenuOpen = isMenuOpen
        self.title = title
        self.destination = destination
        self.leadingItem = leadingItem()
        self.trailingItem = trailingItem()
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        VStack {
            content()
            NavigationLink(destination: destination) {
                Text("Go to \(title) Detail")
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { leadingItem }
            ToolbarItem(placement: .navigationBarTrailing) { trailingItem }
        }
        .overlay(
            MenuView(isMenuOpen: $isMenuOpen)
                .offset(x: isMenuOpen ? 0 : -UIScreen.main.bounds.width)
                .animation(.easeInOut(duration: 0.3), value: isMenuOpen)
        )
    }
}

struct MenuButton: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        Button(action: {
            isMenuOpen.toggle()
        }) {
            Image(systemName: "line.horizontal.3")
                .imageScale(.large)
        }
    }
}

struct MenuView: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Color.black.opacity(0.3)
                    .onTapGesture {
                        isMenuOpen = false
                    }
                
                VStack(alignment: .leading) {
                    Text("Menu Item 1")
                    Text("Menu Item 2")
                    Text("Menu Item 3")
                }
                .frame(width: geometry.size.width * 0.7, height: geometry.size.height)
                .background(Color.gray)
                .offset(x: isMenuOpen ? 0 : -geometry.size.width)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct TaskView: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        TabTopView(
            isMenuOpen: $isMenuOpen,
            title: "Task",
            destination: TaskDetailView(),
            leadingItem: {
                MenuButton(isMenuOpen: $isMenuOpen)
            },
            trailingItem: {},
            content: {
                VStack {
                    Text("Custom Content for Task View")
                    Text("Additional Content")
                }
            }
        )
    }
}

struct NoteView: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        TabTopView(
            isMenuOpen: $isMenuOpen,
            title: "Note",
            destination: NoteDetailView(),
            leadingItem: {
                MenuButton(isMenuOpen: $isMenuOpen)
            },
            trailingItem: {
                Button(action: {
                    print("Right button tapped")
                }) {
                    Image(systemName: "bell.fill")
                        .imageScale(.large)
                }
            },
            content: {
                AnyView(
                    VStack {
                        Text("Custom Content for Note View")
                        Text("Additional Content")
                    }
                )
            }
        )
    }
}

struct TargetView: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        TabTopView(
            isMenuOpen: $isMenuOpen,
            title: "Target",
            destination: TargetDetailView(),
            leadingItem: {
                MenuButton(isMenuOpen: $isMenuOpen)
            },
            trailingItem: {
                Button(action: {
                    print("Right button tapped")
                }) {
                    Image(systemName: "bell.fill")
                        .imageScale(.large)
                }
            },
            content: {
                AnyView(
                    VStack {
                        Text("Custom Content for Target View")
                        Text("Additional Content")
                    }
                )
            }
        )
    }
}

struct TaskDetailView: View {
    var body: some View {
        Text("Task Detail View")
            .navigationTitle("Task Detail")
            .navigationBarTitleDisplayMode(.inline)
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
