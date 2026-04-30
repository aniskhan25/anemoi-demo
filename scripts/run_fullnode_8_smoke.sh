#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export ANEMOI_NODES=8
export ANEMOI_GPUS_PER_NODE=8
export ANEMOI_BATCH_SIZE="${ANEMOI_BATCH_SIZE:-8}"
export ANEMOI_TRAIN_LIMIT="${ANEMOI_TRAIN_LIMIT:-50}"
export ANEMOI_VAL_LIMIT="${ANEMOI_VAL_LIMIT:-2}"
export ANEMOI_MAX_EPOCHS="${ANEMOI_MAX_EPOCHS:-1}"

exec "${ROOT_DIR}/scripts/run_fullnode_interactive.sh"
