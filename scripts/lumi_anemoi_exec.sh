#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/env/lumi-env.sh"

"${ROOT_DIR}/scripts/lumi_exec.sh"   bash -lc 'set -euo pipefail
test -x "'"${ANEMOI_VENV}"'/bin/python" || { echo "Anemoi venv is missing: '"${ANEMOI_VENV}"'" >&2; exit 1; }
VENV_SITE=$("'"${ANEMOI_VENV}"'/bin/python" -c "import site; print(site.getsitepackages()[0])")
export PYTHONNOUSERSITE=1
export PYTHONPATH="${VENV_SITE}${PYTHONPATH:+:${PYTHONPATH}}"
"$@"'   bash "$@"
