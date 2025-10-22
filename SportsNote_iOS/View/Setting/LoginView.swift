import Combine
import SwiftUI

struct LoginView: View {
    // 環境オブジェクト
    @Environment(\.dismiss) private var dismiss

    // ViewModelの参照
    @StateObject private var viewModel = LoginViewModel()

    // シートを閉じるためのコールバック
    var onDismiss: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // アプリアイコン画像
                    Image("AppIcon")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.top, 20)

                    // アプリ名ラベル
                    Text("SportsNote")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    // ログイン状態を示すラベル
                    Text(viewModel.isLoggedIn ? LocalizedStrings.loggedIn : LocalizedStrings.notLoggedIn)
                        .font(.headline)
                        .foregroundColor(viewModel.isLoggedIn ? .green : .red)
                        .padding(.bottom, 20)

                    VStack(spacing: 15) {
                        // メールアドレス入力フィールド
                        TextField(LocalizedStrings.email, text: $viewModel.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.horizontal)

                        // パスワード入力フィールド
                        SecureField(LocalizedStrings.password, text: $viewModel.password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }

                    // ボタン群
                    VStack(spacing: 15) {
                        // ログイン/ログアウトボタン
                        Button(action: {
                            if viewModel.isLoggedIn {
                                // ログアウト処理
                                viewModel.logout(
                                    onSuccess: {
                                        hideKeyboard()
                                    },
                                    onFailure: {
                                        hideKeyboard()
                                    }
                                )
                            } else {
                                // ログイン処理
                                viewModel.login(
                                    onSuccess: {
                                        hideKeyboard()
                                        onDismiss()
                                        dismiss()
                                    },
                                    onFailure: {
                                        hideKeyboard()
                                    }
                                )
                            }
                        }) {
                            Text(viewModel.isLoggedIn ? LocalizedStrings.logout : LocalizedStrings.login)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)

                        // パスワードリセットボタン
                        Button(action: {
                            viewModel.resetPassword(
                                onSuccess: {
                                    hideKeyboard()
                                    viewModel.email = ""
                                },
                                onFailure: {
                                    hideKeyboard()
                                }
                            )
                        }) {
                            Text(LocalizedStrings.resetPassword)
                                .foregroundColor(.blue)
                                .padding(8)
                        }

                        // アカウント作成ボタン
                        Button(action: {
                            viewModel.createAccount(
                                onSuccess: {
                                    hideKeyboard()
                                    onDismiss()
                                    dismiss()
                                },
                                onFailure: {
                                    hideKeyboard()
                                }
                            )
                        }) {
                            Text(LocalizedStrings.createAccount)
                                .foregroundColor(.blue)
                                .padding(8)
                        }

                        // アカウント削除ボタン（ログイン中のみ表示）
                        if viewModel.isLoggedIn {
                            Button(action: {
                                viewModel.deleteAccount(
                                    onSuccess: {
                                        hideKeyboard()
                                        onDismiss()
                                        dismiss()
                                    },
                                    onFailure: {
                                        hideKeyboard()
                                    }
                                )
                            }) {
                                Text(LocalizedStrings.deleteAccount)
                                    .foregroundColor(.red)
                                    .padding(8)
                            }
                        }

                        // キャンセルボタン
                        Button(action: {
                            onDismiss()
                            dismiss()
                        }) {
                            Text(LocalizedStrings.cancel)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $viewModel.showingAlert) {
                Alert(
                    title: Text(LocalizedStrings.notice),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text(LocalizedStrings.ok))
                )
            }
        }
        .interactiveDismissDisabled()  // スワイプで閉じる動作を無効化
    }

    /// キーボードを閉じる
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
