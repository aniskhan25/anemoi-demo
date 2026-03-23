#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/env/lumi-env.sh"

if ! type module >/dev/null 2>&1; then
  echo "The module command is not available in this shell." >&2
  exit 1
fi

module use "${AI_MODULE_PATH}"
module load singularity-AI-bindings

if ! command -v singularity >/dev/null 2>&1; then
  echo "singularity is not available after loading singularity-AI-bindings." >&2
  exit 1
fi

if [[ ! -f "${CONTAINER}" ]]; then
  echo "Configured container was not found: ${CONTAINER}" >&2
  exit 1
fi

mkdir -p \
  "${ROOT_DIR}/notes" \
  "${ANEMOI_DATA_ROOT}" \
  "${ANEMOI_GRAPH_ROOT}" \
  "$(dirname "${ANEMOI_VENV}")" \
  "${ANEMOI_OUTPUT_ROOT}" \
  "${ROOT_DIR}/logs/validation"

srun singularity exec "${CONTAINER}" bash -lc "
set -euo pipefail
python3 -m venv '${ANEMOI_VENV}' --system-site-packages
'${ANEMOI_VENV}/bin/python' -m pip install --upgrade pip setuptools wheel
'${ANEMOI_VENV}/bin/python' -m pip install -r '${ROOT_DIR}/env/requirements.txt'
"

ANEMOI_VERSION="$(srun singularity exec "${CONTAINER}" bash -lc "
set -euo pipefail
'${ANEMOI_VENV}/bin/python' -m pip show anemoi-training | awk '/^Version: / {print \$2}'
")"

{
  echo "# Environment Capture"
  echo
  echo "Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "Runtime: LUMI container"
  echo "Runtime launcher: srun singularity exec"
  echo "Container: ${CONTAINER}"
  echo "AI module path: ${AI_MODULE_PATH}"
  echo "Project account: ${PROJECT_ACCOUNT}"
  echo "Project root: ${PROJECT_ROOT}"
  echo "Scratch root: ${SCRATCH_ROOT}"
  echo "Repo root: ${ANEMOI_DEMO_ROOT}"
  echo "Data root: ${ANEMOI_DATA_ROOT}"
  echo "Graph root: ${ANEMOI_GRAPH_ROOT}"
  echo "Output root: ${ANEMOI_OUTPUT_ROOT}"
  echo "Anemoi venv: ${ANEMOI_VENV}"
  echo "anemoi-training version: ${ANEMOI_VERSION}"
  echo
  echo "## Module state"
  module list 2>&1 || true
} > "${ROOT_DIR}/notes/environment.md"

cat <<EOF
Validated container prerequisites for LUMI.
Installed Anemoi into ${ANEMOI_VENV}
Captured environment details in notes/environment.md
EOF
