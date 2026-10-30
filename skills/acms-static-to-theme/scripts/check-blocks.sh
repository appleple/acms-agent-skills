#!/bin/sh
# 標準テンプレート（.html / .htm）の開始と終了のコメントの対応を、ファイルごとに機械的に確かめる。
# 対象: BEGIN_MODULE / END_MODULE、BEGIN 名前 / END 名前、BEGIN_IF / ELSE_IF / ELSE / END_IF、
#       BEGIN_SetTemplate / END_SetTemplate、BEGIN_SetRendered / END_SetRendered。バックスラッシュでエスケープしたもの（BEGIN_MODULE\ など）は別に数える。
# 分かること: 閉じ忘れ、名前の綴りの食い違い、入れ子の順番の誤り、ELSE_IF・ELSE の置き場所の誤り、
#             本体が条件分岐として読まない綴り（ELSEIF・BEGINIF など）、
#             静的 HTML に残った「<!-- END 名前 -->」形式の目印のコメント。
# 分からないこと: 変数名やブロック名が実在するか（変数表で確かめる）、Twig の構文（.twig は読まない）。
# 1 つのブロックを複数のファイル（@include の先）にまたがせている場合は誤検出になる。
# ファイルは読むだけで書き換えない。外部通信はしない。
# 使い方: sh check-blocks.sh <テーマのディレクトリ または .html ファイル>...
# 終了コード: 0 = 食い違いなし、1 = 食い違いあり、2 = 使い方の誤り
set -eu
LC_ALL=C
export LC_ALL

