import MessageUI
import SwiftUI
import UIKit

/// メール機能を提供するユーティリティクラス
@MainActor
class Mailer: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {

    // シングルトンインスタンス
    static let shared = Mailer()

    // 親ビューコントローラーの参照を保持
    private var presentingViewController: UIViewController?

    // 成功時のコールバック
    private var onSuccessCallback: (() -> Void)?

    private override init() {
        super.init()
    }

    /// お問い合わせメーラーを開く
    /// - Parameters:
    ///   - viewController: メーラーを表示するViewControllerコンテキスト
    ///   - onSuccess: メール送信成功時のコールバック（オプション）
    static func openInquiry(from viewController: UIViewController, onSuccess: (() -> Void)? = nil) {
        // 開発者メールアドレス
        let email = "SportsNote開発者<it6210ge@gmail.com>"

        // 件名
        let subject = LocalizedStrings.inquiry

        // デバイス情報
        let deviceName = UIDevice.current.name
        let deviceModel = UIDevice.current.model
        let osVersion = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"

        // アプリバージョン
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? LocalizedStrings.notSet
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? LocalizedStrings.notSet

        // メール本文
        let body = """
            \(LocalizedStrings.pleaseEnterInquiry)


            \(LocalizedStrings.doNotDeleteBelow)
            ■\(LocalizedStrings.deviceInfo)：\(deviceName) (\(deviceModel))
            ■\(LocalizedStrings.osVersion)：\(osVersion)
            ■\(LocalizedStrings.appVersion)：\(appVersion) (\(buildNumber))
            """

        shared.launchMailer(from: viewController, email: email, subject: subject, body: body, onSuccess: onSuccess)
    }

    /// メーラーを起動する
    /// - Parameters:
    ///   - viewController: メーラーを表示するViewControllerコンテキスト
    ///   - email: 宛先メールアドレス
    ///   - subject: 件名
    ///   - body: 本文
    ///   - onSuccess: メール送信成功時のコールバック（オプション）
    private func launchMailer(
        from viewController: UIViewController, email: String, subject: String, body: String,
        onSuccess: (() -> Void)? = nil
    ) {
        // 表示元ビューコントローラーを保持
        self.presentingViewController = viewController
        self.onSuccessCallback = onSuccess

        // メールアプリが利用可能な場合はMFMailComposeViewControllerを使用
        if MFMailComposeViewController.canSendMail() {
            showMailComposer(from: viewController, email: email, subject: subject, body: body)
            return
        }

        // URLスキームを使ったフォールバック
        guard let urlString = createMailtoURLString(email: email, subject: subject, body: body),
            let url = URL(string: urlString),
            UIApplication.shared.canOpenURL(url)
        else {
            // URLスキームも利用できない場合はエラーアラートを表示
            showMailerNotFoundAlert(from: viewController)
            return
        }

        // URLスキームでメーラーを起動
        UIApplication.shared.open(url)
    }

    /// メールコンポーザーを表示
    private func showMailComposer(from viewController: UIViewController, email: String, subject: String, body: String) {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients([email])
        mailComposer.setSubject(subject)
        mailComposer.setMessageBody(body, isHTML: false)

        viewController.present(mailComposer, animated: true)
    }

    /// MFMailComposeViewControllerのデリゲートメソッド
    /// メール作成画面が閉じられた時に呼ばれる
    func mailComposeController(
        _ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?
    ) {
        // メーラーを閉じる
        controller.dismiss(animated: true)

        // エラーが発生した場合は通知
        if let error = error {
            print("Mail error: \(error.localizedDescription)")
            if let viewController = self.presentingViewController {
                showErrorAlert(
                    from: viewController, message: "\(LocalizedStrings.mailError): \(error.localizedDescription)")
            }
        } else if result == .sent {
            // メール送信成功時のコールバックを実行
            DispatchQueue.main.async { [weak self] in
                self?.onSuccessCallback?()
            }
        }

        // 表示元ビューコントローラーの参照をクリア
        self.presentingViewController = nil
        self.onSuccessCallback = nil
    }

    /// mailto: URLスキーム文字列を作成
    private func createMailtoURLString(email: String, subject: String, body: String) -> String? {
        return
            "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

    /// メーラーが見つからない場合のアラートを表示
    private func showMailerNotFoundAlert(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: LocalizedStrings.error,
            message: LocalizedStrings.mailAppNotFound,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: LocalizedStrings.ok, style: .default))
        viewController.present(alert, animated: true)
    }

    /// エラーアラートを表示
    private func showErrorAlert(from viewController: UIViewController, message: String) {
        let alert = UIAlertController(
            title: LocalizedStrings.error,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: LocalizedStrings.ok, style: .default))
        viewController.present(alert, animated: true)
    }
}

/// SwiftUIからMailerを使用するための拡張
extension View {
    /// お問い合わせメーラーを開く
    /// - Parameter onSuccess: メール送信成功時のコールバック（オプション）
    func openInquiryMailer(onSuccess: (() -> Void)? = nil) {
        // UIWindowSceneから現在のUIWindowを取得
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootViewController = windowScene.windows.first?.rootViewController
        {
            Mailer.openInquiry(from: rootViewController, onSuccess: onSuccess)
        }
    }
}
