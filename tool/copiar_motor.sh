#!/usr/bin/env bash
# Copia o motor (repositorio kyanthx-dv/motor) para assets/web. Uso: tool/copiar_motor.sh <pasta-do-motor>
set -euo pipefail
cd "$(dirname "$0")/.."
src="${1:?informe a pasta do repositorio motor}"
rm -rf assets/web && mkdir -p assets/web
for d in core adapters editor projetos libs vendor; do [ -d "$src/$d" ] && cp -r "$src/$d" assets/web/; done
for f in "$src"/*.html "$src"/*.js "$src"/*.json; do [ -f "$f" ] && cp "$f" assets/web/; done
true
