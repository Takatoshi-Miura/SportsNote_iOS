# TestFlight自動アップロード（GitHub Actions）

`.github/workflows/testflight.yml` で、アーカイブからApp Store Connect（TestFlight）へのアップロードまでを自動化している。

## 実行タイミング

- `release/<バージョン>` 形式のタグをpushしたとき（例: `release/1.8.1`）
- Actionsタブから手動実行したとき（`workflow_dispatch`）

タグのバージョンと `MARKETING_VERSION` が一致しない場合は失敗する。
ビルド番号は `CURRENT_PROJECT_VERSION` の値をそのまま使うため、従来どおりコミットで更新する。

## 署名方式

アーカイブは未署名で作成し、export時にAppleのクラウド管理配布証明書で署名する。
証明書（.p12）やプロビジョニングプロファイルをSecretsに登録する必要はなく、CI実行ごとに開発証明書が作成されることもない。

## 初回セットアップ

### 1. App Store Connect APIキーを作成する

App Store Connect →「ユーザとアクセス」→「統合」→「App Store Connect API」→「チームキー」で、アクセス権 **Admin** のキーを作成する。
クラウド署名にはAdmin権限が必要（App Manager以下では `Cloud signing permission error` になる）。

`.p8` ファイルは一度しかダウンロードできないため、安全な場所に保管する。

### 2. GitHub Secretsを登録する

リポジトリの Settings → Secrets and variables → Actions に以下を登録する。

| Secret名 | 値 |
| --- | --- |
| `ASC_KEY_ID` | APIキーのキーID |
| `ASC_ISSUER_ID` | 「統合」画面上部に表示されるIssuer ID |
| `ASC_API_KEY_P8_BASE64` | `.p8` ファイルをbase64化した文字列 |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | `GoogleService-Info.plist`（Git管理外）をbase64化した文字列 |

base64化はクリップボードへコピーして貼り付けると楽。

```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
```

```bash
base64 -i SportsNote_iOS/Resource/GoogleService-Info.plist | pbcopy
```

## リリース手順

1. バージョン・ビルド番号を更新してmainにマージする
2. `release/<バージョン>` タグをpushする（TestFlightアップロードとGitHub Releaseが同時に走る）
3. App Store ConnectでTestFlightのビルド処理完了を待ち、審査に提出する

## トラブルシューティング

- 失敗時は実行結果の Artifacts（`xcodebuild-logs`）に archive / export のログが残る
- `Xcode_26.6` がランナーから削除された場合は、ワークフローの `XCODE_VERSION` を更新する
