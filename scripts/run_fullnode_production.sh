#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export ANEMOI_DISTRIBUTED_STRATEGY="${ANEMOI_DISTRIBUTED_STRATEGY:-ddp}"

case "${ANEMOI_DISTRIBUTED_STRATEGY}" in
  ddp)
    export ANEMOI_CONFIG_NAME="${ANEMOI_CONFIG_NAME:-training-fullnode.yaml}"
    ;;
  fsdp)
    export ANEMOI_CONFIG_NAME="${ANEMOI_CONFIG_NAME:-training-fullnode-fsdp.yaml}"
    ;;
  *)
    echo "Unsupported distributed strategy '${ANEMOI_DISTRIBUTED_STRATEGY}'. Supported values: ddp, fsdp." >&2
    exit 1
    ;;
esac

export ANEMOI_NODES="${ANEMOI_NODES:-${SLURM_NNODES:-8}}"
export ANEMOI_GPUS_PER_NODE="${ANEMOI_GPUS_PER_NODE:-8}"
export ANEMOI_BATCH_SIZE="${ANEMOI_BATCH_SIZE:-8}"
export ANEMOI_TRAIN_LIMIT="${ANEMOI_TRAIN_LIMIT:-500}"
export ANEMOI_VAL_LIMIT="${ANEMOI_VAL_LIMIT:-1}"
export ANEMOI_MAX_EPOCHS="${ANEMOI_MAX_EPOCHS:-1}"
export ANEMOI_STAGE_DATA="${ANEMOI_STAGE_DATA:-1}"
export ANEMOI_STAGE_GRAPH="${ANEMOI_STAGE_GRAPH:-1}"
export ANEMOI_OUTPUT_ROOT="${ANEMOI_OUTPUT_ROOT:-${ROOT_DIR}/logs/output/${SLURM_JOB_ID:-interactive}}"

exec bash "${ROOT_DIR}/scripts/run_fullnode_interactive.sh"
