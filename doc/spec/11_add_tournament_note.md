# 大会ノート追加画面

## 概要

大会ノートを新規作成する画面。基本情報・大会の目標・結果・反省を入力する。

## 画面構成

- ナビゲーションバー: タイトル「大会ノートの追加」、「キャンセル」ボタン、「保存」ボタン
- Form:
  - 基本情報セクション（BasicInfoSection）: 日付、天気、気温
  - 体調（TextEditorSection）
  - 目標（TextEditorSection）
  - 意識すること（TextEditorSection）
  - 結果（TextEditorSection）
  - 反省（TextEditorSection）

## 前提条件

- ノート一覧画面の＋ボタン →「大会ノート」選択で表示

## 機能仕様

### 基本情報入力

| 項目 | 入力方法 | デフォルト値 |
|------|---------|-------------|
| 日付 | DatePicker | 今日の日付 |
| 天気 | Picker（sunny/cloudy/rainy） | sunny |
| 気温 | Stepper（℃） | 20 |

### テキスト入力

| 項目 | 入力方法 | 必須 |
|------|---------|------|
| 体調 | AutoResizingTextEditor | 任意 |
| 目標 | AutoResizingTextEditor | 任意 |
| 意識すること | AutoResizingTextEditor | 任意 |
| 結果 | AutoResizingTextEditor | 任意 |
| 反省 | AutoResizingTextEditor | 任意 |

### 保存

| 操作 | 期待結果 |
|------|----------|
| 「保存」をタップ | 大会ノートがRealmに保存され、画面が閉じる |

### キャンセル

| 操作 | 期待結果 |
|------|----------|
| 「キャンセル」をタップ | 入力内容を破棄して画面が閉じる |

## 画面遷移

| 遷移元操作 | 遷移先 | 遷移方法 |
|-----------|--------|---------|
| 保存成功 | ノート一覧画面 | sheet dismiss |
| キャンセル | ノート一覧画面 | sheet dismiss |

## 補足

- 保存時にFirebaseへバックグラウンド同期される
- 全項目が任意入力（バリデーションなし）
- 大会ノートには取り組んだ課題セクションはない
