#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/env/lumi-env.sh"

if command -v singularity >/dev/null 2>&1; then
  CONTAINER_RUNNER="singularity"
elif command -v apptainer >/dev/null 2>&1; then
  CONTAINER_RUNNER="apptainer"
else
  echo "Neither singularity nor apptainer is available on PATH." >&2
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
  "${ANEMOI_OUTPUT_ROOT}" \
  "${ROOT_DIR}/logs/validation"

{
  echo "# Environment Capture"
  echo
  echo "Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "Runtime: LUMI container"
  echo "Container runner: ${CONTAINER_RUNNER}"
  echo "Container: ${CONTAINER}"
  echo "Project account: ${PROJECT_ACCOUNT}"
  echo "Project root: ${PROJECT_ROOT}"
  echo "Scratch root: ${SCRATCH_ROOT}"
  echo "Repo root: ${ANEMOI_DEMO_ROOT}"
  echo "Data root: ${ANEMOI_DATA_ROOT}"
  echo "Graph root: ${ANEMOI_GRAPH_ROOT}"
  echo "Output root: ${ANEMOI_OUTPUT_ROOT}"
  echo
  echo "## Module state"
  if type module >/dev/null 2>&1; then
    module list 2>&1 || true
  else
    echo "No module command available in this shell."
  fi
} > "${ROOT_DIR}/notes/environment.md"

cat <<EOF
Validated container prerequisites for LUMI.
Captured environment details in notes/environment.md
EOF
