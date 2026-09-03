#!/usr/bin/env bash
# ext-install: 拡張ソースをclone→--load-extensionでブラウザ起動
set -euo pipefail

REPO="${1:?usage: ext-install <owner/repo> [url] [browser]}"
URL="${2:-}"
BROWSER="${3:-auto}"

BASE="${LOCALAPPDATA:-$HOME/.local/share}/extensions"
DIR="$BASE/${REPO//\//-}"

echo "[1/3] source: $DIR"
if [ -d "$DIR/.git" ]; then
  git -C "$DIR" pull --ff-only
else
  gh repo clone "$REPO" "$DIR"
fi

EXT_DIR="$DIR"
if [ ! -f "$DIR/manifest.json" ]; then
  # manifest を含むサブフォルダを探す
  EXT_DIR=$(find "$DIR" -name manifest.json -maxdepth 2 -printf '%h\n' | head -1)
fi
[ -n "$EXT_DIR" ] && [ -f "$EXT_DIR/manifest.json" ] || { echo "manifest.json が見つかりません"; exit 1; }

echo "[2/3] manifest: $EXT_DIR/manifest.json"

detect_chrome() {
  for p in \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
    "$(command -v google-chrome || true)" \
    "$(command -v chromium || true)" \
    "$(command -v microsoft-edge || true)"; do
    [ -n "$p" ] && [ -x "$p" ] && { echo "$p"; return 0; }
  done
  [ -n "${CHROME_PATH:-}" ] && echo "$CHROME_PATH" && return 0
  return 1
}

CHROME=$(detect_chrome) || { echo "ブラウザが見つかりません"; exit 1; }
echo "[3/3] launch: $CHROME --load-extension=$EXT_DIR"

ARGS=("--load-extension=$EXT_DIR")
[ -n "$URL" ] && ARGS+=("--new-window" "$URL")
"$CHROME" "${ARGS[@]}" &

echo "完了。ブラウザが拡張込みで起動しました。"
