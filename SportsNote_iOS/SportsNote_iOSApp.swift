import Firebase
import SwiftUI

@main
struct SportsNote_iOSApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // 初期化
        FirebaseApp.configure()
        RealmManager.shared.initRealm()

        // CrashlyticsにuserID情報を付加
        if let userID = UserDefaults.standard.string(forKey: "userID") {
            Crashlytics.crashlytics().setUserID(userID)
        }

        setupFirstLaunch()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    setupNavigationBarAppearance()
                    checkAndShowTermsDialog()

                    // For debugging
                    RealmManager.shared.printRealmFilePath()
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        checkAndShowTermsDialog()
                    }
                }
        }
    }

    /// 利用規約の同意状態をチェックし、未同意の場合はダイアログを表示
    private func checkAndShowTermsDialog() {
        if !UserDefaultsManager.get(key: UserDefaultsManager.Keys.agree, defaultValue: false) {
            TermsManager.showDialog()
        }
    }

    /// 起動時の初期化処理
    private func setupFirstLaunch() {
        let isFirstLaunch = UserDefaultsManager.get(key: UserDefaultsManager.Keys.firstLaunch, defaultValue: true)
        if isFirstLaunch {
            // userID作成
            let userID = UUID().uuidString
            UserDefaultsManager.set(key: UserDefaultsManager.Keys.userID, value: userID)
            UserDefaultsManager.set(key: UserDefaultsManager.Keys.firstLaunch, value: false)

            // フリーノート作成
            let noteViewModel = NoteViewModel()
            noteViewModel.saveFreeNote(
                title: LocalizedStrings.freeNote,
                detail: LocalizedStrings.defaltFreeNoteDetail
            )

            // 未分類グループ作成
            let groupViewModel = GroupViewModel()
            groupViewModel.saveGroup(
                title: LocalizedStrings.uncategorized,
                color: GroupColor.gray
            )
        }
    }

    func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: UIColor.label,
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .systemBlue
    }
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .task
    @State private var isMenuOpen: Bool = false

    enum Tab: Int {
        case task, note, target
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    TaskView(isMenuOpen: $isMenuOpen)
                }
                .tabItem {
                    Label(LocalizedStrings.task, systemImage: "checkmark.circle.fill")
                }
                .tag(Tab.task)

                NavigationStack {
                    NoteView(isMenuOpen: $isMenuOpen)
                }
                .tabItem {
                    Label(LocalizedStrings.note, systemImage: "note.text")
                }
                .tag(Tab.note)

                NavigationStack {
                    TargetView(isMenuOpen: $isMenuOpen)
                }
                .tabItem {
                    Label(LocalizedStrings.target, systemImage: "target")
                }
                .tag(Tab.target)
            }
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(Color(.systemBackground), for: .tabBar)

            // 設定メニュー
            if isMenuOpen {
                Color.gray.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            isMenuOpen = false
                        }
                    }

                MenuView(
                    isMenuOpen: $isMenuOpen,
                    onDismiss: {
                        isMenuOpen = false
                    }
                )
                .transition(.move(edge: .leading))
                .zIndex(1)
            }
        }
    }
}
