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

if [[ -n "${SLURM_SUBMIT_DIR:-}" ]]; then
  ROOT_DIR="${SLURM_SUBMIT_DIR}"
else
  ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

if [[ ! -f "${ROOT_DIR}/env/lumi-env.sh" ]]; then
  echo "Could not find repo root from ROOT_DIR=${ROOT_DIR}" >&2
  exit 1
fi

cd "${ROOT_DIR}"

./scripts/validate_install.sh
./scripts/run_train.sh
