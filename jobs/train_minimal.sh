#!/bin/bash
#SBATCH --job-name=anemoi-minimal
#SBATCH --account=project_462000131
#SBATCH --partition=small-g
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus=1
#SBATCH --time=00:30:00
#SBATCH --output=logs/slurm-%j.out

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/env/lumi-env.sh"

module use "${AI_MODULE_PATH}"
module load singularity-AI-bindings

exec env -u SLURM_MEM_PER_CPU -u SLURM_MEM_PER_GPU -u SLURM_MEM_PER_NODE -u SLURM_CPUS_PER_TASK -u SLURM_TRES_PER_TASK   srun singularity exec "${CONTAINER}" bash -lc "
set -euo pipefail
VENV_SITE=\$('${ANEMOI_VENV}/bin/python' -c 'import site; print(site.getsitepackages()[0])')
export PYTHONNOUSERSITE=1
export PYTHONPATH="\${VENV_SITE}\${PYTHONPATH:+:\${PYTHONPATH}}"
cd '${ROOT_DIR}/configs'
exec '${ANEMOI_VENV}/bin/anemoi-training' train --config-name=training-minimal.yaml
"
