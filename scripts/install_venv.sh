#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/env/lumi-env.sh"

module purge
module use /appl/local/laifs/modules
module load lumi-aif-singularity-bindings

mkdir -p "${ANEMOI_DATA_ROOT}" "${ANEMOI_GRAPH_ROOT}" "${ANEMOI_OUTPUT_ROOT}" "$(dirname "${ANEMOI_VENV}")"

singularity exec "${CONTAINER}" bash -lc "
set -euo pipefail
python3 -m venv '${ANEMOI_VENV}' --system-site-packages
'${ANEMOI_VENV}/bin/python' -m pip install --upgrade pip setuptools wheel
'${ANEMOI_VENV}/bin/python' -m pip install -r '${ROOT_DIR}/env/requirements.txt'
"
