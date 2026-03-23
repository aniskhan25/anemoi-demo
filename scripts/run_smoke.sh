#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/env/lumi-env.sh"
extra_args=""

if (($#)); then
  printf -v extra_args ' %q' "$@"
fi

"${ROOT_DIR}/scripts/lumi_anemoi_exec.sh" \
  bash -lc "cd '${ROOT_DIR}/configs' && '${ANEMOI_VENV}/bin/anemoi-training' train --config-name=training-minimal.yaml dataloader.limit_batches.training=1 dataloader.limit_batches.validation=1 hardware.num_gpus_per_node=1${extra_args}"
