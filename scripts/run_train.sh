#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/env/lumi-env.sh"
extra_args=""

if (($#)); then
  printf -v extra_args ' %q' "$@"
fi

"${ROOT_DIR}/scripts/lumi_anemoi_exec.sh" \
  bash -lc "cd '${ROOT_DIR}/configs' && '${ANEMOI_VENV}/bin/anemoi-training' train --config-name=training-minimal.yaml${extra_args}"
