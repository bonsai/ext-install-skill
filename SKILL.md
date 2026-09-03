---
name: ext-install
description: Use when the user wants to install or launch a browser extension via CLI from source code (not a built/zipped package). Keywords: 拡張をインストールして, 〇〇の拡張, browser extension install, --load-extension, 拡張ソース, extension source, cloneしてインストール, ソースのまま, .crx, crx pack, Edge, msedge. Covers cloning a GitHub repo, resolving the extension manifest, launching Edge/Chrome with the unpacked source, and packing to .crx for permanent installation.
---

# ext-install — 拡張ソースを CLI でインストール＆起動

「〇〇の拡張をインストールして」に対して、**ソースコードのまま**（ビルド/ZIP不要）で読み込む。
GitHub リポジトリを clone し、`manifest.json` を含むフォルダを Edge / Chrome の `--load-extension` に渡す。

## ゴールの使い分け（最初に確認）

| 目的 | 方法 | 有効範囲 |
|---|---|---|
| **検証・PoC** | `--load-extension` | フラグ付き起動のみ |
| **永続インストール（本番）** | `.crx` をブラウザに設定 | 毎回有効 |

ユーザーの意図を確認。不明なら「ソースのまま」を推奨（ Edge は `.crx` を弾く場合あり）。

## フロー

### 1. 対象の特定
- 指示から拡張名・リポジトリ（`owner/repo`）を確定。不明なら確認。

### 2. clone（ソース取得）
```bash
gh repo clone <owner/repo> <作業ディレクトリ>
```
- clone 先は `$HOME/.local/share/extensions/<repo>`（`%LOCALAPPDATA%\extensions\<repo>`）など永続化に適した場所へ
- 既存なら `git pull --ff-only` で最新化

### 3. manifest の解決
- リポジトリ直下か、`dist/`・`extension/`・`release/` 等を探索して `manifest.json` を含むフォルダを決定（複数あれば確認）

### 4. 起動 or パッケージ化

**検証（--load-extension）— Edge 推奨**
```bash
# Edge
msedge --load-extension="<フォルダ>" --new-window <url>

# Chrome
chrome --load-extension="<フォルダ>" --new-window <url>
```

**永続（.crx パッケージ化）**
```bash
# key が無ければ生成（2回目以降と同じIDにするため保存・漏洩禁止）
google-chrome --pack-extension=<フォルダ>                        # 一時.pem生成
google-chrome --pack-extension=<フォルダ> --pack-extension-key=<key.pem>  # 再ビルド
```
- 出力: `<フォルダ>.crx`（配布用）+ `<key>.pem`（署名キー・**gitignore必須**）
- `.crx` を `chrome://extensions` / `edge://extensions` へドラッグ&ドロップ（デベロッパーモードON）で永続インストール
- **Edge は .crx を弾く場合がある**。その場合は方法C（ソースのまま）を使用

## ドライバスクリプト
同梱 `install.ps1`（Windows PowerShell）:
```powershell
# 自動検出（Edge優先）
powershell -ExecutionPolicy Bypass -File install.ps1

# Edge を明示
powershell -ExecutionPolicy Bypass -File install.ps1 -Browser edge

# Chrome を明示
powershell -ExecutionPolicy Bypass -File install.ps1 -Browser chrome
```

同梱 `install.bat`（ダブルクリック用）:
```bat
install.bat
```

## 検証
- `edge://extensions` / `chrome://extensions` で「読み込み済み」を確認
- 対象サイトでの挙動を確認（例: connpass 検索で Tokyo 自動選択）
- エラーは拡張ページのエラー表示を確認

## 注意
- `--load-extension` は**フラグ付き起動でのみ有効**。通常起動では無効。
- Edge は `.crx` の自動DLを弾く場合がある。確実なのはソースのまま（--load-extension）。
- 再ビルドは**同じ `.pem` キー**を使わないと拡張IDが変わり、アップデート扱いにならない。
- 実行環境（リモートLinux）にブラウザUIが無い場合、`.crx` 生成は可能。ローカル側の取り込み案内をする。
