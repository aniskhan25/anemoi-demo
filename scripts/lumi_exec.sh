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

extra_flags=()
if [[ -n "${LUMI_CONTAINER_FLAGS:-}" ]]; then
  read -r -a extra_flags <<< "${LUMI_CONTAINER_FLAGS}"
fi

srun singularity exec "${extra_flags[@]}" "${CONTAINER}" "$@"
