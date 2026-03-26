#!/usr/bin/env bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export PROJECT_ACCOUNT="${PROJECT_ACCOUNT:-project_462000131}"
export LUMI_USER="${LUMI_USER:-${USER:-anisrahm}}"
export CONTAINER="${CONTAINER:-/appl/local/laifs/containers/lumi-multitorch-u24r64f21m43t29-20260225_144743/lumi-multitorch-full-u24r64f21m43t29-20260225_144743.sif}"

export PROJECT_ROOT="${PROJECT_ROOT:-/project/${PROJECT_ACCOUNT}/${LUMI_USER}}"
export SCRATCH_ROOT="${SCRATCH_ROOT:-/scratch/${PROJECT_ACCOUNT}/${LUMI_USER}}"
export AI_MODULE_PATH="${AI_MODULE_PATH:-/appl/local/laifs/modules}"

export ANEMOI_DEMO_ROOT="${ANEMOI_DEMO_ROOT:-${ROOT_DIR}}"
export ANEMOI_DATA_ROOT="${ANEMOI_DATA_ROOT:-${SCRATCH_ROOT}/anemoi-demo/data}"
export ANEMOI_GRAPH_ROOT="${ANEMOI_GRAPH_ROOT:-${PROJECT_ROOT}/anemoi-demo/graphs}"
export ANEMOI_OUTPUT_ROOT="${ANEMOI_OUTPUT_ROOT:-${SCRATCH_ROOT}/anemoi-demo/logs}"
export ANEMOI_VENV="${ANEMOI_VENV:-${SCRATCH_ROOT}/anemoi-demo/.venv}"
