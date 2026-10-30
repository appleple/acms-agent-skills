#!/bin/sh
# a-blog cms の移行先の版に合わせて、テーマとプラグイン（拡張アプリ）の要修正箇所を洗い出す。
# checks/to-<版>.tsv のチェック定義を読み、themes/（system を除く）と extension/ を grep する。
# config.server.php と private/ は DB の接続情報などを含むため読まない（探索の対象に入れていない）。
# 使い方: sh scan.sh <a-blog cms の設置ディレクトリ> <移行先の版（例 3.2）>
# 終了コード: 0 = 実行できた（検出の有無は問わない）、1 = 引数や設置ディレクトリの誤り、2 = 移行先の版のチェック定義がない
set -eu

script_dir=$(cd "$(dirname "$0")" && pwd)
checks_dir="$script_dir/checks"

list_versions() {
  found=0
  for f in "$checks_dir"/to-*.tsv; do
    [ -f "$f" ] || continue
    v=$(basename "$f" .tsv)
    echo "  ${v#to-}"
    found=1
  done
  [ "$found" -eq 1 ] || echo "  （なし）"
}

if [ "$#" -ne 2 ]; then
  echo "使い方: sh scan.sh <a-blog cms の設置ディレクトリ> <移行先の版（例 3.2）>" >&2
  exit 1
fi

root="${1%/}"
version="$2"
checks="$checks_dir/to-$version.tsv"

if [ ! -d "$root/themes" ]; then
  echo "error: $root に themes/ がない。a-blog cms の設置ディレクトリ（index.php・themes/・extension/ があるディレクトリ）を指定してください" >&2
  exit 1
fi

if [ ! -f "$checks" ]; then
  echo "error: 移行先 $version のチェック定義（checks/to-$version.tsv）がない。用意されている移行先:" >&2
  list_versions >&2
  exit 2
fi

# 探索するディレクトリ。テーマは system を除く（本体のアップデートで置き換わるため）。
theme_dirs=""
for dir in "$root"/themes/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  [ "$name" = "system" ] && continue
  theme_dirs="$theme_dirs ${dir%/}"
done
plugin_dirs=""
[ -d "$root/extension" ] && plugin_dirs="$root/extension"

# テキストのファイルだけを、node_modules・vendor・.git を除いて grep する。
# grep -r と --exclude-dir は POSIX にないため、find で対象を絞る。/dev/null を渡すのはファイル名を必ず出させるため。
search() {
  pattern="$1"
  shift
  [ "$#" -gt 0 ] || return 0
  find "$@" \( -name node_modules -o -name vendor -o -name .git \) -prune -o -type f \
    \( -name '*.html' -o -name '*.htm' -o -name '*.twig' -o -name '*.php' -o -name '*.js' -o -name '*.mjs' \
    -o -name '*.ts' -o -name '*.tsx' -o -name '*.jsx' -o -name '*.vue' -o -name '*.css' -o -name '*.scss' \
    -o -name '*.sass' -o -name '*.less' -o -name '*.yaml' -o -name '*.yml' -o -name '*.json' -o -name '*.xml' \
    -o -name '*.txt' \) ! -name '*.map' ! -name 'package-lock.json' \
    -exec grep -nE -e "$pattern" /dev/null {} + 2>/dev/null |
    cut -d: -f1,2 | sed "s|^$root/||"
}

echo "# a-blog cms Ver. $version への移行チェック"
echo "# 対象: ${root}（themes/ の system 以外と extension/）"
echo "# 検出は文字列の一致による候補。直す前に該当行を開き、各チェックの → の先（T- は acms-upgrade-theme、P- は acms-upgrade-plugin の references）で直し方を確かめる"

tab=$(printf '\t')
summary=""
total=0
line_no=0
while IFS="$tab" read -r id target pattern message section; do
  line_no=$((line_no + 1))
  [ "$line_no" -eq 1 ] && continue
  case "$id" in
    '' | '#'*) continue ;;
  esac

  dirs=""
  case "$target" in
    *theme*) dirs="$dirs $theme_dirs" ;;
  esac
  case "$target" in
    *plugin*) dirs="$dirs $plugin_dirs" ;;
  esac

  # shellcheck disable=SC2086 # dirs は空白区切りのパスの並び（設置ディレクトリに空白がないことを前提とする）
  hits=$(search "$pattern" $dirs)
  if [ -n "$hits" ]; then
    count=$(printf '%s\n' "$hits" | wc -l | tr -d ' ')
  else
    count=0
  fi
  total=$((total + count))
  summary="$summary
$id: $count"

  [ "$count" -eq 0 ] && continue
  echo
  echo "## $id ($target) $count 件"
  echo "$message"
  # section は「<スキル名>: <references のファイル>#<見出し>」の形
  section_skill=${section%%: *}
  section_path=${section#*: }
  echo "→ ${section_skill} の references/${section_path%%#*}「${section_path#*#}」"
  printf '%s\n' "$hits" | sed 's/^/- /'
done < "$checks"

echo
echo "## system テーマと同じパスに置いたファイル（上書き）"
echo "# 移行先の版の themes/system の同じファイルと見比べる。本体側の変更が取り込まれていない可能性がある"
override_list=$(
  for dir in $theme_dirs; do
    find "$dir" \( -name node_modules -o -name vendor -o -name .git \) -prune -o -type f \( -name '*.html' -o -name '*.twig' \) -print |
      while IFS= read -r f; do
        rel="${f#"$dir"/}"
        if [ -f "$root/themes/system/$rel" ]; then
          echo "- ${f#"$root"/}"
        fi
      done
  done
)
if [ -n "$override_list" ]; then
  printf '%s\n' "$override_list"
  overrides=$(printf '%s\n' "$override_list" | wc -l | tr -d ' ')
else
  echo "- なし"
  overrides=0
fi

echo
echo "## 件数"
echo "合計: $total 件（上書き $overrides 件は含まない）"
printf '%s\n' "$summary" | sed '/^$/d'
