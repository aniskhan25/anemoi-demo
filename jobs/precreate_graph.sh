#!/bin/bash
#SBATCH --job-name=anemoi-precreate-graph
#SBATCH --account=project_462000131
#SBATCH --partition=dev-g
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus=1
#SBATCH --cpus-per-task=7
#SBATCH --time=00:20:00
#SBATCH --output=logs/slurm-precreate-graph-%j.out

set -euo pipefail

ROOT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"
source "${ROOT_DIR}/env/lumi-env.sh"

module purge
module use /appl/local/laifs/modules
module load lumi-aif-singularity-bindings

mkdir -p "${ROOT_DIR}/logs" "${ANEMOI_GRAPH_ROOT}"

GRAPH_PATH="${ANEMOI_GRAPH_ROOT}/first_graph_o48.pt"

if [[ -f "${GRAPH_PATH}" ]]; then
  echo "Graph already exists at ${GRAPH_PATH}"
  exit 0
fi

exec srun singularity exec "${CONTAINER}" bash -lc "
set -euo pipefail
VENV_SITE=\$('${ANEMOI_VENV}/bin/python' -c 'import site; print(site.getsitepackages()[0])')
export PYTHONNOUSERSITE=1
export PYTHONPATH=\"\${VENV_SITE}\${PYTHONPATH:+:\${PYTHONPATH}}\"
cd '${ROOT_DIR}/configs'
exec '${ANEMOI_VENV}/bin/anemoi-training' train --config-name=training-minimal.yaml \
  training.max_epochs=1 \
  dataloader.limit_batches.training=1 \
  dataloader.limit_batches.validation=1
"
