#!/bin/sh
# 静的サイト（HTML 一式）のディレクトリを受け取り、a-blog cms のテーマにするための材料を Markdown で出力する。
# 出すもの: ページの一覧、全ページに共通するブロックの候補、リンクの構造（一覧と詳細の候補）、
# 繰り返し構造の候補、フォーム、アセットの参照とパスの形、CSS の中の url()、テンプレートの記法と衝突する箇所、言語。
# ファイル名・クラス名は決め打ちせず、HTML の構造だけから推定する。推定なので、最後は人が確かめる。
# 外部通信はしない。対象のファイルは書き換えない（一時ディレクトリを作り、終了時に消す）。
# 使い方: sh inventory.sh <静的サイトのディレクトリ>
set -eu
LC_ALL=C
export LC_ALL

if [ $# -lt 1 ] || [ ! -d "$1" ]; then
  echo "usage: sh inventory.sh <静的サイトのディレクトリ>" >&2
  exit 1
fi
root=$(cd "$1" && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/acms-inventory.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
trap 'exit 1' HUP INT TERM

# 共通ブロックとみなす割合（%）。全ページの何割に同じ行があれば共通とみなすか
common_ratio="${INVENTORY_COMMON_RATIO:-80}"

# ---- awk の共通関数 -------------------------------------------------------
# attr: タグの行から属性値を取り出す（"…"・'…'・引用符なし）。: や - が前に付く属性（:src、data-src）は対象外
# kind: パスの形（external / root / relative / anchor / other / variable）
# resolve: ページからの参照をサイト内のパスにする（クエリと # を外し、. と .. を解決する）
# trivial: 閉じタグだけの行などの、共通ブロックの判定に使わない行
lib='
function attr(s, name,   ls, p, q, rest, e) {
  ls = tolower(s)
  if (match(ls, "[ \t]" name "=\"")) { q = "\"" }
  else if (match(ls, "[ \t]" name "=\047")) { q = "\047" }
  else if (match(ls, "[ \t]" name "=[^ \t>\"\047]")) {
    rest = substr(s, RSTART + RLENGTH - 1)
    if (match(rest, "[ \t>]")) return substr(rest, 1, RSTART - 1)
    return rest
  } else return ""
  p = RSTART + RLENGTH
  rest = substr(s, p)
  e = index(rest, q)
  if (e == 0) return ""
  return substr(rest, 1, e - 1)
}
function tagname(s) {
  if (match(s, "^<[A-Za-z][A-Za-z0-9-]*")) return tolower(substr(s, 2, RLENGTH - 1))
  return ""
}
function kind(v) {
  if (v == "") return "empty"
  if (index(v, "{") > 0 || index(v, "%{") > 0) return "variable"
  if (v ~ /^(data|mailto|tel|javascript|blob):/) return "other"
  if (index(v, "://") > 0 || substr(v, 1, 2) == "//") return "external"
  if (substr(v, 1, 1) == "#") return "anchor"
  if (substr(v, 1, 1) == "/") return "root"
  return "relative"
}
function dirof(p,   i, d) {
  d = ""
  for (i = length(p); i > 0; i--) if (substr(p, i, 1) == "/") { d = substr(p, 1, i); break }
  return d
}
function normpath(p,   n, a, i, out, k, st) {
  n = split(p, a, "/")
  k = 0
  for (i = 1; i <= n; i++) {
    if (a[i] == "" || a[i] == ".") continue
    if (a[i] == "..") { if (k > 0) k--; continue }
    st[++k] = a[i]
  }
  out = ""
  for (i = 1; i <= k; i++) out = out (i > 1 ? "/" : "") st[i]
  if (substr(p, length(p), 1) == "/" && out != "") out = out "/"
  return out
}
function resolve(page, v,   p) {
  sub(/[?#].*$/, "", v)
  if (substr(v, 1, 1) == "/") p = substr(v, 2)
  else p = dirof(page) v
  if (v == "") return page
  p = normpath(p)
  if (p == "" || substr(p, length(p), 1) == "/") p = p "index.html"
  return p
}
function trivial(l) {
  if (length(l) < 5) return 1
  if (l ~ /^(<\/[A-Za-z0-9-]+>)+$/) return 1
  return 0
}
function short(s, n) {
  gsub(/\|/, "\\|", s)
  gsub(/`/, "\047", s)
  if (length(s) > n) return utf8cut(s, n) "…"
  return s
}
# LC_ALL=C では文字列はバイト列なので、UTF-8 の文字の途中で切らないようにする
function utf8cut(s, n,   t, k, c, need) {
  t = substr(s, 1, n)
  k = 0
  while (length(t) - k > 0 && substr(t, length(t) - k, 1) ~ /[\200-\277]/) k++
  if (length(t) - k <= 0) return t
  c = substr(t, length(t) - k, 1)
  need = 1
  if (c ~ /[\300-\337]/) need = 2
  else if (c ~ /[\340-\357]/) need = 3
  else if (c ~ /[\360-\367]/) need = 4
  if (k + 1 < need) return substr(t, 1, length(t) - k - 1)
  return t
}
'

# ---- ファイルの一覧 --------------------------------------------------------
find "$root" \( -name node_modules -o -name .git \) -prune -o -type f -print |
  awk -v p="$root/" '{ print substr($0, length(p) + 1) }' | sort > "$tmp/files"
grep -E '\.html?$' "$tmp/files" > "$tmp/pages" || true
grep -E '\.css$' "$tmp/files" > "$tmp/cssfiles" || true
total=$(wc -l < "$tmp/pages" | tr -d ' ')
if [ "$total" -eq 0 ]; then
  echo "error: $root に .html / .htm のファイルがない" >&2
  exit 1
fi

# ---- 正規化: 1 行に 1 タグ（タグの間で改行し、空白をまとめる）-------------------
# 圧縮された HTML（ビルドの成果物）も、手書きの HTML も同じ形にそろえる
: > "$tmp/lines.tsv"
while IFS= read -r page; do
  awk -v page="$page" '
    { sub(/\r$/, ""); buf = buf $0 " " }
    END {
      gsub(/\t/, " ", buf)
      gsub(/>[ ]*</, ">\n<", buf)
      n = split(buf, a, "\n")
      k = 0
      for (i = 1; i <= n; i++) {
        l = a[i]; sub(/^ +/, "", l); sub(/ +$/, "", l); gsub(/  +/, " ", l)
        if (l != "") { k++; print page "\t" k "\t" l }
      }
    }' "$root/$page" >> "$tmp/lines.tsv"
done < "$tmp/pages"

top=""
for c in index.html index.htm; do
  if grep -qx "$c" "$tmp/pages"; then top="$c"; break; fi
done
[ -n "$top" ] || top=$(head -n 1 "$tmp/pages")

if [ "$total" -le 3 ]; then
  threshold="$total"
else
  threshold=$(( (total * common_ratio + 99) / 100 ))
fi
[ "$threshold" -ge 2 ] || threshold=2

# 行ごとに、その行を含むページの数
awk -F '\t' "$lib"'
  trivial($3) == 0 { if (!(($3, $1) in seen)) { seen[$3, $1] = 1; cnt[$3]++ } }
  END { for (t in cnt) print cnt[t] "\t" t }' "$tmp/lines.tsv" > "$tmp/linecount.tsv"

# ---- リンク・アセット・フォーム・繰り返しを 1 回の走査で取り出す ------------------
awk -F '\t' -v files="$tmp/files" -v out="$tmp" "$lib"'
  BEGIN {
    while ((getline f < files) > 0) exists[f] = 1
  }
  function exist(p) {
    if (p in exists) return p
    if ((p ".html") in exists) return p ".html"
    if ((p "/index.html") in exists) return p "/index.html"
    return ""
  }
  function asset(page, k, v,   c, r, e) {
    c = kind(v)
    r = ""; e = ""
    if (c == "root" || c == "relative") { r = resolve(page, v); e = (r in exists) ? "yes" : "no" }
    print k "\t" c "\t" v "\t" r "\t" e "\t" page > (out "/assets.tsv")
  }
  function flushrep(   key, i, s) {
    for (key in rep) {
      if (rep[key] < 3) continue
      s = ""
      for (i = 1; i <= nlink; i++) {
        if (linkline[i] >= repfirst[key] && linkline[i] <= replast[key] + 30) { s = s " " linktarget[i] }
      }
      print curpage "\t" rep[key] "\t" key "\t" repline[key] "\t" (s == "" ? "-" : s) "\t" repimg[key] > (out "/repeat.tsv")
    }
    for (key in rep) { delete rep[key]; delete repfirst[key]; delete replast[key]; delete repline[key]; delete repimg[key] }
    nlink = 0
  }
  {
    page = $1; ln = $2 + 0; l = $3
    if (page != curpage) { if (curpage != "") flushrep(); curpage = page; instyle = 0; inform = 0; parentline = "" }
    t = tagname(l)
    if (t == "title" && match(l, /<title[^>]*>[^<]*/)) {
      v = substr(l, RSTART, RLENGTH); sub(/<title[^>]*>/, "", v)
      print page "\t" v > (out "/titles.tsv")
    }
    if (t == "html") { v = attr(l, "lang"); print page "\t" (v == "" ? "-" : v) > (out "/langs.tsv") }
    if (t == "meta" && tolower(attr(l, "name")) == "generator") print attr(l, "content") > (out "/generator.txt")
    if (index(tolower(l), "hreflang=") > 0) print page > (out "/hreflang.txt")
    if (t == "script" && tolower(attr(l, "type")) == "module") print page > (out "/esm.txt")
    if (t == "link") { v = attr(l, "href"); if (v != "") asset(page, "link(" tolower(attr(l, "rel")) ")", v) }
    if (t == "script") { v = attr(l, "src"); if (v != "") asset(page, "script", v) }
    if (t == "img" || t == "source" || t == "video" || t == "audio" || t == "iframe" || t == "embed" || t == "input") {
      v = attr(l, "src"); if (v != "") asset(page, t, v)
      v = attr(l, "srcset")
      if (v != "") {
        n = split(v, ss, ",")
        for (i = 1; i <= n; i++) { s = ss[i]; sub(/^ +/, "", s); sub(/ .*$/, "", s); if (s != "") asset(page, t "(srcset)", s) }
      }
      v = attr(l, "poster"); if (v != "") asset(page, "video(poster)", v)
    }
    if (t == "style") instyle = 1
    if (instyle || index(tolower(l), " style=") > 0) {
      s = l
      while (match(s, /url\([^)]*\)/)) {
        v = substr(s, RSTART + 4, RLENGTH - 5); gsub(/["\047 ]/, "", v)
        if (v != "") asset(page, "style url()", v)
        s = substr(s, RSTART + RLENGTH)
      }
    }
    if (index(tolower(l), "</style>") > 0) instyle = 0
    if (t == "a") {
      v = attr(l, "href")
      c = kind(v)
      if (c == "root" || c == "relative") {
        r = exist(resolve(page, v))
        if (r == "") r = "(missing)" resolve(page, v)
        print page "\t" r "\t" v > (out "/links.tsv")
        linkline[++nlink] = ln; linktarget[nlink] = r
      } else if (c == "anchor") {
        print page > (out "/anchors.txt")
      } else if (c == "external") {
        print page "\t" v > (out "/extlinks.tsv")
      }
    }
    if (t == "form") {
      inform = 1; fields = ""
      faction = attr(l, "action"); fmethod = attr(l, "method"); fenc = attr(l, "enctype")
    }
    if (inform && (t == "input" || t == "select" || t == "textarea" || t == "button")) {
      v = attr(l, "name")
      if (v != "") { ty = attr(l, "type"); fields = fields " " v "(" (t == "input" ? (ty == "" ? "text" : ty) : t) ")" }
    }
    if (inform && index(tolower(l), "</form>") > 0) {
      print page "\t" (faction == "" ? "(なし)" : faction) "\t" kind(faction) "\t" (fmethod == "" ? "get" : tolower(fmethod)) "\t" fenc "\t" fields > (out "/forms.tsv")
      inform = 0
    }
    # 繰り返し構造: 同じタグ・同じ class の開始タグ
    if (t != "" && t !~ /^(html|head|body|meta|link|script|style|svg|path|g|br|hr|span|option|input|label|source|i|b|strong|em|time|small|img|p|h[1-6]|button|title|noscript|template)$/) {
      cl = attr(l, "class")
      key = ""
      key = ""; base = l
      if (cl != "") key = "<" t " class=\"" cl "\">"
      else if (t ~ /^(li|article|tr|dt|dd|figure|section)$/) {
        # class の無い要素は、直前に開いた入れ物（ul・ol・table など）と組にして区別する
        key = (parentline == "" ? "" : parentline " > ") "<" t ">"
        if (parentline != "") base = parentline
      }
      if (t ~ /^(ul|ol|dl|table|tbody|div|section|main|nav)$/) parentline = l
      if (key != "") {
        if (!(key in rep)) { repfirst[key] = ln; repline[key] = base; repimg[key] = 0 }
        rep[key]++; replast[key] = ln
      }
    }
    if (t == "img") { for (key in rep) if (ln - replast[key] <= 30) repimg[key] = 1 }
  }
  END { if (curpage != "") flushrep() }
' "$tmp/lines.tsv"
for f in assets.tsv links.tsv anchors.txt extlinks.tsv forms.tsv repeat.tsv titles.tsv langs.tsv generator.txt hreflang.txt esm.txt; do
  [ -f "$tmp/$f" ] || : > "$tmp/$f"
done

# ---- 出力 ------------------------------------------------------------------
echo "# 静的サイトの棚卸し"
echo
echo "- 対象: \`$(basename "$root")/\`（HTML ${total} ページ、ファイル $(wc -l < "$tmp/files" | tr -d ' ') 個）"
echo "- トップページとみなしたファイル: \`$top\`"
echo "- 共通とみなす基準: ${total} ページ中 ${threshold} ページ以上に同じ行がある"
echo "- 推定の結果なので、テーマに分ける前に実際のファイルで確かめる"
echo

# リンクの集計（ページの役割の推定に使う）
awk -F '\t' -v total="$total" -v thr="$threshold" -v top="$top" -v pages="$tmp/pages" -v titles="$tmp/titles.tsv" \
    -v anchors="$tmp/anchors.txt" -v forms="$tmp/forms.tsv" -v out="$tmp" "$lib"'
  BEGIN {
    while ((getline p < pages) > 0) { np++; plist[np] = p; ispage[p] = 1 }
    FS = "\t"
    while ((getline line < titles) > 0) { split(line, a, "\t"); if (!(a[1] in title)) title[a[1]] = a[2] }
    while ((getline line < anchors) > 0) anc[line]++
    while ((getline line < forms) > 0) { split(line, a, "\t"); hasform[a[1]] = 1 }
  }
  {
    if (substr($2, 1, 9) == "(missing)") { missing[$1 "\t" $3] = 1; next }
    if ($1 == $2) next
    if (!(($1, $2) in e)) { e[$1, $2] = 1; indeg[$2]++; outdeg[$1]++; src[++ne] = $1; dst[ne] = $2; outs[$1] = outs[$1] SUBSEP $2 }
  }
  END {
    # 8 割以上のページからリンクされる先 = グローバルナビゲーション
    nnav = 0
    for (i = 1; i <= np; i++) { p = plist[i]; if (indeg[p] >= thr && total > 3) { isnav[p] = 1; navs = navs " `" p "`" ; nnav++ } }
    # ページ L から同じディレクトリ D の 3 ページ以上へのリンク（ナビゲーションを除く）= 一覧の候補
    for (i = 1; i <= ne; i++) {
      if (isnav[dst[i]]) continue
      d = dirof(dst[i])
      if (dst[i] == d "index.html") continue
      grp[src[i], d]++
      if (!((src[i], d) in seenpair)) { seenpair[src[i], d] = 1; pairs[++npairs] = src[i] SUBSEP d }
      if (!((d, dst[i]) in member)) { member[d, dst[i]] = 1; members[d] = members[d] " " dst[i]; nmember[d]++ }
    }
    # d ごとの最大の件数。その半分以上（かつ 3 以上）を一覧の候補、3 以上で半分未満を「新着・関連の欄」とみなす
    for (i = 1; i <= npairs; i++) {
      split(pairs[i], pd, SUBSEP)
      if (grp[pairs[i]] > maxc[pd[2]]) maxc[pd[2]] = grp[pairs[i]]
    }
    for (i = 1; i <= npairs; i++) {
      split(pairs[i], pd, SUBSEP)
      c = grp[pairs[i]]; d = pd[2]
      if (c < 3) continue
      if (!(d in listdir)) { listdir[d] = 1; dirs[++ndirs] = d }
      if (c * 2 >= maxc[d]) {
        islist[pd[1]] = 1; nlists[d]++
        if (nlists[d] <= 10) lists[d] = lists[d] " `" pd[1] "`(" c ")"
      } else { nrel[d]++; isrel[pd[1]] = 1 }
    }
    # 一覧の続きのページ: 一覧 L からリンクされ、L がリンクしていない d のページへ 2 つ以上リンクし、
    # さらに「L と title が同じ」「d の外（page/2/ など）にある」「自分も一覧の候補」のどれかに当たるもの
    for (i = 1; i <= npairs; i++) {
      split(pairs[i], pd, SUBSEP)
      L = pd[1]; d = pd[2]
      if (!islist[L] || grp[pairs[i]] < 3) continue
      no = split(outs[L], lo, SUBSEP)
      for (j = 1; j <= no; j++) {
        P = lo[j]
        if (P == "" || P == d "index.html" || P == top || ispager[P]) continue
        if (!(title[P] == title[L] || dirof(P) != d || islist[P])) continue
        newc = 0
        nq = split(outs[P], qo, SUBSEP)
        for (k = 1; k <= nq; k++) {
          Q = qo[k]
          if (Q == "" || Q == L || dirof(Q) != d || isnav[Q] || Q == d "index.html") continue
          if (!((L, Q) in e)) newc++
        }
        if (newc >= 2) { ispager[P] = 1; npager[d]++; if (npager[d] <= 10) pagers[d] = pagers[d] " `" P "`" }
      }
    }
    for (i = 1; i <= ndirs; i++) {
      d = dirs[i]
      n = split(members[d], ms, " ")
      for (j = 1; j <= n; j++) if (!islist[ms[j]] && !ispager[ms[j]]) isdetail[ms[j]] = 1
    }
    # ページの役割
    for (i = 1; i <= np; i++) {
      p = plist[i]
      role = ""
      if (p == top) role = "トップ"
      else if (ispager[p]) role = "一覧の続き（2 ページ目以降）の候補"
      else if (islist[p]) role = "一覧の候補"
      else if (isdetail[p]) role = "詳細の候補"
      else if (hasform[p]) role = "フォームのあるページ"
      else role = "固定ページの候補"
      if (hasform[p] && role != "フォームのあるページ") role = role "・フォームあり"
      if (p ~ /(^|\/)_/) role = role "（名前が _ で始まる: URL から直接開けなくなる）"
      prole[p] = role
    }
    print "## ページ"
    print ""
    print "| ファイル | title | 推定の役割 | 被リンク | ページ内リンク(#) |"
    print "|---|---|---|---|---|"
    for (i = 1; i <= np; i++) {
      p = plist[i]
      print "| `" p "` | " short(title[p], 40) " | " prole[p] " | " (indeg[p] + 0) " | " (anc[p] + 0) " |"
    }
    print ""
    print "## リンクの構造"
    print ""
    if (nnav > 0) print "- グローバルナビゲーションの候補（" thr " ページ以上からリンク）:" navs
    else print "- グローバルナビゲーションの候補: なし（ページが少ないか、ページごとにリンクが違う）"
    if (ndirs == 0) print "- 一覧と詳細の候補: なし（同じディレクトリの 3 ページ以上へリンクするページが無い）"
    for (i = 1; i <= ndirs; i++) {
      d = dirs[i]
      n = split(members[d], ms, " ")
      det = 0; ex = ""
      for (j = 1; j <= n; j++) if (isdetail[ms[j]]) { det++; if (det <= 3) ex = ex " `" ms[j] "`" }
      print "- `" (d == "" ? "/" : d) "` の一覧の候補:" lists[d] (nlists[d] > 10 ? " ほか " (nlists[d] - 10) " ページ" : "")
      print "  - 詳細の候補: " det " ページ（例:" (ex == "" ? " なし" : ex) "）"
      if (pagers[d] != "") print "  - 一覧の続き（2 ページ目以降）の候補:" pagers[d] (npager[d] > 10 ? " ほか " (npager[d] - 10) " ページ" : "") "（CMS ではページャーで出すので、テンプレートにしない）"
      if (nrel[d] > 0) print "  - " d " の 3 ページ以上へリンクするが件数の少ないページ: " nrel[d] " ページ（新着・関連記事の欄の候補）"
    }
    orph = ""
    for (i = 1; i <= np; i++) if (plist[i] != top && indeg[plist[i]] == 0) orph = orph " `" plist[i] "`"
    if (orph != "") print "- どこからもリンクされていないページ:" orph
    nm = 0
    for (k in missing) { nm++; if (nm <= 10) { split(k, mk, "\t"); mlist = mlist " `" mk[1] "` → `" mk[2] "`" } }
    if (nm > 0) print "- リンク先のファイルが無いリンク: " nm " 件（例:" mlist "）"
    if (np <= 2 || anc[top] >= 5) print "- トップページにページ内リンク（#）が " (anc[top] + 0) " 個ある。1 ページで完結するサイト（LP など）なら、ページ内のセクションごとに管理する方法を考える"
    print ""
  }
' "$tmp/links.tsv"
# system テーマと同じパス（テーマに置くと本体のエラーページ・サイトマップ・管理画面の部品などを置き換える）
sys=$(grep -E '^((400|403|404|413|500|login|admin|_maintenance|_restore)\.html|(sitemap|rss2)\.xml|(admin|ajax|callback|mail|rpc|_layouts|_member|_member-admin)/.*|include/(unit|layout|check-seo|jsbanner|members-only|gmaps-error|unit-fetch|unit-rss)\.html)$' "$tmp/files" | head -n 10 | awk '{ printf "%s`%s`", (NR > 1 ? ", " : ""), $0 }')
if [ -n "$sys" ]; then
  echo "- a-blog cms の system テーマと同じパスのファイル: $sys（テーマに置くと本体のものの代わりに使われる。本体のものを使うなら、テーマにコピーしない）"
  echo
fi

# 共通ブロック
echo "## 全ページに共通するブロックの候補"
echo
if [ "$total" -lt 2 ]; then
  echo "- ページが 1 つなので判定しない。インクルードに分けるかは、今後ページが増えるかで決める"
else
  awk -F '\t' -v top="$top" -v thr="$threshold" -v counts="$tmp/linecount.tsv" "$lib"'
    BEGIN { while ((getline line < counts) > 0) { i = index(line, "\t"); cnt[substr(line, i + 1)] = substr(line, 1, i - 1) + 0 } }
    $1 == top { n++; L[n] = $3 }
    END {
      body = 0
      for (i = 1; i <= n; i++) if (body == 0 && L[i] ~ /^<body/) body = i
      inrun = 0; nrun = 0
      for (i = 1; i <= n + 1; i++) {
        if (i <= n) st = trivial(L[i]) ? "N" : ((L[i] in cnt) && cnt[L[i]] >= thr ? "C" : "X")
        else st = "END"
        if (i == body && inrun) st = "BREAK"
        if (st == "C") {
          if (!inrun) { inrun = 1; rs = i; rc = 0; gap = 0 }
          rc++; re = i; gap = 0
        } else if (st == "X" || st == "END" || st == "BREAK") {
          if (inrun) { gap++; if (gap > 2 || st != "X") { inrun = 0; if (rc >= 5) { nrun++; RS_[nrun] = rs; RE_[nrun] = re; RC_[nrun] = rc } } }
        }
      }
      if (nrun == 0) { print "- 見つからない（ページごとに構造が違うか、共通部分が短い）"; exit }
      print "`" top "` の中で、" thr " ページ以上に同じ行が続く範囲（タグを 1 行ずつにした行番号）:"
      print ""
      print "| 範囲 | 共通の行数 | 位置 | 最初の行 | 最後の行 |"
      print "|---|---|---|---|---|"
      for (k = 1; k <= nrun; k++) {
        pos = (body > 0 && RS_[k] < body) ? "head の中（CSS・JS の読み込みなど）" : (RS_[k] < n / 2 ? "本文の前（ヘッダー・ナビゲーションの候補）" : "本文の後（フッターの候補）")
        print "| " RS_[k] "–" RE_[k] " | " RC_[k] " | " pos " | `" short(L[RS_[k]], 60) "` | `" short(L[RE_[k]], 60) "` |"
      }
      print ""
      print "- 共通の範囲の中に、ページごとに違う行（title、現在地の印など）が少し混じっていてもまとめている。インクルードに分けるときは、違う部分をグローバル変数やタッチモジュールで出し分ける"
    }' "$tmp/lines.tsv"
fi
echo

# 繰り返し構造
echo "## 繰り返し構造の候補"
echo
if [ ! -s "$tmp/repeat.tsv" ]; then
  echo "- 見つからない（同じタグ・同じ class の要素が 3 個以上並ぶところが無い）"
else
  echo "同じタグ・同じ class の要素が 3 個以上あり、近くにリンクか画像があるもの（ページごとに多い順に 3 つまで）:"
  echo
  echo "| ページ | 個数 | 要素 | 近くのリンク先（例） | 画像 |"
  echo "|---|---|---|---|---|"
  awk -F '\t' -v counts="$tmp/linecount.tsv" -v thr="$threshold" "$lib"'
    BEGIN { while ((getline line < counts) > 0) { i = index(line, "\t"); cnt[substr(line, i + 1)] = substr(line, 1, i - 1) + 0 } }
    ($5 != "-" || $6 == 1) { print }' "$tmp/repeat.tsv" |
    sort -t "$(printf '\t')" -k1,1 -k2,2nr |
    awk -F '\t' -v counts="$tmp/linecount.tsv" -v thr="$threshold" -v total="$total" "$lib"'
      BEGIN { while ((getline line < counts) > 0) { i = index(line, "\t"); cnt[substr(line, i + 1)] = substr(line, 1, i - 1) + 0 } }
      {
        if ($1 != prev) { shown = 0; prev = $1 }
        if ((($4) in cnt) && cnt[$4] >= thr && total > 1) { skipped++; next }
        if (shown >= 3) next
        shown++; rows++
        if (rows > 60) { if (rows == 61) more = 1; next }
        n = split($5, ls, " "); ex = ""; m = 0
        for (i = 1; i <= n && m < 3; i++) if (!(ls[i] in dup)) { dup[ls[i]] = 1; ex = ex " `" ls[i] "`"; m++ }
        for (i = 1; i <= n; i++) delete dup[ls[i]]
        print "| `" $1 "` | " $2 " | `" short($3, 90) "` | " (ex == "" ? "-" : ex) " | " ($6 == 1 ? "あり" : "") " |"
      }
      END {
        if (more) print "\n（61 行目以降は省略）"
        if (skipped) print "\n- 全ページに共通する部分（ナビゲーションなど）の中の繰り返し " skipped " 件は省いた"
      }'
  echo
  echo "- 近くのリンク先が「一覧と詳細の候補」の詳細ページなら、エントリーの一覧として CMS 化する候補。リンクが無く画像だけなら、スライダーやギャラリー（モジュールフィールドやバナー）の候補"
fi
echo

# フォーム
echo "## フォーム"
echo
if [ ! -s "$tmp/forms.tsv" ]; then
  echo "- form 要素は無い"
else
  echo "| ページ | action | action の形 | method | enctype | 入力欄の name（type） |"
  echo "|---|---|---|---|---|---|"
  awk -F '\t' "$lib"'{ print "| `" $1 "` | `" short($2, 50) "` | " $3 " | " $4 " | " ($5 == "" ? "-" : $5) " | " ($6 == "" ? "（name なし）" : short($6, 200)) " |" }' "$tmp/forms.tsv"
  echo
  echo "- action が外部（external）のフォームは、外部のサービスに送っている。a-blog cms のフォームに置き換えるか、そのまま残すかを利用者に確かめる"
  echo "- 入力 → 確認 → 完了の各画面が別の HTML になっていても、a-blog cms では 1 つのテンプレートの中でステップを切り替える（acms-form）"
fi
echo

# アセット
echo "## アセットの参照"
echo
if [ ! -s "$tmp/assets.tsv" ]; then
  echo "- 参照は無い"
else
  echo "パスの形ごとの件数（同じ参照は 1 件と数える）:"
  echo
  echo "| 要素 | root（/ から） | relative（相対） | external（外部） | その他 |"
  echo "|---|---|---|---|---|"
  awk -F '\t' '
    { k = $1; sub(/\(.*$/, "", k); if (k == "style url") k = "style url()"; key = k SUBSEP $2 SUBSEP $3
      if (!(key in seen)) { seen[key] = 1; c[k, $2]++; if (!(k in kk)) { kk[k] = 1; ks[++nk] = k } } }
    END { for (i = 1; i <= nk; i++) { k = ks[i]; o = c[k, "other"] + c[k, "variable"] + c[k, "anchor"]
      print "| " k " | " (c[k, "root"] + 0) " | " (c[k, "relative"] + 0) " | " (c[k, "external"] + 0) " | " o " |" } }' "$tmp/assets.tsv"
  echo
  hosts=$(awk -F '\t' '$2 == "external" { v = $3; sub(/^[a-zA-Z]*:?\/\//, "", v); sub(/[\/?#].*$/, "", v); print v }' "$tmp/assets.tsv" | sort | uniq -c | sort -rn | awk '{ printf "%s`%s`(%s)", (NR > 1 ? ", " : ""), $2, $1 }')
  [ -n "$hosts" ] && echo "- 外部から読み込んでいるホスト: $hosts（CDN の CSS フレームワーク・ライブラリなど。テンプレートでは書き換えられずそのまま出る）"
  miss=$(awk -F '\t' '$5 == "no" { print $3 " (" $6 ")" }' "$tmp/assets.tsv" | sort -u | head -n 10 | awk '{ printf "%s`%s`", (NR > 1 ? ", " : ""), $0 }')
  [ -n "$miss" ] && echo "- ファイルが見つからない参照（最大 10 件）: $miss"
  hashed=$(awk -F '\t' '($2 == "root" || $2 == "relative") && ($1 ~ /^(script|link)/) {
      b = $3; sub(/[?#].*$/, "", b); sub(/^.*\//, "", b)
      if (b !~ /\.(js|mjs|css)$/) next
      sub(/\.[a-z]+$/, "", b); sub(/\.min$/, "", b)
      n = split(b, s, /[-.]/); h = s[n]
      if (n > 1 && length(h) >= 8 && h ~ /^[A-Za-z0-9_]+$/ && h ~ /[0-9]/ && h ~ /[A-Za-z]/) print $3 }' "$tmp/assets.tsv" | sort -u | head -n 5 | awk '{ printf "%s`%s`", (NR > 1 ? ", " : ""), $0 }')
  [ -n "$hashed" ] && echo "- ハッシュ付きのファイル名（ビルドの成果物らしい）: $hashed。ビルドのたびに名前が変わるので、テンプレートに直接書かない方法（ビルドの設定で名前を固定する、Vite なら vite() を使う）を考える"
  rel=$(awk -F '\t' '$2 == "relative" { print $6 }' "$tmp/assets.tsv" | sort -u | wc -l | tr -d ' ')
  if [ "$rel" -gt 0 ]; then
    echo "- 相対パスの参照があるページ: ${rel} ページ。標準テンプレートではテンプレートのファイルの場所が基準になるので、部品をインクルードに分ける（別のディレクトリに移す）前に / から始まるパスにそろえる"
  fi
fi
[ -s "$tmp/generator.txt" ] && echo "- meta generator: $(sort -u "$tmp/generator.txt" | awk '{ printf "%s`%s`", (NR > 1 ? ", " : ""), $0 }')（静的サイトジェネレーターなどの成果物の可能性）"
[ -s "$tmp/esm.txt" ] && echo "- type=\"module\" の script があるページ: $(sort -u "$tmp/esm.txt" | wc -l | tr -d ' ') ページ"
hit=$(grep -E '(^|/)(manifest|asset-manifest)\.json$' "$tmp/files" | head -n 3 | awk '{ printf "%s`%s`", (NR > 1 ? ", " : ""), $0 }')
[ -n "$hit" ] && echo "- ビルドツールのマニフェストらしいファイル: $hit（PWA の manifest のこともある）"
maps=$(grep -c -E '\.map$' "$tmp/files" || true)
[ "$maps" -gt 0 ] && echo "- ソースマップ（.map）: ${maps} 個（公開しないなら、テーマにコピーしない）"
echo

# CSS ファイルの中の url()
echo "## CSS ファイルの中の url()"
echo
if [ ! -s "$tmp/cssfiles" ]; then
  echo "- サイト内に .css ファイルは無い"
else
  : > "$tmp/cssurl.tsv"
  while IFS= read -r css; do
    awk -v css="$css" -v files="$tmp/files" "$lib"'
      BEGIN { while ((getline f < files) > 0) ex[f] = 1 }
      {
        s = $0
        while (match(s, /url\([^)]*\)/)) {
          v = substr(s, RSTART + 4, RLENGTH - 5); gsub(/["\047 ]/, "", v)
          s = substr(s, RSTART + RLENGTH)
          k = kind(v)
          if (k == "root" || k == "relative") { r = resolve(css, v); print css "\t" k "\t" v "\t" ((r in ex) ? "yes" : "no") }
          else if (k != "other") print css "\t" k "\t" v "\t-"
        }
      }' "$root/$css" >> "$tmp/cssurl.tsv"
  done < "$tmp/cssfiles"
  echo "- .css ファイル: $(wc -l < "$tmp/cssfiles" | tr -d ' ') 個。url() の件数: $(awk -F '\t' '$2 == "root" { r++ } $2 == "relative" { l++ } $2 == "external" { e++ } END { printf "root %d / relative %d / external %d", r, l, e }' "$tmp/cssurl.tsv")"
  rootcss=$(awk -F '\t' '$2 == "root" { print $1 " → " $3 }' "$tmp/cssurl.tsv" | sort -u | head -n 10 | awk '{ printf "%s`%s`", (NR > 1 ? ", " : ""), $0 }')
  if [ -n "$rootcss" ]; then
    echo "- **/ から始まる url() があるCSS（a-blog cms は CSS ファイルの中を書き換えないので、テーマに置くと参照が外れる）**: $rootcss"
    echo "  - 直し方: CSS ファイルからの相対パスにする（\`../images/x.png\`）か、テーマの場所を含む絶対パスにする"
  else
    echo "- / から始まる url() は無い（相対パスの url() は CSS ファイルの場所から解決されるので、CSS と画像の位置関係を保ってテーマにコピーすればよい）"
  fi
  cmiss=$(awk -F '\t' '$4 == "no" { print $1 " → " $3 }' "$tmp/cssurl.tsv" | sort -u | head -n 5 | awk '{ printf "%s`%s`", (NR > 1 ? ", " : ""), $0 }')
  [ -n "$cmiss" ] && echo "- ファイルが見つからない url()（最大 5 件）: $cmiss"
fi
echo

# テンプレートの記法との衝突
echo "## テンプレートの記法と衝突しそうな箇所"
echo
: > "$tmp/syntax.tsv"
while IFS= read -r page; do
  awk -v page="$page" '
    function count(s, re,   n) { n = 0; while (match(s, re)) { n++; s = substr(s, RSTART + RLENGTH) } return n }
    {
      tw += count($0, "\\{\\{") + count($0, "\\{%") + count($0, "\\{#")
      br += count($0, "\\{[^{}]+\\}")
      bg += count($0, "<!--[ \t]*(BEGIN|END)[ \t]")
      gv += count($0, "%\\{")
      at += count($0, "@(include|extends|section|vite)\\(")
    }
    END { if (tw + br + bg + gv + at > 0) print page "\t" tw "\t" br "\t" bg "\t" gv "\t" at }' "$root/$page" >> "$tmp/syntax.tsv"
done < "$tmp/pages"
if [ ! -s "$tmp/syntax.tsv" ]; then
  echo "- 見つからない"
else
  echo "| ページ | Twig の区切り（{{ {% {#） | 波括弧 {…} | BEGIN / END のコメント | %{ | @include など |"
  echo "|---|---|---|---|---|---|"
  awk -F '\t' '{ n++; if (n <= 40) print "| `" $1 "` | " $2 " | " $3 " | " $4 " | " $5 " | " $6 " |" } END { if (n > 40) print "\n（" n " ページ中 40 ページまで表示）" }' "$tmp/syntax.tsv"
  echo
  echo "- Twig: {{ {% {# は Twig の構文として読まれる。インラインの CSS・JavaScript（圧縮した CSS の \`){#id\` など）にあるとエラーになるので、{% verbatim %} で囲むか外部ファイルに出す"
  echo "- 標準テンプレート: モジュール（BEGIN_MODULE）で囲んだ範囲の中では、改行を含まない {…} が変数として扱われ、値が無ければ消える（Alpine.js の x-data・:class のオブジェクト、Vue などの {{ }}、インラインの JavaScript の波括弧など）。\\{ \\} とエスケープするか、モジュールの外に出す"
  echo "- 標準テンプレート: モジュールの中の <!-- BEGIN x --> / <!-- END x --> のコメントはブロックとして扱われ、中身ごと消える。HTML のコメントの書き方を変える"
fi
echo

# 言語
echo "## 言語"
echo
langs=$(awk -F '\t' '{ c[$2]++ } END { for (k in c) print c[k] "\t" k }' "$tmp/langs.tsv" | sort -rn | awk -F '\t' '{ printf "%s`%s`(%s)", (NR > 1 ? ", " : ""), $2, $1 }')
nlang=$(awk -F '\t' '{ print $2 }' "$tmp/langs.tsv" | sort -u | grep -vc '^-$' || true)
echo "- html の lang 属性: ${langs:-なし}"
[ -s "$tmp/hreflang.txt" ] && echo "- hreflang があるページ: $(sort -u "$tmp/hreflang.txt" | wc -l | tr -d ' ') ページ"
if [ "$nlang" -gt 1 ]; then
  echo "- 複数の言語がある。言語ごとにディレクトリが分かれていれば、言語ごとに子ブログにする案を検討する（references/site-types.md）"
fi
