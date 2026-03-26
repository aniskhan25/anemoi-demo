#!/bin/bash
#SBATCH --job-name=anemoi-validate
#SBATCH --account=project_462000131
#SBATCH --partition=small-g
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus=1
#SBATCH --time=00:20:00
#SBATCH --output=logs/slurm-validate-%j.out

set -euo pipefail

ROOT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"
source "${ROOT_DIR}/env/lumi-env.sh"

module purge
module use /appl/local/laifs/modules
module load lumi-aif-singularity-bindings

exec singularity exec "${CONTAINER}" bash -lc "
set -euo pipefail
VENV_SITE=\$('${ANEMOI_VENV}/bin/python' -c 'import site; print(site.getsitepackages()[0])')
export PYTHONNOUSERSITE=1
export PYTHONPATH="\${VENV_SITE}\${PYTHONPATH:+:\${PYTHONPATH}}"
cd '${ROOT_DIR}/configs'
exec '${ANEMOI_VENV}/bin/anemoi-training' train --config-name=training-minimal.yaml   dataloader.limit_batches.training=1   dataloader.limit_batches.validation=1   system.hardware.num_gpus_per_node=1
"
