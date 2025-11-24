//
//  TutorialViewModelTests.swift
//  SportsNote_iOSTests
//
//  Created by Swift Testing on 2025/11/23.
//

import Foundation
import Testing

@testable import SportsNote_iOS

@Suite("TutorialViewModel Tests")
@MainActor
struct TutorialViewModelTests {
    
    // MARK: - 初期化テスト
    
    @Test("初期化 - プロパティが正しく初期化される")
    func initialization_propertiesAreInitializedCorrectly() async {
        let viewModel = TutorialViewModel()
        
        #expect(!viewModel.pages.isEmpty)
    }
    
    @Test("初期化 - チュートリアルページ数が正しい")
    func initialization_correctNumberOfPages() async {
        let viewModel = TutorialViewModel()
        
        // TutorialViewModelには6つのページが定義されている
        #expect(viewModel.pages.count == 6)
    }
    
    // MARK: - ページ内容テスト
    
    @Test("ページ内容 - 全てのページにタイトルが設定されている")
    func pageContent_allPagesHaveTitle() async {
        let viewModel = TutorialViewModel()
        
        for page in viewModel.pages {
            #expect(!page.title.isEmpty)
        }
    }
    
    @Test("ページ内容 - 全てのページに説明が設定されている")
    func pageContent_allPagesHaveDescription() async {
        let viewModel = TutorialViewModel()
        
        for page in viewModel.pages {
            #expect(!page.description.isEmpty)
        }
    }
    
    @Test("ページ内容 - 全てのページに画像名が設定されている")
    func pageContent_allPagesHaveImageName() async {
        let viewModel = TutorialViewModel()
        
        for page in viewModel.pages {
            #expect(!page.imageName.isEmpty)
        }
    }
    
    @Test("ページ内容 - 各ページのタイトルが一意")
    func pageContent_uniqueTitles() async {
        let viewModel = TutorialViewModel()
        
        let titles = viewModel.pages.map { $0.title }
        let uniqueTitles = Set(titles)
        
        #expect(titles.count == uniqueTitles.count)
    }
    
    @Test("ページ内容 - 各ページの画像名が一意")
    func pageContent_uniqueImageNames() async {
        let viewModel = TutorialViewModel()
        
        let imageNames = viewModel.pages.map { $0.imageName }
        let uniqueImageNames = Set(imageNames)
        
        #expect(imageNames.count == uniqueImageNames.count)
    }
    
    // MARK: - 個別ページテスト（パラメータ化）
    
    @Test("個別ページ - インデックスでアクセス可能", arguments: 0..<6)
    func individualPage_accessibleByIndex(index: Int) async {
        let viewModel = TutorialViewModel()
        
        #expect(viewModel.pages.indices.contains(index))
        
        let page = viewModel.pages[index]
        #expect(!page.title.isEmpty)
        #expect(!page.description.isEmpty)
        #expect(!page.imageName.isEmpty)
    }
    
    // MARK: - 特定ページの検証
    
    @Test("特定ページ - 最初のページは「SportsNoteとは」")
    func specificPage_firstPageIsSportsNoteIntro() async {
        let viewModel = TutorialViewModel()
        
        let firstPage = viewModel.pages[0]
        #expect(firstPage.title == "SportsNoteとは")
        #expect(firstPage.imageName == "screenshot_1")
    }
    
    @Test("特定ページ - 最後のページは「課題を完了にする」")
    func specificPage_lastPageIsCompleteTask() async {
        let viewModel = TutorialViewModel()
        
        let lastPage = viewModel.pages[5]
        #expect(lastPage.title == "課題を完了にする")
        #expect(lastPage.imageName == "screenshot_6")
    }
    
    // MARK: - 境界値テスト
    
    @Test("境界値 - ページ配列が空でない")
    func boundaryCase_pagesNotEmpty() async {
        let viewModel = TutorialViewModel()
        
        #expect(!viewModel.pages.isEmpty)
    }
    
    @Test("境界値 - 最初のページにアクセス")
    func boundaryCase_accessFirstPage() async {
        let viewModel = TutorialViewModel()
        
        let firstPage = viewModel.pages.first
        #expect(firstPage != nil)
        #expect(firstPage?.title != nil)
    }
    
    @Test("境界値 - 最後のページにアクセス")
    func boundaryCase_accessLastPage() async {
        let viewModel = TutorialViewModel()
        
        let lastPage = viewModel.pages.last
        #expect(lastPage != nil)
        #expect(lastPage?.title != nil)
    }
    
    // MARK: - ページ順序テスト
    
    @Test("ページ順序 - 画像名が連番になっている")
    func pageOrder_imageNamesAreSequential() async {
        let viewModel = TutorialViewModel()
        
        for (index, page) in viewModel.pages.enumerated() {
            let expectedImageName = "screenshot_\(index + 1)"
            #expect(page.imageName == expectedImageName)
        }
    }
    
    // MARK: - TutorialPage構造体テスト
    
    @Test("TutorialPage構造体 - プロパティが正しく設定される")
    func tutorialPageStruct_propertiesSetCorrectly() async {
        let page = TutorialPage(
            title: "テストタイトル",
            description: "テスト説明",
            imageName: "test_image"
        )
        
        #expect(page.title == "テストタイトル")
        #expect(page.description == "テスト説明")
        #expect(page.imageName == "test_image")
    }
    
    @Test("TutorialPage構造体 - 空文字列でも作成可能")
    func tutorialPageStruct_canCreateWithEmptyStrings() async {
        let page = TutorialPage(
            title: "",
            description: "",
            imageName: ""
        )
        
        #expect(page.title == "")
        #expect(page.description == "")
        #expect(page.imageName == "")
    }
    
    @Test("TutorialPage構造体 - 特殊文字を含む文字列",
          arguments: [
            ("タイトル🎾", "説明テキスト", "image_1"),
            ("Title & Name", "Description (test)", "image-2"),
            ("タイトル\n改行", "説明\t\tタブ", "image_3")
          ])
    func tutorialPageStruct_specialCharacters(title: String, description: String, imageName: String) async {
        let page = TutorialPage(
            title: title,
            description: description,
            imageName: imageName
        )
        
        #expect(page.title == title)
        #expect(page.description == description)
        #expect(page.imageName == imageName)
    }
    
    // MARK: - 複数インスタンステスト
    
    @Test("複数インスタンス - 独立したインスタンスが作成される")
    func multipleInstances_independentInstances() async {
        let viewModel1 = TutorialViewModel()
        let viewModel2 = TutorialViewModel()
        
        #expect(viewModel1.pages.count == viewModel2.pages.count)
        #expect(viewModel1.pages.count == 6)
    }
}

// MARK: - テストヘルパー拡張

extension TutorialViewModelTests {
    
    /// テスト用のTutorialPageを作成
    static func createTestPage(
        title: String = "Test Title",
        description: String = "Test Description",
        imageName: String = "test_image"
    ) -> TutorialPage {
        return TutorialPage(
            title: title,
            description: description,
            imageName: imageName
        )
    }
}
