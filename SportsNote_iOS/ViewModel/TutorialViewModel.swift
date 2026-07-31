import Combine
import Foundation

/// チュートリアルページの構造体
struct TutorialPage {
    let title: String
    let description: String
    let imageName: String
}

/// アプリの使い方ページ用ViewModel
@MainActor
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
                title: LocalizedStrings.tutorialPage1Title,
                description: LocalizedStrings.tutorialPage1Description,
                imageName: "screenshot_1"
            ),
            TutorialPage(
                title: LocalizedStrings.tutorialPage2Title,
                description: LocalizedStrings.tutorialPage2Description,
                imageName: "screenshot_2"
            ),
            TutorialPage(
                title: LocalizedStrings.tutorialPage3Title,
                description: LocalizedStrings.tutorialPage3Description,
                imageName: "screenshot_3"
            ),
            TutorialPage(
                title: LocalizedStrings.tutorialPage4Title,
                description: LocalizedStrings.tutorialPage4Description,
                imageName: "screenshot_4"
            ),
            TutorialPage(
                title: LocalizedStrings.tutorialPage5Title,
                description: LocalizedStrings.tutorialPage5Description,
                imageName: "screenshot_5"
            ),
            TutorialPage(
                title: LocalizedStrings.tutorialPage6Title,
                description: LocalizedStrings.tutorialPage6Description,
                imageName: "screenshot_6"
            ),
        ]
    }
}
