#!/usr/bin/env bash
# ext-browser-action: URL-first browser handoff used by ext-install.
set -euo pipefail

ACTION="${1:-open_url}"
URL="${2:?usage: browser-action.sh <open_url|navigate> <http(s)://...> [browser]}"
BROWSER="${3:-auto}"

case "$URL" in
  http://*|https://*) ;;
  *) echo "unsupported URL: only http/https is allowed" >&2; exit 2 ;;
esac

find_browser() {
  case "$BROWSER" in
    edge)
      command -v microsoft-edge || command -v msedge || true ;;
    chrome)
      command -v google-chrome || command -v google-chrome-stable || command -v chromium || true ;;
    auto)
      command -v microsoft-edge || command -v msedge || command -v google-chrome || command -v chromium || true ;;
    *)
      echo "unknown browser: $BROWSER" >&2; exit 2 ;;
  esac
}

case "$ACTION" in
  open_url|navigate) ;;
  *) echo "unsupported action: $ACTION" >&2; exit 2 ;;
esac

if command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -NoProfile -Command "Start-Process '$URL'"
elif BROWSER_BIN="$(find_browser)"; [ -n "$BROWSER_BIN" ]; then
  "$BROWSER_BIN" "$URL" >/dev/null 2>&1 &
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$URL" >/dev/null 2>&1 &
elif command -v open >/dev/null 2>&1; then
  open "$URL" >/dev/null 2>&1 &
else
  echo "no browser launcher found" >&2
  exit 1
fi

echo "{\"ok\":true,\"action\":\"$ACTION\",\"url\":\"$URL\"}"
