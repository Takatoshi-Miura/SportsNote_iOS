# SportsNote iOS

## 概要

SportsNote iOSは、スポーツ選手やコーチが練習や試合の記録、課題管理、目標設定を効率的に行うためのiOSアプリケーションです。SwiftUIとMVVMアーキテクチャを採用し、直感的で使いやすいインターフェースを提供します。

### アプリの目的

**課題をほったらかしにせず解決へと導き、目標達成をサポートする。**

### ノートを書く意義

#### 上達するために書く
- 気づいたこと、反省点などを復習することで上達する
- 課題に気付くことができる
- 課題に対してどうすれば解決に向かうか意識することで練習の心構えが変わる

#### 目標を忘れない
- モチベーションの維持につながる
- 長期目標、月間目標、週間目標、今日の目標
- 具体的にどう行動するかまで落とし込む

#### 紙のノートの弱点を解決
- どこに書いたか探すのに手間がかかる問題を解決
- 課題が放ったらかしになる問題を解決（一つの課題に集中しすぎて他を忘れてしまうことを防ぐ）

### ターゲットユーザー

- スポーツをする全てのユーザー
- スポーツに限らず、何かの課題に取り組んでいるユーザー

### アプリストア

- [App Store](https://apps.apple.com/us/app/id1526923401)
- [Google Play](https://play.google.com/store/apps/details?id=com.it6210.sportsnote)

### 主な機能

- **課題管理**: 練習や試合で見つかった課題を記録・管理
- **ノート機能**: 練習ノート、大会ノート、フリーノートの作成・管理
- **目標設定**: 年間・月間目標の管理
- **グループ管理**: 課題やノートをカテゴリ別に整理
- **対策管理**: 課題に対する具体的な対策を記録
- **メモ機能**: ノートに紐づく詳細なメモの記録
- **データ同期**: Firebase連携によるクラウド同期機能
- **多言語対応**: 日本語・英語対応

## 設計思想

### データの永続性と同期
- ローカルデータベース（Realm）による高速アクセス
- クラウド同期（Firebase）による複数デバイス間でのデータ共有
- オフライン環境でも基本機能が利用可能

### 拡張性と保守性
- MVVMアーキテクチャによる責務の明確な分離
- 再利用可能なコンポーネント設計
- テスタブルなコード構造

## アーキテクチャ

### MVVM (Model-View-ViewModel) パターン

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      View       │◄──►│   ViewModel     │◄──►│     Model       │
│   (SwiftUI)     │    │   (ObservableObject) │    │  (Realm/Firebase) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

#### Model層
- **データモデル**: Realmオブジェクトとして定義
- **データ管理**: RealmManager、FirebaseManagerによる永続化
- **ビジネスロジック**: データの整合性とバリデーション

#### ViewModel層
- **状態管理**: @Published プロパティによるリアクティブな状態管理
- **データバインディング**: ViewとModelの橋渡し
- **ビジネスロジック**: UI関連のロジック処理

#### View層
- **UI表示**: SwiftUIによる宣言的UI
- **ユーザーインタラクション**: タップ、スワイプなどのイベント処理
- **状態の監視**: ViewModelの状態変化に応じた自動更新

### 技術スタック

#### 言語
- **Swift 6**

#### アーキテクチャ
- **MVVM (Model-View-ViewModel)**

#### ライブラリ管理
- **Swift Package Manager**

#### Apple純正フレームワーク
- **SwiftUI**: 宣言的UI構築
- **Combine**: リアクティブプログラミング
- **Foundation**: 基本的なデータ型と機能

#### サードパーティライブラリ
- **Realm**: ローカルデータベース
- **Firebase**: 認証・データ同期・クラッシュレポート
  - FirebaseAuth: ユーザー認証
  - FirebaseFirestore: クラウドデータベース
  - FirebaseCrashlytics: クラッシュ解析
- **UserDefaults**: アプリ設定とユーザー設定の保存

## ディレクトリ構成

```
SportsNote_iOS/
├── Model/                          # データモデル層
│   ├── Manager/                    # データ管理クラス
│   └── xxx.swift                   # 各種データモデル
├── View/                           # ビュー層
│   ├── Common/                     # 共通コンポーネント
│   ├── Task/                       # 課題関連画面
│   ├── Note/                       # ノート関連画面
│   ├── Target/                     # 目標関連画面
│   ├── Group/                      # グループ関連画面
│   ├── Measures/                   # 対策関連画面
│   └── Setting/                    # 設定関連画面
├── Utils/                          # ユーティリティ
├── Resource/                       # リソース
└── SportsNote_iOSApp.swift         # アプリエントリーポイント
```

## セットアップ

### 必要な環境
- Xcode 15.0以上
- iOS 16.0以上
- Swift 5.9以上

### インストール手順

1. **リポジトリのクローン**
   ```bash
   git clone https://github.com/your-username/SportsNote_iOS.git
   cd SportsNote_iOS
   ```

2. **Xcodeでプロジェクトを開く**
   ```bash
   open SportsNote_iOS.xcodeproj
   ```

3. **依存関係の解決**
   - Xcodeが自動的にSwift Package Managerの依存関係を解決します
   - 必要に応じて「File > Packages > Resolve Package Versions」を実行

4. **Firebase設定**
   - Firebase Consoleでプロジェクトを作成
   - `GoogleService-Info.plist`をダウンロードし、プロジェクトに追加
   - 認証、Firestore、Crashlyticsを有効化

5. **ビルドと実行**
   - シミュレーターまたは実機を選択
   - ⌘+R でビルド・実行

### 依存関係

#### Swift Package Manager
- **RealmSwift**: ローカルデータベース
- **Firebase**: バックエンドサービス
  - FirebaseAnalytics
  - FirebaseAuth
  - FirebaseCore
  - FirebaseCrashlytics
  - FirebaseFirestore
  - FirebaseFirestoreCombine-Community

## コーディング規約

### 1. 命名規則

#### クラス・構造体・列挙型
```swift
// PascalCase を使用
class TaskViewModel: ObservableObject { }
struct TaskData { }
enum GroupColor { }
```

#### 変数・関数・プロパティ
```swift
// camelCase を使用
var taskTitle: String
func saveTask() { }
@Published var isLoading: Bool
```

#### 定数
```swift
// camelCase を使用（グローバル定数はPascalCaseも可）
let maxTaskCount = 100
static let DatabaseName = "sportsnote.realm"
```

### 2. ファイル構成

#### ViewModelの構造
```swift
import SwiftUI
import Combine

@MainActor
class TaskViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var tasks: [TaskData] = []
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    func loadTasks() { }
    
    // MARK: - Private Methods
    private func setupBindings() { }
}
```

#### Viewの構造
```swift
import SwiftUI

struct TaskView: View {
    // MARK: - Properties
    @StateObject private var viewModel = TaskViewModel()
    @State private var showingAddTask = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            content
        }
        .navigationTitle(LocalizedStrings.task)
    }
    
    // MARK: - Private Views
    private var content: some View {
        // View implementation
    }
}

// MARK: - Preview
#Preview {
    TaskView()
}
```

### 3. SwiftUI ベストプラクティス

#### 状態管理
```swift
// ViewModelを使用した状態管理
@StateObject private var viewModel = TaskViewModel()

// 一時的な状態は@State
@State private var showingAlert = false

// 親から子への値渡しは@Binding
@Binding var selectedTask: TaskData?
```

#### View分割
```swift
// 複雑なViewは小さなコンポーネントに分割
var body: some View {
    VStack {
        headerView
        contentView
        footerView
    }
}

private var headerView: some View {
    // Header implementation
}
```

### 4. データ管理

#### Realmオブジェクト
```swift
class TaskData: Object {
    @Persisted(primaryKey: true) var taskID: String
    @Persisted var title: String
    @Persisted var isDeleted: Bool
    
    override init() {
        super.init()
        taskID = UUID().uuidString
        // 初期化処理
    }
}
```

#### データアクセス
```swift
// RealmManagerを通じたデータアクセス
let tasks = RealmManager.shared.getDataList(clazz: TaskData.self)
RealmManager.shared.saveItem(task)
```

### 5. 多言語対応

#### 文字列の定義
```swift
// LocalizedString.swift
struct LocalizedStrings {
    static let task = "task".localized
    static let save = "save".localized
}

// 使用例
Text(LocalizedStrings.task)
```

#### Localizable.strings
```
// ja.lproj/Localizable.strings
"task" = "課題";
"save" = "保存";

// en.lproj/Localizable.strings
"task" = "Task";
"save" = "Save";
```

### 6. エラーハンドリング

```swift
// Result型を使用したエラーハンドリング
func saveTask() -> Result<Void, Error> {
    do {
        // 保存処理
        return .success(())
    } catch {
        return .failure(error)
    }
}

// ViewModelでのエラー処理
@Published var errorMessage: String?

private func handleError(_ error: Error) {
    errorMessage = error.localizedDescription
}
```

### 7. 非同期処理

```swift
// async/await を使用
@MainActor
func loadData() async {
    isLoading = true
    defer { isLoading = false }
    
    do {
        let data = try await dataService.fetchData()
        self.data = data
    } catch {
        handleError(error)
    }
}
```

## コードフォーマット

### swift-format
プロジェクトでは統一されたコードスタイルを維持するためにswift-formatを使用しています。

#### フォーマット実行
```bash
# プロジェクト全体をフォーマット
swift format format --in-place --recursive ~/SportsNote_iOS/SportsNote_iOS
```
