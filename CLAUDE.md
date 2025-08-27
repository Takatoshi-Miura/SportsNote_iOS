# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## プロジェクト概要

SportsNote iOSは、アスリートやコーチ向けのSwiftUIベースのスポーツ管理アプリです。
MVVMアーキテクチャを採用し、ローカルのRealmデータベースとFirebaseクラウド同期を使用しています。
アプリは日本語と英語の多言語対応を行い、iOS 16以上をターゲットとしています。

## ビルドコマンド

### ビルドと実行
```bash
# プロジェクトディレクトリに移動
cd /Users/it6210/Documents/Program/Github/SportsNote_iOS

# 🚨 ビルド前必須: swift-formatの実行（コード品質確保）
# 全ViewModelファイルにswift-formatを適用
find SportsNote_iOS/ViewModel -name "*.swift"

# 特定ファイルにswift-formatを適用する場合
# xcrun swift-format --configuration .swift-format --in-place SportsNote_iOS/ViewModel/GroupViewModel.swift

# Xcodeでプロジェクトを開く
open SportsNote_iOS.xcodeproj

# コマンドラインからビルド
xcodebuild -project SportsNote_iOS.xcodeproj -scheme SportsNote_iOS -destination 'platform=iOS Simulator,name=iPhone 16' build

# ビルド結果の確認（エラー・警告・結果のみ表示）
xcodebuild -project SportsNote_iOS.xcodeproj -scheme SportsNote_iOS -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)" | tail -10

# テスト実行
xcodebuild -project SportsNote_iOS.xcodeproj -scheme SportsNote_iOS -destination 'platform=iOS Simulator,name=iPhone 16' test
```

### 依存関係
- Swift Package Managerを使用（依存関係はXcodeが自動解決）
- 主要な依存関係：RealmSwift、Firebase SDK（Analytics、Auth、Core、Crashlytics、Firestore）

## ディレクトリ構成

```
SportsNote_iOS/
├── SportsNote_iOS/                    # メインアプリケーション
│   ├── Model/                         # データモデル層
│   │   └── Manager/                   # データ管理クラス
│   ├── View/                         # ビュー層
│   │   ├── Common/                   # 共通UIコンポーネント
│   │   ├── Task/                     # 課題関連画面
│   │   ├── Note/                     # ノート関連画面
│   │   ├── Target/                   # 目標関連画面
│   │   ├── Group/                    # グループ関連画面
│   │   ├── Measures/                 # 対策関連画面
│   │   └── Setting/                  # 設定関連画面
│   ├── ViewModel/                    # ビューモデル層
│   ├── Utils/                        # ユーティリティ
│   └── Resource/                     # リソース
│       ├── Assets.xcassets/          # アプリアイコン・画像
│       ├── ja.lproj/                 # 日本語ローカライゼーション
│       └── en.lproj/                 # 英語ローカライゼーション
├── SportsNote_iOSTests/              # 単体テスト
├── SportsNote_iOSUITests/            # UIテスト
└── SportsNote_iOS.xcodeproj/         # Xcodeプロジェクトファイル
```

## アーキテクチャ概要

### MVVMパターンの実装
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      View       │◄──►│   ViewModel     │◄──►│     Model       │
│   (SwiftUI)     │    │ (ObservableObject)  │    │ (Realm/Firebase) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Model層**: Firebase同期機能付きRealmオブジェクト
- `RealmManager.swift`: すべてのローカルデータベース操作のシングルトン
- `FirebaseManager.swift`: クラウドデータ同期の処理
- データモデル: `Group.swift`、`TaskData.swift`、`Note.swift`、`Target.swift`、`Measures.swift`、`Memo.swift`

**ViewModel層**: @Publishedプロパティを持つObservableObjectクラス
- 場所: `SportsNote_iOS/ViewModel/`
- 命名規則: `[Entity]ViewModel.swift`（例: `TaskViewModel.swift`）
- リアクティブプログラミングにCombineを使用

**View層**: 機能別に整理されたSwiftUIビュー
- 場所: `SportsNote_iOS/View/`
- 共通コンポーネントは `View/Common/`
- 機能固有のビューはサブディレクトリ（`Task/`、`Note/`、`Target/`など）

### データ管理
- **ローカルストレージ**: Realmデータベース（`RealmManager.shared`）
- **クラウド同期**: `FirebaseManager.shared`経由のFirebase Firestore
- **同期パターン**: `SyncManager`によるバックグラウンドクラウド同期付きローカルファースト
- **ユーザー管理**: アプリ設定用の`UserDefaultsManager`経由UserDefaults

### 主要なマネージャー
- `RealmManager`: データベース操作、クエリ、論理削除
- `FirebaseManager`: すべてのエンティティのクラウドCRUD操作
- `SyncManager`: ローカル-クラウドデータ同期の調整
- `UserDefaultsManager`: アプリ設定とユーザー設定
- `InitializationManager`: 初回起動時のセットアップとデフォルトデータ作成

## 開発ガイドライン

### コードパターン
- ViewModelとUI関連クラスには`@MainActor`を使用
- すべてのデータベース操作は`RealmManager.shared`を通す
- ユーザー向けテキストには`LocalizedStrings`を使用
- 既存の命名規則に従う（プロパティはcamelCase、型はPascalCase）

### 多言語化
- 文字列は`en.lproj/Localizable.strings`と`ja.lproj/Localizable.strings`で定義
- `Resource/LocalizedString.swift`の`LocalizedStrings`構造体経由でアクセス

### データフロー
1. UIイベントがViewModelメソッドをトリガー
2. ViewModelがローカル操作のためRealmManagerを呼び出し
3. SyncManagerがバックグラウンドFirebase同期を処理
4. ViewModelが@PublishedプロパティでUI更新

### 一般的な操作
- **作成**: 最初にRealmに保存、その後Firebaseに同期
- **読み取り**: Realmからクエリ（ローカルファースト）
- **更新**: Realmを更新、同期用にマーク
- **削除**: 論理削除（`isDeleted = true`に設定）

### テスト
- 単体テスト: `SportsNote_iOSTests/`
- UIテスト: `SportsNote_iOSUITests/`
- Xcodeの組み込みテストフレームワークを使用

## プロジェクト設定からのコーディングルール

### SwiftUI/MVVM要件
- 厳密なMVVM分離の維持（Model-View-ViewModel）
- SwiftUIの宣言的構文を使用
- リアクティブプログラミングにCombineを活用
- iOS 16以上の最小ターゲット
- サードパーティライブラリよりもApple純正フレームワークを優先
- コンポーネントの再利用性を重視
- 新機能には既存のコードパターンと最小限の変更を使用

### Realmデータベースルール
- すべてのデータベース操作は`RealmManager.swift`を通す必要がある
- 物理削除ではなく論理削除（`isDeleted`フラグ）を使用
- RealmManagerで確立されたクエリパターンに従う

### 多言語化ルール
- すべてのユーザー向け文字列は`Localizable.strings`で定義する必要がある
- `LocalizedStrings`構造体経由で文字列にアクセス
- 日本語と英語の両方をサポート

### Firebase統合
- すべてのクラウド操作に`FirebaseManager`を使用
- UserDefaultsの`userID`でスコープされたユーザーデータ
- オフラインシナリオを適切に処理

## コミュニケーションガイドライン

### 言語設定
- **このコードベースで作業する際は常に日本語で回答する**
- 開発チームは主に日本語でコミュニケーションを行う
- コードコメントは標準的な日本語で記述する
- 技術的な説明は日本語で提供する