if [ $# -lt 1 ]; then
  echo "usage: sh check-blocks.sh <テーマのディレクトリ または .html ファイル>..." >&2
  exit 2
fi

tmp=$(mktemp "${TMPDIR:-/tmp}/acms-check-blocks.XXXXXX")
trap 'rm -f "$tmp"' EXIT
trap 'exit 1' HUP INT TERM

for target in "$@"; do
  if [ ! -e "$target" ]; then
    echo "見つからない: $target" >&2
    exit 2
  fi
done

for target in "$@"; do
  if [ -d "$target" ]; then
    find "$target" \( -name node_modules -o -name .git \) -prune -o \
      -type f \( -name '*.html' -o -name '*.htm' \) -print
  else
    printf '%s\n' "$target"
  fi
done | sort > "$tmp"

if [ ! -s "$tmp" ]; then
  echo "対象の .html / .htm ファイルがない" >&2
  exit 2
fi

status=0
checked=0
while IFS= read -r file; do
  checked=$((checked + 1))
  if ! awk -v f="$file" '
    function problem(ln, msg) { printf "- %s:%d: %s\n", f, ln, msg; bad = 1 }
    function label(i) {
      if (kind[i] ~ /^M/) return "BEGIN_MODULE" esc(i) " " name[i]
      if (kind[i] ~ /^B/) return "BEGIN" esc(i) " " name[i]
      if (kind[i] ~ /^I/) return "BEGIN_IF" esc(i)
      if (kind[i] ~ /^R/) return "BEGIN_SetRendered" esc(i)
      return "BEGIN_SetTemplate" esc(i)
    }
    function esc(i) { return (substr(kind[i], 2, 1) == "e") ? "\\" : "" }
    # 開始を探して閉じる。途中に閉じていないものがあれば報告する
    function close_block(k, nm, ln, word,   i, j) {
      for (i = n; i >= 1; i--) {
        if (kind[i] == k && (nm == "" || name[i] == nm)) break
      }
      if (i < 1) {
        problem(ln, word " に対応する開始がない" (n > 0 ? "（直前に開いているのは " label(n) "、" line[n] " 行目）" : ""))
        return
      }
      for (j = n; j > i; j--) problem(line[j], label(j) " が " word "（" ln " 行目）より前に閉じていない")
      n = i - 1
    }
    {
      # 本体が受け付けない綴り（ELSEIF・BEGINIF など）は条件分岐として扱われず、コメントのまま残る
      if (match($0, /<!--[ \t]*(ELSEIF|ELSE IF|END IF|BEGINIF|BEGIN IF)([ \t\[]|-->)/)) {
        typo = substr($0, RSTART, RLENGTH)
        sub(/^<!--[ \t]*/, "", typo)
        sub(/([ \t\[]|-->)$/, "", typo)
        problem(FNR, typo " は条件分岐として読まれない綴り（BEGIN_IF・ELSE_IF・END_IF と書く）")
      }
      rest = $0
      while (match(rest, /<!--[ \t]*(BEGIN_SetTemplate|END_SetTemplate|BEGIN_SetRendered|END_SetRendered|BEGIN_MODULE|END_MODULE|BEGIN_IF|ELSE_IF|END_IF|ENDIF|ELSE|BEGIN|END)/)) {
        tok = substr(rest, RSTART, RLENGTH)
        rest = substr(rest, RSTART + RLENGTH)
        sub(/^<!--[ \t]*/, "", tok)
        # 本体は ENDIF も END_IF として読む
        if (tok == "ENDIF") tok = "END_IF"
        e = "n"
        c = substr(rest, 1, 1)
        if (c == "\\") { e = "e"; rest = substr(rest, 2); c = substr(rest, 1, 1) }
        # BEGINNER のような別の語は対象外
        if (c != "" && c != " " && c != "\t" && c != "-") continue
        nm = ""
        if (tok == "BEGIN" || tok == "END" || tok == "BEGIN_MODULE" || tok == "END_MODULE") {
          if (match(rest, /^[ \t]+[^ \t]+/)) {
            nm = substr(rest, RSTART, RLENGTH)
            sub(/^[ \t]+/, "", nm)
            sub(/-->.*$/, "", nm)
          }
        }
        shown = tok ((e == "e") ? "\\" : "") (nm != "" ? " " nm : "")
        if (tok == "BEGIN_MODULE" || tok == "BEGIN" || tok == "BEGIN_IF" || tok == "BEGIN_SetTemplate" || tok == "BEGIN_SetRendered") {
          if ((tok == "BEGIN" || tok == "BEGIN_MODULE") && nm == "") { problem(FNR, shown " に名前がない"); continue }
          n++
          if (tok == "BEGIN") kind[n] = "B" e
          if (tok == "BEGIN_MODULE") kind[n] = "M" e
          if (tok == "BEGIN_IF") kind[n] = "I" e
          if (tok == "BEGIN_SetTemplate") kind[n] = "S" e
          if (tok == "BEGIN_SetRendered") kind[n] = "R" e
          name[n] = nm
          line[n] = FNR
        } else if (tok == "ELSE_IF" || tok == "ELSE") {
          if (n < 1 || kind[n] != "I" e) {
            problem(FNR, shown " が BEGIN_IF の直下にない" (n > 0 ? "（直前に開いているのは " label(n) "、" line[n] " 行目）" : ""))
          }
        } else if (tok == "END_IF") {
          close_block("I" e, "", FNR, shown)
        } else if (tok == "END_MODULE") {
          close_block("M" e, nm, FNR, shown)
        } else if (tok == "END_SetTemplate") {
          close_block("S" e, "", FNR, shown)
        } else if (tok == "END_SetRendered") {
          close_block("R" e, "", FNR, shown)
        } else if (tok == "END") {
          if (nm == "") { problem(FNR, shown " に名前がない"); continue }
          close_block("B" e, nm, FNR, shown)
        }
      }
    }
    END {
      for (i = n; i >= 1; i--) problem(line[i], label(i) " が閉じていない")
      exit bad ? 1 : 0
    }
  ' "$file"; then
    status=1
  fi
done < "$tmp"

if [ "$status" -eq 0 ]; then
  echo "食い違いなし（${checked} ファイル）"
else
  echo "上の食い違いを確かめる（${checked} ファイルを検査）。@include の先にまたがるブロックは誤検出のことがある"
fi
exit "$status"
