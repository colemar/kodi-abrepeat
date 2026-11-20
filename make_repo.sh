#!/usr/bin/env bash
# make_repo.sh - Build the Kodi repository site (GitHub Pages content) into ./site:
#   site/index.html                                  browsable by Kodi's File manager
#   site/repository.colemar-<ver>.zip                repository add-on, installed via "Install from zip file"
#   site/repo/addons.xml + addons.xml.md5            index read by the repository add-on
#   site/repo/<addon-id>/<addon-id>-<ver>.zip        packaged add-ons
# With -p it also publishes ./site to the gh-pages branch (force-push, history not kept).
set -euo pipefail

ADDONS=(service.abrepeat repository.colemar)
usage() { printf 'Usage: %s [-h] [-p]\n  -p  publish site/ to the gh-pages branch of origin\n  -h  show this help\n' "${0##*/}"; }

publish=0
while getopts hp o; do
  case $o in h) usage; exit 0 ;; p) publish=1 ;; *) usage >&2; exit 1 ;; esac
done

cd "${BASH_SOURCE[0]%/*}"
rm -rf site; mkdir -p site/repo

version_of() {   # $1 = add-on dir
  local xml re='<addon[^>]*version="([^"]+)"'
  xml=$(<"$1/addon.xml")
  [[ $xml =~ $re ]] || { echo "no version in $1/addon.xml" >&2; exit 1; }
  printf '%s' "${BASH_REMATCH[1]}"
}

idx='<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'$'\n''<addons>'$'\n'
for a in "${ADDONS[@]}"; do
  v=$(version_of "$a")
  echo ">> $a $v"
  mkdir -p "site/repo/$a"
  zip -qr "site/repo/$a/$a-$v.zip" "$a" -x '*/__pycache__/*' '*.pyc'
  for f in icon.png resources/icon.png; do [[ -f $a/$f ]] && cp "$a/$f" "site/repo/$a/icon.png" && break; done
  mapfile -t lines < "$a/addon.xml"
  for l in "${lines[@]}"; do [[ $l == '<?xml'* ]] || idx+="$l"$'\n'; done
done
idx+='</addons>'$'\n'
printf '%s' "$idx" > site/repo/addons.xml
md5sum site/repo/addons.xml | { read -r sum _; printf '%s' "$sum" > site/repo/addons.xml.md5; }

rv=$(version_of repository.colemar)
cp "site/repo/repository.colemar/repository.colemar-$rv.zip" site/
cat > site/index.html <<HTML
<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Colemar Kodi repository</title></head>
<body>
<h1>Colemar Kodi repository</h1>
<p>Add this URL as a source in Kodi's File manager, then "Install from zip file".
See <a href="https://github.com/colemar/kodi-abrepeat">github.com/colemar/kodi-abrepeat</a>.</p>
<a href="repository.colemar-$rv.zip">repository.colemar-$rv.zip</a>
</body></html>
HTML
touch site/.nojekyll
echo ">> site/ ready"

if (( publish )); then
  echo ">> publishing to gh-pages"
  tmp=$(mktemp -d)
  cp -a site/. "$tmp"
  git -C "$tmp" init -q -b gh-pages
  git -C "$tmp" add -A
  git -C "$tmp" -c user.name="$(git config user.name || echo colemar)" -c user.email="$(git config user.email || echo colemar@users.noreply.github.com)" \
      commit -q -m "Repository site $(date -u +%F)"
  git -C "$tmp" push -q -f "$(git remote get-url origin)" gh-pages
  rm -rf "$tmp"
  echo ">> done: https://colemar.github.io/kodi-abrepeat/"
fi
