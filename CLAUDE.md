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
cd /Users/it6210/Documents/Git/SportsNote_iOS

# 🚨 ビルド前必須: swift-formatの実行（コード品質確保）
# 全ViewModelファイルにswift-formatを適用（推奨）
find SportsNote_iOS/ViewModel -name "*.swift" -exec xcrun swift-format --configuration .swift-format --in-place {} \;

# 特定ファイルにswift-formatを適用する場合
# xcrun swift-format --configuration .swift-format --in-place SportsNote_iOS/ViewModel/GroupViewModel.swift

# 全プロジェクトにswift-formatを適用（慎重に実行）
# find SportsNote_iOS -name "*.swift" -exec xcrun swift-format --configuration .swift-format --in-place {} \;

# Xcodeでプロジェクトを開く
open SportsNote_iOS.xcodeproj

# コマンドラインからビルド
# 🚨 注意: 同名（iPhone 16e）のシミュレータが複数存在する環境では、name指定のみだと
# 「error: Unable to find a device matching the provided destination specifier」で失敗する。
# その場合は`xcrun simctl list devices available`でidを確認し、id指定に切り替える。
xcodebuild -project SportsNote_iOS.xcodeproj -scheme SportsNote_iOS -destination 'platform=iOS Simulator,id=F0355670-E20E-41A6-A5B9-B41E21EC87CB' build

# ビルド結果の確認（エラー・警告・結果のみ表示）
xcodebuild -project SportsNote_iOS.xcodeproj -scheme SportsNote_iOS -destination 'platform=iOS Simulator,id=F0355670-E20E-41A6-A5B9-B41E21EC87CB' build 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)" | tail -10

# テスト実行
xcodebuild -project SportsNote_iOS.xcodeproj -scheme SportsNote_iOS -destination 'platform=iOS Simulator,id=F0355670-E20E-41A6-A5B9-B41E21EC87CB' test
```

### swift-format設定
- **設定ファイル場所**: `/Users/it6210/Documents/Git/SportsNote_iOS/.swift-format`
- **フォーマット形式**: JSON設定ファイル（120文字/行、4スペースインデント等）
- **適用タイミング**: ビルド前に必須実行（コード品質確保）

### 依存関係
- Swift Package Managerを使用（依存関係はXcodeが自動解決）
- 主要な依存関係：RealmSwift、Firebase SDK（Analytics、Auth、Core、Crashlytics、Firestore）

## ディレクトリ構成

```
SportsNote_iOS/
├── SportsNote_iOS/                    # メインアプリケーション
│   ├── Model/                         # データモデル層
│   │   ├── Manager/                   # データ管理クラス
│   │   └── Error/                     # エラー型定義
│   ├── View/                         # ビュー層
│   │   ├── Common/                   # 共通UIコンポーネント
│   │   ├── Task/                     # 課題関連画面
│   │   ├── Note/                     # ノート関連画面
│   │   ├── Target/                   # 目標関連画面
│   │   ├── Group/                    # グループ関連画面
│   │   ├── Measures/                 # 対策関連画面
│   │   └── Setting/                  # 設定関連画面
│   ├── ViewModel/                    # ビューモデル層
│   │   └── Protocols/                # 共通ViewModelプロトコル
│   ├── Utils/                        # ユーティリティ
│   └── Resource/                     # リソース
│       ├── Assets.xcassets/          # アプリアイコン・画像
│       ├── ja.lproj/                 # 日本語ローカライゼーション
│       └── en.lproj/                 # 英語ローカライゼーション
├── SportsNote_iOSTests/              # 単体テスト（UIテストディレクトリは未作成）
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
- CRUD操作を持つViewModel（Group/Measures/Memo/Note/Target/Task）は`SportsNote_iOS/ViewModel/Protocols/`配下の`BaseViewModelProtocol`（fetchData/エラー状態管理）・`CRUDViewModelProtocol`（save/delete/fetchById）・`FirebaseSyncable`（Firebase同期）に準拠する
- `BaseViewModelProtocol`はデフォルト実装として、エラークリア＋`fetchData()`再取得＋失敗時のエラー再表示を1つにまとめた`refresh()`を提供する。View側は個別に`fetchData()`＋エラー表示を実装せず、`onAppear`やPull to Refresh等から`viewModel.refresh()`を呼び出す形に統一する（該当ViewModel: Group/Measures/Memo/Note/Target/Task）
- `BaseViewModelProtocol`は`observeClearAllData(cancellables:)`も提供し、`didClearAllData`通知（ログアウト/アカウント削除時のRealm全削除）を購読して`clearRealmReferences()`（invalidate済みRealmオブジェクト参照のクリア）を呼び出す処理を共通化している

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
- `InitializationManager`: アプリ初期化処理の統括。初回起動時のセットアップ・デフォルトデータ作成に加え、`initializeApp()`は起動時・ログイン時・ログアウト時にも呼び出され、旧アプリからのログイン状態補完（`migrateLoginStateIfNeeded()`）、ログイン済み＋オンライン時の`MigrationManager`による旧データマイグレーションと`SyncManager`によるFirebase同期の実行も担う
- `MigrationManager`: 旧アプリ（UIKit版）のFirebaseデータを新形式（Task+Measures+Memo、Target、Note）に変換するマイグレーション処理
- `MigrationStepRunner`: `MigrationManager`内で1件ごとの「変換→旧データ削除」を実行する補助struct。変換が`MigrationError`で失敗した場合は旧データ削除をスキップして保持する（データ恒久消失防止、Firebase非依存で単体テスト容易）
- `TestDataManager`: DEBUG専用のテストデータ生成・旧形式データのFirebase投入・マイグレーション検証用ユーティリティ
- `BackgroundSyncTracker`: `FirebaseSyncable.performBackgroundSync`が起動したバックグラウンドFirebase同期Taskを追跡するシングルトン。`InitializationManager.deleteAllData()`（ログアウト/アカウント削除）はRealm全削除の直前に`waitForAll()`を呼び、起動済み同期処理の完了を待ってからデータを削除する（同期データ消失・invalidate済みRealmオブジェクトへのアクセスクラッシュを防止）
- `MeasuresOrderResolver`: `MigrationManager`のマイグレーション処理で使う純粋関数enum。旧アプリのmeasuresData（対策タイトルをキーとするDictionary、列挙順不定）から`Measures.order`を決定的に採番するため、"measuresPriority"（旧データのユーザー指定最優先対策）をorder=0に固定し、残りは`sorted()`で決定的にソートする

## 開発ガイドライン

### コードパターン
- ViewModelとUI関連クラスには`@MainActor`を使用
- すべてのデータベース操作は`RealmManager.shared`を通す
- ユーザー向けテキストには`LocalizedStrings`を使用
- 日付フォーマットには`DateFormatterUtil`を使用（パフォーマンス最適化とコード統一）
- 既存の命名規則に従う（プロパティはcamelCase、型はPascalCase）
- タップでキーボードを閉じる処理は`View/Common/ViewExtensions.swift`の`dismissKeyboardOnTap()`（`onTapGesture`ベース）を使うが、`List`内に`NavigationLink`を含む画面（`TaskDetailView`、`MeasureDetailView`）では`onTapGesture`が`NavigationLink`のタップと競合し遷移できなくなるため使用しない。代わりに`.toolbar { ToolbarItemGroup(placement: .keyboard) { ... } }`でキーボード上に「閉じる」ボタン（`LocalizedStrings.close`＋`KeyboardUtil.hideKeyboard()`）を表示する方式を使う

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
- UIテストディレクトリは現時点で未作成
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