//
//  AdMobBannerView.swift
//  SportsNote_iOS
//
//  Created by Claude on 2025.
//

import GoogleMobileAds
import SwiftUI
import UIKit

/// AdMobバナー広告を表示するSwiftUIビュー
/// UIViewRepresentableを使用してBannerViewをラップ
struct AdMobBannerView: UIViewRepresentable {
    // テスト広告IDを使用（デバッグ用）
    // 本番リリース時は "ca-app-pub-9630417275930781/4051421921" に変更
    #if DEBUG
        private let adUnitID = "ca-app-pub-3940256099942544/2934735716"  // Googleのテスト広告ID
    #else
        private let adUnitID = "ca-app-pub-9630417275930781/4051421921"  // 本番広告ID
    #endif

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator
        bannerView.rootViewController = getRootViewController()
        return bannerView
    }

    // 回転時に前の向きの幅を保持して親レイアウトを押し広げないよう、幅は提案幅に従わせる
    // uiView.adSizeはSwiftUIのレイアウト過程で(0,0)にリセットされるため、固定値のAdSizeBannerを参照する
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: BannerView, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? AdSizeBanner.size.width, height: AdSizeBanner.size.height)
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        guard !context.coordinator.hasStartedLoading else { return }
        context.coordinator.hasStartedLoading = true
        loadWhenReady(uiView, attempt: 0)
    }

    // makeUIView直後はSwiftUIのレイアウトが未確定でuiView.frameの高さが0のままのため、
    // 確定するまで次のRunLoopで再試行してからロードする
    private func loadWhenReady(_ uiView: BannerView, attempt: Int) {
        guard uiView.frame.height > 0 || attempt >= 10 else {
            DispatchQueue.main.async {
                self.loadWhenReady(uiView, attempt: attempt + 1)
            }
            return
        }

        let request = Request()
        if TrackingPermissionManager.shared.requiresNonPersonalizedAds {
            let extras = Extras()
            extras.additionalParameters = ["npa": "1"]
            request.register(extras)
        }
        uiView.load(request)
    }

    /// ルートViewControllerを取得
    private func getRootViewController() -> UIViewController? {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first
                as? UIWindowScene
        else {
            print("⚠️ AdMob: WindowSceneの取得に失敗")
            return nil
        }

        guard let rootViewController = windowScene.windows.first?.rootViewController else {
            print("⚠️ AdMob: RootViewControllerの取得に失敗")
            return nil
        }

        return rootViewController
    }

    /// AdMobバナー広告のデリゲート
    class Coordinator: NSObject, BannerViewDelegate {
        var hasStartedLoading = false

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("✅ AdMob: 広告の読み込み成功")
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ AdMob: 広告の読み込み失敗 - \(error.localizedDescription)")
        }

        func bannerViewDidRecordImpression(_ bannerView: BannerView) {
            print("👁️ AdMob: 広告が表示されました")
        }

        func bannerViewWillPresentScreen(_ bannerView: BannerView) {
            print("📱 AdMob: 広告がフルスクリーンで表示されます")
        }

        func bannerViewWillDismissScreen(_ bannerView: BannerView) {
            print("📱 AdMob: フルスクリーン広告が閉じられます")
        }

        func bannerViewDidDismissScreen(_ bannerView: BannerView) {
            print("📱 AdMob: フルスクリーン広告が閉じられました")
        }
    }
}

/// プレビュー用
struct AdMobBannerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            AdMobBannerView()
                .frame(height: 50)
                .background(Color.gray.opacity(0.1))
        }
    }
}
