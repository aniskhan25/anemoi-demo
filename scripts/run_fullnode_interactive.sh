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
ANEMOI_STAGE_ROOT="${ANEMOI_STAGE_ROOT:-/tmp/anemoi-demo}"
ANEMOI_STAGE_DATA="${ANEMOI_STAGE_DATA:-1}"
ANEMOI_STAGE_GRAPH="${ANEMOI_STAGE_GRAPH:-1}"

module purge
module use /appl/local/laifs/modules
module load lumi-aif-singularity-bindings

unset SLURM_MEM_PER_GPU SLURM_MEM_PER_CPU SLURM_MEM_PER_NODE

mkdir -p "${ROOT_DIR}/logs"

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
echo "  graph=${ANEMOI_GRAPH_ROOT}/first_graph_o48.pt"
echo "  dataset=${ANEMOI_DATA_ROOT}/era5-o48-2020-2021-6h-v1.zip"
echo "  stage_root=${ANEMOI_STAGE_ROOT}"
echo "  stage_data=${ANEMOI_STAGE_DATA}"
echo "  stage_graph=${ANEMOI_STAGE_GRAPH}"

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
if [[ '${ANEMOI_STAGE_DATA}' == '1' ]]; then
  export ANEMOI_DATA_ROOT='${STAGE_DATA_ROOT}'
fi
if [[ '${ANEMOI_STAGE_GRAPH}' == '1' ]]; then
  export ANEMOI_GRAPH_ROOT='${STAGE_GRAPH_ROOT}'
fi
cd '${ROOT_DIR}/configs'
echo \"\$(date -Is) rank=\${SLURM_PROCID} starting anemoi-training\"
exec '${ANEMOI_VENV}/bin/anemoi-training' train --config-name=training-multinode.yaml \
  hardware.num_nodes=${ANEMOI_NODES} \
  hardware.num_gpus_per_node=${ANEMOI_GPUS_PER_NODE} \
  hardware.num_gpus_per_model=1 \
  training.max_epochs=${ANEMOI_MAX_EPOCHS} \
  dataloader.limit_batches.training=${ANEMOI_TRAIN_LIMIT} \
  dataloader.limit_batches.validation=${ANEMOI_VAL_LIMIT} \
  dataloader.batch_size.training=${ANEMOI_BATCH_SIZE} \
  dataloader.batch_size.validation=${ANEMOI_BATCH_SIZE}
"
