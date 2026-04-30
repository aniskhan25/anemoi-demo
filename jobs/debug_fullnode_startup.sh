#!/bin/bash
#SBATCH --job-name=anemoi-fullnode-startup
#SBATCH --account=project_462000131
#SBATCH --partition=standard-g
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=8
#SBATCH --gpus-per-node=8
#SBATCH --cpus-per-task=7
#SBATCH --time=01:00:00
#SBATCH --output=logs/slurm-fullnode-startup-%j.out

set -euo pipefail

ROOT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"
source "${ROOT_DIR}/env/lumi-env.sh"

ANEMOI_NODES="${ANEMOI_NODES:-${SLURM_NNODES}}"
ANEMOI_GPUS_PER_NODE="${ANEMOI_GPUS_PER_NODE:-8}"
ANEMOI_BATCH_SIZE="${ANEMOI_BATCH_SIZE:-8}"
ANEMOI_TRAIN_LIMIT="${ANEMOI_TRAIN_LIMIT:-500}"
ANEMOI_VAL_LIMIT="${ANEMOI_VAL_LIMIT:-10}"
ANEMOI_MAX_EPOCHS="${ANEMOI_MAX_EPOCHS:-1}"

module purge
module use /appl/local/laifs/modules
module load lumi-aif-singularity-bindings

unset SLURM_MEM_PER_GPU SLURM_MEM_PER_CPU SLURM_MEM_PER_NODE

mkdir -p "${ROOT_DIR}/logs"

echo "Startup debug settings:"
echo "  nodes=${ANEMOI_NODES}"
echo "  gpus_per_node=${ANEMOI_GPUS_PER_NODE}"
echo "  batch_size=${ANEMOI_BATCH_SIZE}"
echo "  train_limit=${ANEMOI_TRAIN_LIMIT}"
echo "  val_limit=${ANEMOI_VAL_LIMIT}"
echo "  max_epochs=${ANEMOI_MAX_EPOCHS}"
echo "  graph=${ANEMOI_GRAPH_ROOT}/first_graph_o48.pt"
echo "  dataset=${ANEMOI_DATA_ROOT}/era5-o48-2020-2021-6h-v1.zip"

CPU_BIND="mask_cpu:7e000000000000,7e00000000000000"
CPU_BIND="${CPU_BIND},7e0000,7e000000"
CPU_BIND="${CPU_BIND},7e,7e00"
CPU_BIND="${CPU_BIND},7e00000000,7e0000000000"

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
export TORCH_DISTRIBUTED_DEBUG=DETAIL
export NCCL_DEBUG=INFO
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
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
