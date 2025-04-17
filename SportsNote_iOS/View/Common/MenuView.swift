import SwiftUI
import UIKit

struct MenuButton: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        Button(action: {
            withAnimation {
                isMenuOpen.toggle()
            }
        }) {
            Image(systemName: "line.horizontal.3")
                .imageScale(.large)
        }
    }
}

enum DialogType {
    case none, login, tutorial
}

struct SectionData: Identifiable {
    let id = UUID()
    let title: String
    let items: [ItemData]
}

struct ItemData: Identifiable {
    let id = UUID()
    let title: String
    let subTitle: String
    let iconRes: String
    let onClick: () -> Void
}

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
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "不明"
        self.appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "不明"
    }
    
    /// メーラーを表示する処理
    private func openMailer() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            Mailer.openInquiry(from: rootViewController)
        }
    }
    
    /// セクションデータを作成
    private func createSections() -> [SectionData] {
        return [
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
                    )
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
                        onClick: { TermsManager.navigateToTermsOfService() }
                    ),
                    ItemData(
                        title: LocalizedStrings.privacyPolicy,
                        subTitle: "",
                        iconRes: "lock.shield",
                        onClick: { TermsManager.navigateToPrivacyPolicy() }
                    ),
                    ItemData(
                        title: LocalizedStrings.appVersion,
                        subTitle: appVersion,
                        iconRes: "info.circle",
                        onClick: {}
                    )
                ]
            )
        ]
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

/// メニュー項目のビュー
struct MenuItemView: View {
    let item: ItemData
    
    var body: some View {
        HStack {
            Image(systemName: item.iconRes)
            VStack(alignment: .leading) {
                Text(item.title)
            }
            Spacer()
            if !item.subTitle.isEmpty {
                Text(item.subTitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            item.onClick()
        }
    }
}

struct TutorialScreen: View {
    var onDismiss: () -> Void
    
    var body: some View {
        TutorialView()
            .onDisappear {
                onDismiss()
            }
    }
}
