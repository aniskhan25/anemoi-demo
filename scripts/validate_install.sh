#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${ROOT_DIR}/logs/validation"
mkdir -p "${LOG_DIR}"

set +e
"${ROOT_DIR}/scripts/lumi_exec.sh" \
  bash -lc "cd '${ROOT_DIR}/configs' && command -v anemoi-training && anemoi-training train --config-name=debug" \
  > "${LOG_DIR}/debug-startup.log" 2>&1
status=$?
set -e

cat <<EOF
Validation command finished with exit code ${status}.
Inspect ${LOG_DIR}/debug-startup.log.
Expected pre-data behavior: the command reaches config validation and fails
only because required data or graph values are unresolved.
EOF
