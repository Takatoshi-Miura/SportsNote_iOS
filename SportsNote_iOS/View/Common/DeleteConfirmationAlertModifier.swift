import SwiftUI

/// 削除確認Alert表示と削除実行処理を共通化したModifier
struct DeleteConfirmationAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let onDelete: () async -> Result<Void, SportsNoteError>?
    let onFailure: (SportsNoteError) -> Void
    let onSuccess: () -> Void

    func body(content: Content) -> some View {
        content.alert(isPresented: $isPresented) {
            Alert(
                title: Text(title),
                message: Text(message),
                primaryButton: .destructive(Text(LocalizedStrings.delete)) {
                    Task {
                        guard let result = await onDelete() else { return }
                        switch result {
                        case .success:
                            onSuccess()
                        case .failure(let error):
                            onFailure(error)
                        }
                    }
                },
                secondaryButton: .cancel(Text(LocalizedStrings.cancel))
            )
        }
    }
}

// MARK: - View Extension

extension View {
    /// 削除確認Alertを表示する
    /// - Parameters:
    ///   - isPresented: Alert表示状態
    ///   - title: Alertタイトル
    ///   - message: Alertメッセージ
    ///   - onDelete: 削除実行処理（削除対象が存在しない場合はnilを返すことで処理をスキップできる）
    ///   - onFailure: 削除失敗時に実行する処理
    ///   - onSuccess: 削除成功時に実行する処理
    func deleteConfirmationAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        onDelete: @escaping () async -> Result<Void, SportsNoteError>?,
        onFailure: @escaping (SportsNoteError) -> Void,
        onSuccess: @escaping () -> Void
    ) -> some View {
        self.modifier(
            DeleteConfirmationAlertModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                onDelete: onDelete,
                onFailure: onFailure,
                onSuccess: onSuccess
            )
        )
    }
}
