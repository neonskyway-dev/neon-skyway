#!/bin/sh
# 公開用リポジトリ（読みにくくした dist だけを置く公開リポジトリ）にビルドを出す。
# 元のコードは非公開リポジトリにだけ置き、GitHub Pages はこの公開用リポジトリから配信する。
#   使い方: sh tools/publish.sh
#   公開用リポジトリを変えるとき: PUB_REPO=https://github.com/<owner>/<repo>.git sh tools/publish.sh
set -e
PUB_REPO="${PUB_REPO:-https://github.com/neonskyway-dev/neon-skyway.git}"
cd "$(dirname "$0")/.."
[ -d node_modules ] || npm install
npm run build
if grep -q '__game' dist/index.html; then echo "検証用フックが残っています。中止します" >&2; exit 1; fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone --quiet --depth 1 "$PUB_REPO" "$TMP" 2>/dev/null || { git init --quiet "$TMP"; git -C "$TMP" remote add origin "$PUB_REPO"; }
find "$TMP" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
cp -R dist/. "$TMP"/
touch "$TMP/.nojekyll"
cat > "$TMP/README.md" <<'MD'
# NEON SKYWAY

遊ぶ: https://neonskyway-dev.github.io/neon-skyway/

© 2026 NEON SKYWAY. All rights reserved. 無断での複製・改変・再配布を禁じます。
このリポジトリは公開用のビルドだけを置いています。
MD
cd "$TMP"
git add -A
if git diff --cached --quiet; then echo "変更なし"; exit 0; fi
git -c user.name="NEON SKYWAY" -c user.email="neonskyway-dev@users.noreply.github.com" commit --quiet -m "公開版 $(date +%Y-%m-%d\ %H:%M)"
git push --quiet origin HEAD:main
echo "公開用リポジトリに出しました: $PUB_REPO"
