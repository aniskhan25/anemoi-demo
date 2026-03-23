#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/env/lumi-env.sh"

if command -v singularity >/dev/null 2>&1; then
  CONTAINER_RUNNER=(singularity exec)
elif command -v apptainer >/dev/null 2>&1; then
  CONTAINER_RUNNER=(apptainer exec)
else
  echo "Neither singularity nor apptainer is available on PATH." >&2
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

"${CONTAINER_RUNNER[@]}" "${extra_flags[@]}" "${CONTAINER}" "$@"
