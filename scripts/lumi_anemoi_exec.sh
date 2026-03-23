#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/env/lumi-env.sh"

"${ROOT_DIR}/scripts/lumi_exec.sh" \
  bash -lc 'set -euo pipefail
test -x "'"${ANEMOI_VENV}"'/bin/python" || { echo "Anemoi venv is missing: '"${ANEMOI_VENV}"'" >&2; exit 1; }
"$@"' \
  bash "$@"
