import SwiftUI

struct TutorialView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = TutorialViewModel()
    @State private var currentPage = 0

    var body: some View {
        NavigationStack {
            VStack {
                // ページ表示部分
                TabView(selection: $currentPage) {
                    ForEach(0..<viewModel.pages.count, id: \.self) { index in
                        TutorialPageView(page: viewModel.pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            }
            .navigationTitle(LocalizedStrings.howToUseThisApp)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.cancel) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

/// チュートリアルの各ページを表示するビュー
struct TutorialPageView: View {
    let page: TutorialPage

    var body: some View {
        VStack(spacing: 0) {
            // タイトル（上寄せ）
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // 説明
            Text(page.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 16)

            // スクリーンショットイメージ（残り領域に収まるように表示）
            Image(page.imageName)
                .resizable()
                .scaledToFit()
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding(.horizontal, 40)
                .frame(maxHeight: .infinity)
                .padding(.bottom, 48)
        }
    }
}

struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView()
    }
}
