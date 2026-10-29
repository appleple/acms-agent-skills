#!/bin/sh
# a-blog cms の設置ディレクトリを受け取り、バージョン・テーマの継承・テンプレートの種類・プラグイン（拡張アプリ）を出力する。
# config.server.php と private/ は DB の接続情報などを含むため読まない。
# 使い方: sh detect.sh <a-blog cms の設置ディレクトリ>
set -eu

root="${1:-.}"
root="${root%/}"
if [ ! -d "$root/themes" ]; then
  echo "error: $root に themes/ がない。a-blog cms の設置ディレクトリ（index.php・themes/・extension/ があるディレクトリ）を指定してください" >&2
  exit 1
fi

# template.yaml から 1 つのキーの値を取り出す（コメント・引用符・前後の空白を除く）。無ければ空文字。
yaml_value() {
  [ -f "$1" ] || return 0
  sed -n "s/^[[:space:]]*$2[[:space:]]*:[[:space:]]*//p" "$1" | head -n 1 |
    sed -e 's/[[:space:]]#.*$//' -e 's/^["'\'']//' -e 's/["'\'']$//' -e 's/[[:space:]]*$//'
}

# テーマ名から継承の順（自分 → 親 → … ）を空白区切りで返す。本体と同じく先頭の「名前@」を 1 つずつ外す。
theme_chain() {
  t="$1"
  chain=""
  while [ -n "$t" ]; do
    chain="$chain $t"
    case "$t" in
      *@*) t=${t#*@} ;;
      *) t="" ;;
    esac
  done
  echo "$chain"
}

echo "## a-blog cms"
version=""
for css in "$root/themes/system/css/acms.css" "$root/themes/system/css/acms.min.css"; do
  [ -f "$css" ] || continue
  version=$(head -n 10 "$css" | sed -n 's/.*@ablogcms\/acms\.css Ver\. \([0-9][0-9.]*\).*/\1/p' | head -n 1)
  if [ -n "$version" ]; then
    echo "version: $version (themes/system/css/$(basename "$css") の先頭コメント)"
    break
  fi
done
if [ -z "$version" ]; then
  # Ver. 3.2.28 以前の acms.css には本体の版が入らないため、配布物にあるファイルで系列だけを判定する。
  # 難読化されるのは Application.php など一部だけで、ファイルの有無は配布版でも確かめられる。
  if [ -f "$root/php/Services/Template/Twig.php" ]; then
    series="3.2"; range="3.2.0〜3.2.28"; marker="php/Services/Template/Twig.php"
  elif [ -f "$root/php/ACMS/GET/Admin/Config/Set/Theme.php" ]; then
    series="3.1"; range="3.1.x"; marker="php/ACMS/GET/Admin/Config/Set/Theme.php"
  elif [ -f "$root/php/ACMS/GET/Admin/Webhook/Index.php" ]; then
    series="3.0"; range="3.0.x"; marker="php/ACMS/GET/Admin/Webhook/Index.php"
  elif [ -d "$root/php" ]; then
    series="2"; range="2.x 以前"; marker="Ver. 3.0 以降のファイルがない"
  else
    series=""; range=""; marker=""
  fi
  if [ -n "$series" ]; then
    echo "version: ${range}（推定。根拠: ${marker}。正確な版は管理画面で確認する）"
  else
    echo "version: 不明（acms.css に版の表記がなく、php/ も見つからない。管理画面で確認する）"
  fi
  case "$series" in
    3.1|3.0|2) echo "warning: Ver. 3.2 未満のため acms-agent-skills の対象外（バージョンを上げるなら acms-upgrade）" ;;
  esac
else
  major=$(echo "$version" | cut -d. -f1)
  minor=$(echo "$version" | cut -d. -f2)
  if [ "$major" -lt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -lt 2 ]; }; then
    echo "warning: Ver. 3.2 未満のため acms-agent-skills の対象外（バージョンを上げるなら acms-upgrade）"
  fi
fi

echo
echo "## themes"
echo "# chain: テンプレートを探す順（最後に system）。template: template.yaml の tpl_twig を子 → 親の順に見た結果"
for dir in "$root"/themes/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  [ "$name" = "system" ] && continue

  chain=$(theme_chain "$name")
  missing=""
  twig=""
  twig_from=""
  for t in $chain; do
    if [ ! -d "$root/themes/$t" ]; then
      missing="$missing $t"
      continue
    fi
    if [ -z "$twig" ]; then
      value=$(yaml_value "$root/themes/$t/template.yaml" tpl_twig)
      if [ -n "$value" ]; then
        twig="$value"
        twig_from="$t/template.yaml"
      fi
    fi
  done

  if [ "$twig" = "enabled" ]; then
    engine="twig (tpl_twig: enabled in $twig_from)"
  elif [ -n "$twig" ]; then
    engine="standard (tpl_twig: $twig in $twig_from)"
  elif find "$dir" -maxdepth 4 -name '*.twig' -not -path '*/node_modules/*' 2>/dev/null | grep -q .; then
    engine="standard? (template.yaml に tpl_twig なし。.twig ファイルがあるので、テーマ設定で Twig を有効にしていないか確認)"
  else
    engine="standard (template.yaml に tpl_twig なし)"
  fi

  echo "- $name"
  echo "  chain:$(echo "$chain" | sed 's/ / > /g' | sed 's/^ > / /') > system"
  echo "  template: $engine"
  if [ -n "$missing" ]; then
    echo "  warning: 親テーマのディレクトリがない:$missing"
  fi
done

echo
echo "## plugins"
echo "# extension/plugins/ の配置のみ。有効かどうかは管理画面（プラグイン（拡張アプリ）の管理）で確認する"
found=0
if [ -d "$root/extension/plugins" ]; then
  for dir in "$root"/extension/plugins/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    if [ -f "$dir/ServiceProvider.php" ]; then
      echo "- $name"
    else
      echo "- $name (ServiceProvider.php がないため、プラグインとして認識されない)"
    fi
    found=1
  done
fi
[ "$found" -eq 1 ] || echo "- なし"
