import Firebase
import GoogleMobileAds
import SwiftUI

@main
struct SportsNote_iOSApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isInitialized = false
    @State private var reinitializationTrigger = UUID()

    init() {
        // 同期的な初期化のみここで実行
        FirebaseApp.configure()

        // Google AdMobの初期化
        MobileAds.shared.start()

        // ネットワーク監視の初期化
        _ = Network.shared

        do {
            try RealmManager.shared.initRealm()
        } catch {
            print("🚨 Realm初期化に失敗しました: \(error.localizedDescription)")
            // アプリの起動を継続するが、データベース機能は使用不可
        }
    }

    var body: some Scene {
        WindowGroup {
            if isInitialized {
                MainTabView()
                    .id(reinitializationTrigger)
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
                    .onReceive(NotificationCenter.default.publisher(for: .shouldReinitializeApp)) { _ in
                        // アプリを再初期化
                        isInitialized = false
                        Task {
                            // LoginViewModelの処理完了を待ってからRealmを再初期化
                            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
                            do {
                                try RealmManager.shared.initRealm()
                            } catch {
                                print("🚨 Realm再初期化に失敗しました: \(error.localizedDescription)")
                            }
                            reinitializationTrigger = UUID()
                            isInitialized = true
                        }
                    }
            } else {
                // 初期化中の表示
                ProgressView(LocalizedStrings.initializing)
                    .task {
                        await InitializationManager.shared.initializeApp()
                        isInitialized = true
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
