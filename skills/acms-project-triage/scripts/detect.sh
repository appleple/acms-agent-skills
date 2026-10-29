#!/bin/sh
# a-blog cms の設置ディレクトリを受け取り、バージョン・テーマ・テンプレートの種類・拡張アプリを出力する。
# config.server.php と private/ は DB の接続情報などを含むため読まない。
set -eu

root="${1:-.}"
if [ ! -d "$root/themes" ]; then
  echo "error: $root に themes/ がない。a-blog cms の設置ディレクトリを指定してください" >&2
  exit 1
fi

echo "## a-blog cms"
css="$root/themes/system/css/acms.css"
version=""
if [ -f "$css" ]; then
  version=$(head -n 10 "$css" | sed -n 's/.*@ablogcms\/acms\.css Ver\. \([0-9][0-9.]*\).*/\1/p' | head -n 1)
fi
echo "version: ${version:-不明}"
if [ -n "$version" ]; then
  major=$(echo "$version" | cut -d. -f1)
  minor=$(echo "$version" | cut -d. -f2)
  if [ "$major" -lt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -lt 2 ]; }; then
    echo "warning: Ver. 3.2 未満のため acms-agent-skills の対象外"
  fi
fi

echo
echo "## themes"
for dir in "$root"/themes/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  case "$name" in
    system) continue ;;
  esac
  parent="-"
  case "$name" in
    *@*) parent=${name#*@} ;;
  esac
  engine="standard"
  yaml="$dir/template.yaml"
  if [ -f "$yaml" ] && grep -Eq '^[[:space:]]*tpl_twig[[:space:]]*:[[:space:]]*enabled' "$yaml"; then
    engine="twig"
  elif find "$dir" -maxdepth 3 -name '*.twig' -not -path '*/node_modules/*' 2>/dev/null | grep -q .; then
    engine="standard (.twig ファイルあり。管理画面のテーマ設定で Twig が有効か確認)"
  fi
  echo "- $name (parent: $parent, template: $engine)"
done

echo
echo "## extension plugins"
found=0
if [ -d "$root/extension/plugins" ]; then
  for dir in "$root"/extension/plugins/*/; do
    [ -d "$dir" ] || continue
    echo "- $(basename "$dir")"
    found=1
  done
fi
[ "$found" -eq 1 ] || echo "- なし"
