#!/usr/bin/env bash
# build.sh - Package the Kodi add-on service.abrepeat into dist/service.abrepeat-<version>.zip
# (installable with Kodi "Install from zip file"). The version is read from addon.xml.
set -euo pipefail

usage() { printf 'Usage: %s [-h]\nBuild dist/service.abrepeat-<version>.zip from ./service.abrepeat\n' "${0##*/}"; }
[[ ${1:-} == -h ]] && { usage; exit 0; }
(( $# == 0 )) || { usage >&2; exit 1; }

cd "${BASH_SOURCE[0]%/*}"
addon=service.abrepeat
xml=$(<"$addon/addon.xml")
re='<addon[^>]*version="([^"]+)"'
[[ $xml =~ $re ]] || { echo "version not found in $addon/addon.xml" >&2; exit 1; }
ver=${BASH_REMATCH[1]}
out=dist/$addon-$ver.zip

mkdir -p dist
rm -f "$out"
echo ">> packaging $addon $ver"
zip -r "$out" "$addon" -x '*/__pycache__/*' '*.pyc' | sed 's/^/   /'
echo ">> $out"
