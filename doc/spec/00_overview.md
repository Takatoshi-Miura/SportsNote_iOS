# SportsNote iOS アプリ仕様概要

## 1. アプリ概要

| 項目 | 内容 |
|------|------|
| アプリ名 | SportsNote |
| プラットフォーム | iOS 16以上 |
| アーキテクチャ | MVVM (SwiftUI + Combine) |
| ローカルDB | Realm |
| クラウド同期 | Firebase Firestore |
| 認証 | Firebase Authentication |
| 対応言語 | 日本語 / 英語 |

## 2. タブ構成

| タブ | アイコン | 画面 | 概要 |
|------|---------|------|------|
| 課題 | list.bullet | TaskView | 課題・グループの管理 |
| ノート | book | NoteView | ノートの作成・閲覧 |
| 目標 | calendar | TargetView | 年間/月間目標とカレンダー |

## 3. 画面一覧

| No | 画面名 | ファイル | 仕様書 |
|----|--------|---------|--------|
| 1 | 課題一覧 | TaskView.swift | [01_task_list.md](01_task_list.md) |
| 2 | 課題追加 | AddTaskView.swift | [02_add_task.md](02_add_task.md) |
| 3 | 課題詳細 | TaskDetailView.swift | [03_task_detail.md](03_task_detail.md) |
| 4 | グループ追加 | AddGroupView.swift | [04_add_group.md](04_add_group.md) |
| 5 | グループ詳細 | GroupView.swift | [05_group_detail.md](05_group_detail.md) |
| 6 | 対策詳細 | MeasureDetailView.swift | [06_measures_detail.md](06_measures_detail.md) |
| 7 | ノート一覧 | NoteView.swift | [07_note_list.md](07_note_list.md) |
| 8 | フリーノート | FreeNoteView.swift | [08_free_note.md](08_free_note.md) |
| 9 | 練習ノート追加 | AddPracticeNoteView.swift | [09_add_practice_note.md](09_add_practice_note.md) |
| 10 | 練習ノート詳細 | PracticeNoteView.swift | [10_practice_note.md](10_practice_note.md) |
| 11 | 大会ノート追加 | AddTournamentNoteView.swift | [11_add_tournament_note.md](11_add_tournament_note.md) |
| 12 | 大会ノート詳細 | TournamentNoteView.swift | [12_tournament_note.md](12_tournament_note.md) |
| 13 | ノートページ | NotePageView.swift | [13_note_page.md](13_note_page.md) |
| 14 | 目標一覧 | TargetView.swift | [14_target.md](14_target.md) |
| 15 | 目標追加 | AddTargetView.swift | [15_add_target.md](15_add_target.md) |
| 16 | ログイン | LoginView.swift | [16_login.md](16_login.md) |
| 17 | メニュー | MenuView.swift | [17_menu.md](17_menu.md) |
| 18 | チュートリアル | TutorialView.swift | [18_tutorial.md](18_tutorial.md) |
| 19 | 利用規約 | TermsDialogView.swift | [19_terms.md](19_terms.md) |

## 4. 画面遷移図

```
[アプリ起動]
  │
  ├─ 初期化未完了 → ProgressView（ローディング）
  │    └─ InitializationManager.initializeApp()
  │
  └─ 初期化完了 → MainTabView
       │
       ├─ [課題タブ] TaskView
       │    ├─ → AddGroupView (sheet)
       │    ├─ → AddTaskView (sheet)
       │    ├─ → GroupView (navigation)
       │    └─ → TaskDetailView (navigation)
       │         └─ → MeasureDetailView (navigation)
       │              └─ → ノート詳細画面 (navigation)
       │
       ├─ [ノートタブ] NoteView
       │    ├─ → AddPracticeNoteView (sheet)
       │    ├─ → AddTournamentNoteView (sheet)
       │    ├─ → NotePageView (navigation)
       │    ├─ → FreeNoteView (navigation)
       │    ├─ → PracticeNoteView (navigation)
       │    └─ → TournamentNoteView (navigation)
       │
       ├─ [目標タブ] TargetView
       │    ├─ → AddTargetView (sheet)
       │    └─ → ノート詳細画面 (navigation)
       │
       └─ [サイドメニュー] MenuView (全タブ共通)
            ├─ → LoginView (fullScreenCover)
            ├─ → TutorialView (sheet)
            └─ → 利用規約/プライバシーポリシー (Safari)
```

## 5. データモデル

### 5.1 エンティティ関連図

```
Group (1) ──── (0..*) TaskData (1) ──── (0..*) Measures (1) ──── (0..*) Memo
                                                                        │
Note (1) ──────────────────────────────────────────────── (0..*) ───────┘
Target (独立)
```

### 5.2 主要エンティティ

| エンティティ | 主キー | 主要フィールド |
|-------------|--------|---------------|
| Group | groupID | title, color, order |
| TaskData | taskID | title, cause, groupID, order, isComplete |
| Measures | measuresID | taskID, title, order |
| Memo | memoID | measuresID, noteID, detail |
| Note | noteID | noteType(free/practice/tournament), date, 各種フィールド |
| Target | targetID | title, year, month, isYearlyTarget |

### 5.3 共通フィールド

全エンティティに共通するフィールド:

| フィールド | 型 | 説明 |
|-----------|-----|------|
| userID | String | ユーザー識別子 |
| isDeleted | Bool | 論理削除フラグ |
| created_at | Date | 作成日時 |
| updated_at | Date | 更新日時 |

## 6. 共通仕様

### 6.1 データ操作パターン

- **作成**: Realmに保存 → バックグラウンドでFirebaseに同期
- **読み取り**: Realmから取得（ローカルファースト）
- **更新**: Realmを更新 → バックグラウンドでFirebaseに同期
- **削除**: 論理削除（isDeleted = true）→ バックグラウンドでFirebaseに同期

### 6.2 同期仕様

- オンライン＋ログイン状態の場合のみFirebase同期を実行
- 競合解決: updated_atが新しい方を採用
- 同期はバックグラウンドで実行（UIをブロックしない）

### 6.3 エラー表示

エラー発生時はアラートで表示。エラー種別:
- Realmエラー（初期化、読み書き、削除、マイグレーション）
- Firebaseエラー（接続、認証、権限、ネットワーク等）
- ネットワークエラー（接続不可、タイムアウト）

### 6.4 広告

各タブの画面下部にAdMobバナー広告を表示。

### 6.5 多言語対応

全ユーザー向けテキストは日本語/英語に対応。端末の言語設定に従う。

## 7. 初回起動フロー

1. Firebase、AdMob、Realm を初期化
2. UserDefaults の `firstLaunch` フラグを確認
3. **初回起動の場合**:
   - UserDefaults を初期化
   - ユーザーID（UUID）を自動生成
   - フリーノート・未分類グループを自動作成
4. **通常起動（ログイン済み＋オンライン）**:
   - 旧データマイグレーション実行（必要時）
   - Firebaseとデータ同期
5. MainTabView を表示
6. 利用規約の同意状態を確認（未同意なら同意ダイアログ表示）
