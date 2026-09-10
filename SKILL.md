---
name: ext-install
description: >-
  Install a browser extension from a GitHub source repository. Normalize the repository,
  clone or update it, discover and validate manifest.json, then launch Edge or Chrome with
  --load-extension. Research and browser-action helpers are secondary and do not own install logic.
---

# ext-install

**GitHub source → clone/update → manifest → browser launch** を一つのCLI/Skill契約として扱う。

```text
GitHub URL / owner/repo
        ↓
   normalize
        ↓
 clone / pull --ff-only
        ↓
 manifest.json discovery + validation
        ↓
 Edge / Chrome --load-extension
```

## CLI contract

```text
ext-install <owner/repo|GitHub URL> [browser] [url]
```

`browser`:

- `edge`
- `chrome`
- `auto`（default）

`url` は任意。指定すると、拡張をロードした新規ブラウザウィンドウでそのURLを開く。

### PowerShell

```powershell
.\ext-install.ps1 bonsai/hw-msedge-ext edge
.\ext-install.ps1 https://github.com/bonsai/hw-msedge-ext.git edge https://github.com/
```

### Shell

```bash
./ext-install.sh bonsai/hw-msedge-ext edge
./ext-install.sh https://github.com/bonsai/hw-msedge-ext.git chrome https://github.com/
```

## Install steps

### 1. Normalize

受け付ける形式:

- `owner/repo`
- `https://github.com/owner/repo`
- `https://github.com/owner/repo.git`

GitHub以外のURLや不正なrepo名は拒否する。

### 2. Clone / update

初回:

```bash
gh repo clone <owner/repo> <workdir>
```

`gh` がなければ HTTPS `git clone` にフォールバックする。

既存checkout:

```bash
git -C <workdir> pull --ff-only
```

作業ディレクトリはOSのユーザーデータ領域配下の `ext-install/<owner>-<repo>` を使用する。

### 3. Manifest discovery

まずリポジトリ直下の `manifest.json` を確認し、なければ浅いサブディレクトリから探索する。

検証条件:

- JSONとして読める
- `manifest_version` が `2` または `3`
- `name` が存在する

複数候補の自動選択を前提にせず、曖昧な構成は後続のUI/Plan層で扱う。

### 4. Browser launch

```text
Edge:   --load-extension=<extension-dir>
Chrome: --load-extension=<extension-dir>
```

必要なら `--new-window <url>` を追加する。

これは **開発・PoC用のunpacked extension loading**。通常のブラウザへのサイレントインストールやストア審査回避は行わない。

## Architecture

```text
ext-install-skill
  ├─ normalize
  ├─ clone / update
  ├─ manifest discovery
  ├─ validation
  └─ browser launch
          ↓
   Edge / Chrome

ext-install-ext
  └─ thin browser UI / handoff only
```

ブラウザ拡張からローカルCLIを直接実行することはできないため、将来popupから起動する場合はNative Messagingまたはlocalhost bridgeを別途実装する。CLI本体へinstall logicを戻さない。

## Security boundary

- GitHub HTTPS sourceを基本とする
- credentials / cookies / Authorizationを自動注入しない
- arbitrary JavaScriptを実行しない
- 任意のブラウザActionをinstall処理に混ぜない
- unpacked loadingは開発・検証用途に限定

## Related helper

URLを単にブラウザで開く用途は `browser-action.sh` を使用できる。ただし、**extension installのclone/download/manifest/load処理はこのSkillのinstall CLIが所有する**。
