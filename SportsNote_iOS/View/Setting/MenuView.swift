import SwiftUI
import UIKit

struct MenuView: View {
    @Binding var isMenuOpen: Bool
    @State private var isLoginDialogVisible: Bool = false
    @State private var isTutorialDialogVisible: Bool = false
    private let appVersion: String
    private let appName: String

    // セクションデータ
    @State private var sections: [SectionData] = []

    var onDismiss: () -> Void

    init(isMenuOpen: Binding<Bool>, onDismiss: @escaping () -> Void) {
        self._isMenuOpen = isMenuOpen
        self.onDismiss = onDismiss
        self.appVersion =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? LocalizedStrings.unknown
        self.appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? LocalizedStrings.unknown
    }

    /// メーラーを表示する処理
    private func openMailer() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootViewController = windowScene.windows.first?.rootViewController
        {
            Mailer.openInquiry(from: rootViewController)
        }
    }

    /// セクションデータを作成
    private func createSections() -> [SectionData] {
        var sections: [SectionData] = [
            // データ
            SectionData(
                title: LocalizedStrings.data,
                items: [
                    ItemData(
                        title: LocalizedStrings.login,
                        subTitle: "",
                        iconRes: "person.circle",
                        onClick: { isLoginDialogVisible = true }
                    )
                ]
            ),
            // ヘルプ
            SectionData(
                title: LocalizedStrings.help,
                items: [
                    ItemData(
                        title: LocalizedStrings.howToUseThisApp,
                        subTitle: "",
                        iconRes: "questionmark.circle",
                        onClick: { isTutorialDialogVisible = true }
                    ),
                    ItemData(
                        title: LocalizedStrings.inquiry,
                        subTitle: "",
                        iconRes: "envelope",
                        onClick: { openMailer() }
                    ),
                ]
            ),
            // その他
            SectionData(
                title: LocalizedStrings.other,
                items: [
                    ItemData(
                        title: LocalizedStrings.termsOfService,
                        subTitle: "",
                        iconRes: "doc.text",
                        onClick: { TermsViewModel.navigateToTermsOfService() }
                    ),
                    ItemData(
                        title: LocalizedStrings.privacyPolicy,
                        subTitle: "",
                        iconRes: "lock.shield",
                        onClick: { TermsViewModel.navigateToPrivacyPolicy() }
                    ),
                    ItemData(
                        title: LocalizedStrings.appVersion,
                        subTitle: appVersion,
                        iconRes: "info.circle",
                        onClick: {}
                    ),
                ]
            ),
        ]

        #if DEBUG
            let isLogin = UserDefaultsManager.get(key: UserDefaultsManager.Keys.isLogin, defaultValue: false)
            sections.append(
                SectionData(
                    title: LocalizedStrings.debugSectionTitle,
                    items: [
                        ItemData(
                            title: LocalizedStrings.debugCreateTestData,
                            subTitle: LocalizedStrings.debugCreateTestDataSubtitle,
                            iconRes: "plus.circle",
                            onClick: {
                                Task {
                                    try? await TestDataManager.shared.createTestData()
                                }
                            }
                        ),
                        ItemData(
                            title: LocalizedStrings.debugCreateOldFormatData,
                            subTitle: isLogin
                                ? LocalizedStrings.debugCreateOldFormatDataSubtitle
                                : LocalizedStrings.debugLoginRequired,
                            iconRes: "arrow.up.doc",
                            isEnabled: isLogin,
                            onClick: {
                                Task {
                                    try? await TestDataManager.shared.createOldFormatTestData()
                                }
                            }
                        ),
                        ItemData(
                            title: LocalizedStrings.debugResetMigrationFlag,
                            subTitle: LocalizedStrings.debugResetMigrationFlagSubtitle,
                            iconRes: "arrow.counterclockwise",
                            onClick: {
                                UserDefaultsManager.remove(key: UserDefaultsManager.Keys.migrationV1Completed)
                            }
                        ),
                    ]
                )
            )
        #endif

        return sections
    }

    var body: some View {
        GeometryReader { geometry in
            List {
                ForEach(sections) { section in
                    Section(header: Text(section.title)) {
                        ForEach(section.items) { item in
                            MenuItemView(item: item)
                        }
                    }
                }
            }
            .frame(width: geometry.size.width * 0.8)
            .offset(x: 0)
            .fullScreenCover(isPresented: $isLoginDialogVisible) {
                LoginView(onDismiss: {
                    isLoginDialogVisible = false
                })
            }
            .sheet(isPresented: $isTutorialDialogVisible) {
                TutorialScreen(onDismiss: {
                    isTutorialDialogVisible = false
                })
            }
            .onAppear {
                // 画面表示時にセクションを作成
                if sections.isEmpty {
                    sections = createSections()
                }
            }
        }
    }
}
