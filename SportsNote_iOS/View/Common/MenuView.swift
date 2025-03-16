import SwiftUI

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

struct SectionData {
    let title: String
    let items: [ItemData]
}

struct ItemData {
    let title: String
    let subTitle: String
    let iconRes: String
    let onClick: () -> Void
}

struct MenuView: View {
    @Binding var isMenuOpen: Bool
    
    @State private var isDialogVisible: Bool = false
    @State private var dialogType: DialogType = .none
    @State private var appVersion: String = "1.0.0"
    
    var onDismiss: () -> Void
    
    var sections: [SectionData] { [
        // データ
        SectionData(
            title: LocalizedStrings.data,
            items: [
                ItemData(
                    title: LocalizedStrings.dataTransfer,
                    subTitle: "",
                    iconRes: "cloud",
                    onClick: {
                        // ログイン画面を表示
                        dialogType = .login
                        isDialogVisible = true
                    }
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
                    onClick: {
                        // チュートリアル画面を表示
                        dialogType = .tutorial
                        isDialogVisible = true
                    }
                ),
                ItemData(
                    title: LocalizedStrings.inquiry,
                    subTitle: "",
                    iconRes: "envelope",
                    onClick: {
                        // メーラーを表示 (例: メーラーを開くコードは後で追加)
                    }
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
                    onClick: {
                        // 利用規約画面に遷移
                    }
                ),
                ItemData(
                    title: LocalizedStrings.privacyPolicy,
                    subTitle: "",
                    iconRes: "lock.shield",
                    onClick: {
                        // プライバシーポリシー画面に遷移
                    }
                ),
                ItemData(
                    title: LocalizedStrings.appVersion,
                    subTitle: appVersion,
                    iconRes: "info.circle",
                    onClick: {}
                )
            ]
        )
    ]}
    
    var body: some View {
        GeometryReader { geometry in
            List {
                ForEach(sections, id: \.title) { section in
                    Section(header: Text(section.title)) {
                        ForEach(section.items, id: \.title) { item in
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
                            .onTapGesture {
                                item.onClick()
                            }
                        }
                    }
                }
            }
            .frame(width: geometry.size.width * 0.8)
            .offset(x: 0)
            .sheet(isPresented: $isDialogVisible) {
                if dialogType == .login {
                    LoginScreen(onDismiss: {
                        isDialogVisible = false
                        onDismiss()
                    })
                } else if dialogType == .tutorial {
                    TutorialScreen(onDismiss: {
                        isDialogVisible = false
                    })
                }
            }
        }
    }
}

struct LoginScreen: View {
    var onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("Login Screen")
            Button("Close") {
                onDismiss()
            }
        }
    }
}

struct TutorialScreen: View {
    var onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("Tutorial Screen")
            Button("Close") {
                onDismiss()
            }
        }
    }
}
