#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/env/lumi-env.sh"

if [[ -z "${SLURM_JOB_ID:-}" ]]; then
  echo "This script must be run inside an active salloc allocation." >&2
  exit 1
fi

ANEMOI_NODES="${ANEMOI_NODES:-${SLURM_NNODES}}"
ANEMOI_GPUS_PER_NODE="${ANEMOI_GPUS_PER_NODE:-8}"
ANEMOI_BATCH_SIZE="${ANEMOI_BATCH_SIZE:-8}"
ANEMOI_TRAIN_LIMIT="${ANEMOI_TRAIN_LIMIT:-500}"
ANEMOI_VAL_LIMIT="${ANEMOI_VAL_LIMIT:-10}"
ANEMOI_MAX_EPOCHS="${ANEMOI_MAX_EPOCHS:-1}"
ANEMOI_CONFIG_NAME="${ANEMOI_CONFIG_NAME:-training-multinode.yaml}"
ANEMOI_DISTRIBUTED_STRATEGY="${ANEMOI_DISTRIBUTED_STRATEGY:-ddp}"
ANEMOI_GPUS_PER_MODEL="${ANEMOI_GPUS_PER_MODEL:-1}"
ANEMOI_READ_GROUP_SIZE="${ANEMOI_READ_GROUP_SIZE:-1}"
ANEMOI_STAGE_ROOT="${ANEMOI_STAGE_ROOT:-/tmp/anemoi-demo}"
ANEMOI_STAGE_DATA="${ANEMOI_STAGE_DATA:-1}"
ANEMOI_STAGE_GRAPH="${ANEMOI_STAGE_GRAPH:-1}"
ANEMOI_DISTRIBUTED_DEBUG="${ANEMOI_DISTRIBUTED_DEBUG:-0}"
ANEMOI_OUTPUT_ROOT="${ANEMOI_OUTPUT_ROOT:-${ROOT_DIR}/logs/output/${SLURM_JOB_ID}}"
ANEMOI_NCCL_DEBUG="${ANEMOI_NCCL_DEBUG:-INFO}"
ANEMOI_NCCL_DEBUG_SUBSYS="${ANEMOI_NCCL_DEBUG_SUBSYS:-COLL}"
ANEMOI_TORCH_DISTRIBUTED_DEBUG="${ANEMOI_TORCH_DISTRIBUTED_DEBUG:-DETAIL}"
ANEMOI_TORCH_FR_BUFFER_SIZE="${ANEMOI_TORCH_FR_BUFFER_SIZE:-20000}"
ANEMOI_TORCH_NCCL_DUMP_ON_TIMEOUT="${ANEMOI_TORCH_NCCL_DUMP_ON_TIMEOUT:-1}"

module purge
module use /appl/local/laifs/modules
module load lumi-aif-singularity-bindings

unset SLURM_MEM_PER_GPU SLURM_MEM_PER_CPU SLURM_MEM_PER_NODE

mkdir -p "${ROOT_DIR}/logs"
mkdir -p "${ANEMOI_OUTPUT_ROOT}"

case "${ANEMOI_DISTRIBUTED_STRATEGY}" in
  ddp)
    ;;
  anemoi-sharded)
    ;;
  fsdp)
    echo "Distributed strategy '${ANEMOI_DISTRIBUTED_STRATEGY}' is reserved for the future sharded full-node path." >&2
    echo "The current repo only supports plain DDP launches. Wire the trainer/backend to FSDP before using this mode." >&2
    exit 1
    ;;
  *)
    echo "Unsupported distributed strategy '${ANEMOI_DISTRIBUTED_STRATEGY}'. Supported values: ddp, anemoi-sharded, fsdp." >&2
    exit 1
    ;;
esac

SHARDING_OVERRIDES=""
if [[ "${ANEMOI_DISTRIBUTED_STRATEGY}" == "anemoi-sharded" ]]; then
  SHARDING_OVERRIDES=" dataloader.read_group_size=${ANEMOI_READ_GROUP_SIZE}"
fi

CPU_BIND="mask_cpu:7e000000000000,7e00000000000000"
CPU_BIND="${CPU_BIND},7e0000,7e000000"
CPU_BIND="${CPU_BIND},7e,7e00"
CPU_BIND="${CPU_BIND},7e00000000,7e0000000000"

echo "Interactive full-node run settings:"
echo "  job_id=${SLURM_JOB_ID}"
echo "  nodes=${ANEMOI_NODES}"
echo "  gpus_per_node=${ANEMOI_GPUS_PER_NODE}"
echo "  batch_size=${ANEMOI_BATCH_SIZE}"
echo "  train_limit=${ANEMOI_TRAIN_LIMIT}"
echo "  val_limit=${ANEMOI_VAL_LIMIT}"
echo "  max_epochs=${ANEMOI_MAX_EPOCHS}"
echo "  config_name=${ANEMOI_CONFIG_NAME}"
echo "  distributed_strategy=${ANEMOI_DISTRIBUTED_STRATEGY}"
echo "  gpus_per_model=${ANEMOI_GPUS_PER_MODEL}"
echo "  read_group_size=${ANEMOI_READ_GROUP_SIZE}"
echo "  graph=${ANEMOI_GRAPH_ROOT}/first_graph_o48.pt"
echo "  dataset=${ANEMOI_DATA_ROOT}/era5-o48-2020-2021-6h-v1.zip"
echo "  stage_root=${ANEMOI_STAGE_ROOT}"
echo "  stage_data=${ANEMOI_STAGE_DATA}"
echo "  stage_graph=${ANEMOI_STAGE_GRAPH}"
echo "  output_root=${ANEMOI_OUTPUT_ROOT}"
echo "  distributed_debug=${ANEMOI_DISTRIBUTED_DEBUG}"

