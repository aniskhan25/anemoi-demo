#!/usr/bin/env bash

export PROJECT_ACCOUNT="${PROJECT_ACCOUNT:-project_462000131}"
export LUMI_USER="${LUMI_USER:-${USER:-anisrahm}}"
export CONTAINER="${CONTAINER:-/appl/local/laifs/containers/lumi-multitorch-u24r64f21m43t29-20260225_144743/lumi-multitorch-full-u24r64f21m43t29-20260225_144743.sif}"

export ANEMOI_DATA_ROOT="${ANEMOI_DATA_ROOT:-/scratch/${PROJECT_ACCOUNT}/${LUMI_USER}/anemoi-demo/data}"
export ANEMOI_GRAPH_ROOT="${ANEMOI_GRAPH_ROOT:-/project/${PROJECT_ACCOUNT}/${LUMI_USER}/anemoi-demo/graphs}"
export ANEMOI_OUTPUT_ROOT="${ANEMOI_OUTPUT_ROOT:-/scratch/${PROJECT_ACCOUNT}/${LUMI_USER}/anemoi-demo/logs}"
export ANEMOI_VENV="${ANEMOI_VENV:-/scratch/${PROJECT_ACCOUNT}/${LUMI_USER}/anemoi-demo/.venv}"
