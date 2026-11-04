#!/bin/sh
# claude.ai の「Skills をアップロード」に入れる zip を、スキルごとに作る。
# zip の直下にスキルのディレクトリを置く。評価シナリオ（evals/）は利用者に要らないので入れない。
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
out="${1:-$root/dist/claude-ai}"

if ! command -v zip >/dev/null 2>&1; then
  echo "error: zip コマンドが見つからない" >&2
  exit 1
fi

mkdir -p "$out"
count=0
for dir in "$root"/skills/*/; do
  [ -f "$dir/SKILL.md" ] || continue
  name=$(basename "$dir")
  rm -f "$out/$name.zip"
  (cd "$root/skills" && zip -qr "$out/$name.zip" "$name" -x "$name/evals/*")
  count=$((count + 1))
done
echo "$count 件の zip を $out に作った"
