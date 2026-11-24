#!/usr/bin/env bash
# macOS / Linux 用の起動スクリプト
#   ./run_game.sh        通常起動
#   ./run_game.sh 10     デバッグモードでステージ10から開始
#   ./run_game.sh debug  デバッグモード
#   ./run_game.sh edit   エディタで開く
# Godot は $GODOT、PATH の godot、/Applications/Godot.app の順で探します。
set -e
cd "$(dirname "$0")"
G="${GODOT:-}"
[ -z "$G" ] && command -v godot >/dev/null && G="$(command -v godot)"
[ -z "$G" ] && [ -x /Applications/Godot.app/Contents/MacOS/Godot ] && G=/Applications/Godot.app/Contents/MacOS/Godot
if [ -z "$G" ]; then echo "Godot 4 が見つかりません。https://godotengine.org/download/ から入手し、GODOT=パス を指定してください。"; exit 1; fi
case "${1:-}" in
  "") exec "$G" --path . ;;
  edit) exec "$G" -e --path . ;;
  debug) exec "$G" --path . -- --debug ;;
  *) exec "$G" --path . -- --stage="$1" ;;
esac
