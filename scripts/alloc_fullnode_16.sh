#!/usr/bin/env bash
set -euo pipefail

exec salloc \
  --account=project_462000131 \
  --partition=standard-g \
  --nodes=16 \
  --ntasks-per-node=8 \
  --gpus-per-node=8 \
  --cpus-per-task=7 \
  --time=01:00:00
