import AppTrackingTransparency
import Foundation

/// App Tracking Transparency(ATT)によるトラッキング許可要求を管理するシングルトン
/// AdMob広告のパーソナライズ配信に使用するIDFAへのアクセス許可をユーザーに求める
@MainActor
final class TrackingPermissionManager {
    static let shared = TrackingPermissionManager()

    private init() {}

    /// トラッキング許可が得られていない場合、AdMobへ非パーソナライズ広告(npa)を要求すべきか
    var requiresNonPersonalizedAds: Bool {
        ATTrackingManager.trackingAuthorizationStatus != .authorized
    }

    /// トラッキング許可状態が未決定の場合のみ、ATTダイアログを表示する
    func requestAuthorizationIfNeeded() {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        ATTrackingManager.requestTrackingAuthorization { _ in }
    }
}