SRC_DATASET="${ANEMOI_DATA_ROOT}/era5-o48-2020-2021-6h-v1.zip"
SRC_GRAPH="${ANEMOI_GRAPH_ROOT}/first_graph_o48.pt"
STAGE_DATA_ROOT="${ANEMOI_STAGE_ROOT}/data"
STAGE_GRAPH_ROOT="${ANEMOI_STAGE_ROOT}/graphs"
STAGE_DATASET="${STAGE_DATA_ROOT}/era5-o48-2020-2021-6h-v1.zip"
STAGE_GRAPH="${STAGE_GRAPH_ROOT}/first_graph_o48.pt"

if [[ "${ANEMOI_STAGE_DATA}" == "1" && ! -f "${SRC_DATASET}" ]]; then
  echo "Dataset not found at ${SRC_DATASET}" >&2
  exit 1
fi

if [[ "${ANEMOI_STAGE_GRAPH}" == "1" && ! -f "${SRC_GRAPH}" ]]; then
  echo "Graph not found at ${SRC_GRAPH}" >&2
  exit 1
fi

if [[ "${ANEMOI_STAGE_DATA}" == "1" || "${ANEMOI_STAGE_GRAPH}" == "1" ]]; then
  echo "Staging inputs once per node into ${ANEMOI_STAGE_ROOT}"
  srun \
    --nodes="${ANEMOI_NODES}" \
    --ntasks-per-node=1 \
    --cpus-per-task=1 \
    bash -lc "
set -euo pipefail
mkdir -p '${STAGE_DATA_ROOT}' '${STAGE_GRAPH_ROOT}'
if [[ '${ANEMOI_STAGE_DATA}' == '1' ]]; then
  cp -f '${SRC_DATASET}' '${STAGE_DATASET}'
fi
if [[ '${ANEMOI_STAGE_GRAPH}' == '1' ]]; then
  cp -f '${SRC_GRAPH}' '${STAGE_GRAPH}'
fi
echo \"\$(hostname) staged inputs under ${ANEMOI_STAGE_ROOT}\"
"
fi

exec srun \
  --nodes="${ANEMOI_NODES}" \
  --ntasks-per-node="${ANEMOI_GPUS_PER_NODE}" \
  --gpus-per-node="${ANEMOI_GPUS_PER_NODE}" \
  --cpus-per-task="${SLURM_CPUS_PER_TASK}" \
  --cpu-bind="${CPU_BIND}" \
  --output="${ROOT_DIR}/logs/step-%j-%t.out" \
  singularity exec "${CONTAINER}" bash -lc "
set -euo pipefail
echo \"\$(date -Is) rank=\${SLURM_PROCID} local_rank=\${SLURM_LOCALID} host=\$(hostname) entering container\"
VENV_SITE=\$('${ANEMOI_VENV}/bin/python' -c 'import site; print(site.getsitepackages()[0])')
export PYTHONNOUSERSITE=1
export PYTHONPATH=\"\${VENV_SITE}\${PYTHONPATH:+:\${PYTHONPATH}}\"
export ANEMOI_OUTPUT_ROOT='${ANEMOI_OUTPUT_ROOT}'
export ANEMOI_DISTRIBUTED_STRATEGY='${ANEMOI_DISTRIBUTED_STRATEGY}'
if [[ '${ANEMOI_STAGE_DATA}' == '1' ]]; then
  export ANEMOI_DATA_ROOT='${STAGE_DATA_ROOT}'
fi
if [[ '${ANEMOI_STAGE_GRAPH}' == '1' ]]; then
  export ANEMOI_GRAPH_ROOT='${STAGE_GRAPH_ROOT}'
fi
if [[ '${ANEMOI_DISTRIBUTED_DEBUG}' == '1' ]]; then
  export NCCL_DEBUG='${ANEMOI_NCCL_DEBUG}'
  export NCCL_DEBUG_SUBSYS='${ANEMOI_NCCL_DEBUG_SUBSYS}'
  export TORCH_DISTRIBUTED_DEBUG='${ANEMOI_TORCH_DISTRIBUTED_DEBUG}'
  export TORCH_FR_BUFFER_SIZE='${ANEMOI_TORCH_FR_BUFFER_SIZE}'
  export TORCH_NCCL_DUMP_ON_TIMEOUT='${ANEMOI_TORCH_NCCL_DUMP_ON_TIMEOUT}'
  echo \"\$(date -Is) rank=\${SLURM_PROCID} distributed debug enabled NCCL_DEBUG=\${NCCL_DEBUG} TORCH_DISTRIBUTED_DEBUG=\${TORCH_DISTRIBUTED_DEBUG}\"
fi
cd '${ROOT_DIR}/configs'
echo \"\$(date -Is) rank=\${SLURM_PROCID} starting anemoi-training\"
exec '${ANEMOI_VENV}/bin/anemoi-training' train --config-name=${ANEMOI_CONFIG_NAME} \
  hardware.num_nodes=${ANEMOI_NODES} \
  hardware.num_gpus_per_node=${ANEMOI_GPUS_PER_NODE} \
  hardware.num_gpus_per_model=${ANEMOI_GPUS_PER_MODEL} \
  training.max_epochs=${ANEMOI_MAX_EPOCHS} \
  dataloader.limit_batches.training=${ANEMOI_TRAIN_LIMIT} \
  dataloader.limit_batches.validation=${ANEMOI_VAL_LIMIT} \
  dataloader.batch_size.training=${ANEMOI_BATCH_SIZE} \
  dataloader.batch_size.validation=${ANEMOI_BATCH_SIZE}${SHARDING_OVERRIDES}
"
