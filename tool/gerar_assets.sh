#!/usr/bin/env bash
# Lista cada subpasta de assets/web no pubspec.yaml (o Flutter nao recursa sozinho).
set -euo pipefail
cd "$(dirname "$0")/.."
lista=$(find assets/web -type d | sort | sed 's#^#    - #; s#$#/#')
awk -v l="$lista" '
  /ASSETS-WEB-INICIO/ {print; print "  assets:"; print l; skip=1; next}
  /ASSETS-WEB-FIM/ {skip=0}
  !skip {print}' pubspec.yaml > pubspec.tmp && mv pubspec.tmp pubspec.yaml
