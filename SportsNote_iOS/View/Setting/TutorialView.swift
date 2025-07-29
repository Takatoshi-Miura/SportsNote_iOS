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

                // ナビゲーションボタン
                HStack {
                    // 戻るボタン（最初のページでは非表示）
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text(LocalizedStrings.previous)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                        }
                    } else {
                        Spacer()
                    }

                    Spacer()

                    // 次へボタンまたは完了ボタン
                    Button(action: {
                        if currentPage < viewModel.pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        HStack {
                            Text(
                                currentPage < viewModel.pages.count - 1
                                    ? LocalizedStrings.next : LocalizedStrings.complete)
                            if currentPage < viewModel.pages.count - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
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
        VStack(spacing: 20) {
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)

            // スクリーンショットイメージ
            Image(page.imageName)
                .resizable()
                .scaledToFit()
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding(.horizontal)

            Text(page.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView()
    }
}
