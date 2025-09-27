import SwiftUI

/// SportsNoteError専用のエラーダイアログModifier
/// 重要度に応じた適切なUI表示とユーザー操作を提供
struct ErrorAlertModifier: ViewModifier {
    @Binding var currentError: SportsNoteError?
    @Binding var showingAlert: Bool
    var onRetry: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .alert(
                alertTitle,
                isPresented: $showingAlert,
                presenting: currentError
            ) { error in
                alertButtons(for: error)
            } message: { error in
                alertMessage(for: error)
            }
            .onChange(of: showingAlert) { newValue in
                // アラートが閉じられた時にエラー状態をクリア
                if !newValue {
                    currentError = nil
                }
            }
    }

    // MARK: - Private Methods

    /// エラー種別に応じたアラートタイトル
    private var alertTitle: String {
        guard let error = currentError else { return LocalizedStrings.error }

        switch error {
        case .criticalError(_, _):
            return "🚨 \(LocalizedStrings.errorCriticalTitle)"
        case .systemError(_):
            return "⚠️ \(LocalizedStrings.errorSystemTitle)"
        case .realmInitializationFailed, .realmMigrationFailed:
            return "⚠️ \(LocalizedStrings.errorDatabaseTitle)"
        case .firebaseAuthenticationFailed, .firebasePermissionDenied:
            return "🔐 \(LocalizedStrings.errorAuthTitle)"
        case .networkUnavailable, .networkTimeout, .firebaseNetworkError, .firebaseNotConnected:
            return "🌐 \(LocalizedStrings.errorNetworkTitle)"
        default:
            return "ℹ️ \(LocalizedStrings.errorGeneralTitle)"
        }
    }

    /// エラー種別に応じたアラートメッセージ
    private func alertMessage(for error: SportsNoteError) -> Text {
        var message = error.errorDescription ?? LocalizedStrings.errorUnknown

        // 回復提案がある場合は追加
        if let recovery = error.recoverySuggestion {
            message += "\n\n" + recovery
        }

        return Text(message)
    }

    /// エラー種別に応じたアラートボタン
    @ViewBuilder
    private func alertButtons(for error: SportsNoteError) -> some View {
        // 重大エラーの場合は「OK」のみ
        if case .criticalError(_, _) = error {
            Button(LocalizedStrings.ok) {
                showingAlert = false
            }
        }
        // システムエラーの場合は「OK」のみ（アプリ再起動を促す）
        else if case .systemError(_) = error {
            Button(LocalizedStrings.ok) {
                showingAlert = false
            }
        }
        // その他のエラーは再試行可能
        else {
            // キャンセルボタン
            Button(LocalizedStrings.cancel, role: .cancel) {
                showingAlert = false
            }

            // 再試行ボタン（onRetryが提供されている場合のみ）
            if let retry = onRetry {
                Button(LocalizedStrings.retry) {
                    showingAlert = false
                    retry()
                }
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// SportsNoteError用のエラーアラートを表示する
    /// - Parameters:
    ///   - currentError: 現在のエラー状態（BaseViewModelProtocolのcurrentError）
    ///   - showingAlert: アラート表示状態（BaseViewModelProtocolのshowingErrorAlert）
    ///   - onRetry: 再試行時に実行するアクション（オプション）
    func errorAlert(
        currentError: Binding<SportsNoteError?>,
        showingAlert: Binding<Bool>,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        self.modifier(
            ErrorAlertModifier(
                currentError: currentError,
                showingAlert: showingAlert,
                onRetry: onRetry
            )
        )
    }
}

// MARK: - Preview

#if DEBUG
    struct ErrorAlertModifier_Previews: PreviewProvider {
        @State static var showingAlert = true
        @State static var currentError: SportsNoteError? = .networkUnavailable

        static var previews: some View {
            VStack {
                Text("エラーアラートのプレビュー")
                    .padding()

                Button("ネットワークエラーを表示") {
                    currentError = .networkUnavailable
                    showingAlert = true
                }

                Button("重大エラーを表示") {
                    currentError = .criticalError(
                        NSError(domain: "Test", code: 0),
                        context: "Preview"
                    )
                    showingAlert = true
                }

                Button("データベースエラーを表示") {
                    currentError = .realmInitializationFailed
                    showingAlert = true
                }
            }
            .errorAlert(
                currentError: $currentError,
                showingAlert: $showingAlert,
                onRetry: {
                    print("再試行が実行されました")
                }
            )
        }
    }
#endif
