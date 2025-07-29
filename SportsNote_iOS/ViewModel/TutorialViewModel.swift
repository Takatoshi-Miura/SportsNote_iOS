import Foundation
import SwiftUI

/// チュートリアルページの構造体
struct TutorialPage {
    let title: String
    let description: String
    let imageName: String
}

/// アプリの使い方ページ用ViewModel
class TutorialViewModel: ObservableObject {
    /// 使い方ページデータ
    @Published var pages: [TutorialPage] = []

    init() {
        setupTutorialPages()
    }

    /// チュートリアルページをセットアップ
    private func setupTutorialPages() {
        pages = [
            TutorialPage(
                title: "SportsNoteとは",
                description: """
                    課題解決に特化したノートアプリです。
                    原因と対策を考えて実践し、反省を通して
                    解決を目指すことができます。
                    """,
                imageName: "screenshot_1"
            ),
            TutorialPage(
                title: "課題の管理①",
                description: """
                    課題を一覧で管理できます。
                    グループを作成することで課題を分類して
                    管理することができます。
                    """,
                imageName: "screenshot_2"
            ),
            TutorialPage(
                title: "課題の管理②",
                description: """
                    課題毎に原因と対策を登録できます。
                    優先度が最も高い対策が
                    ノートに読み込まれるようになります。
                    """,
                imageName: "screenshot_3"
            ),
            TutorialPage(
                title: "ノートを作成",
                description: """
                    練習ノートを作成できます。
                    ノートには登録した課題が読み込まれ、
                    課題への取り組みを記録しておくことができます。
                    """,
                imageName: "screenshot_4"
            ),
            TutorialPage(
                title: "振り返り",
                description: """
                    記録した内容はノートで振り返ることができます。
                    課題＞対策へと進めば、その課題への取り組み内容を
                    まとめて振り返ることもできます。
                    """,
                imageName: "screenshot_5"
            ),
            TutorialPage(
                title: "課題を完了にする",
                description: """
                    解決した課題は完了にすることで
                    ノートへ読み込まれなくなります。完了にしても
                    完了した課題からいつでも振り返ることができます。
                    """,
                imageName: "screenshot_6"
            ),
        ]
    }
}
