---
layout: default
---

# Minimal Anemoi Training on LUMI-G

Change only one value:

```bash
export PROJECT_ACCOUNT=project_462000131
```

---

## 1. Create the workspace

```bash
export LUMI_USER="${LUMI_USER:-$USER}"
export ANEMOI_ROOT="/scratch/${PROJECT_ACCOUNT}/${LUMI_USER}/anemoi"
mkdir -p "${ANEMOI_ROOT}"/{configs,jobs}
cd "${ANEMOI_ROOT}"
```

Create `env.sh`:

```bash
cat > env.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

export PROJECT_ACCOUNT="${PROJECT_ACCOUNT:-project_462000131}"
export LUMI_USER="${LUMI_USER:-${USER}}"
export ANEMOI_ROOT="${ANEMOI_ROOT:-/scratch/${PROJECT_ACCOUNT}/${LUMI_USER}/anemoi}"
export CONTAINER="${CONTAINER:-/appl/local/laifs/containers/lumi-multitorch-u24r64f21m43t29-20260225_144743/lumi-multitorch-full-u24r64f21m43t29-20260225_144743.sif}"

export ANEMOI_DATA_ROOT="${ANEMOI_DATA_ROOT:-${ANEMOI_ROOT}/data}"
export ANEMOI_GRAPH_ROOT="${ANEMOI_GRAPH_ROOT:-${ANEMOI_ROOT}/graphs}"
export ANEMOI_OUTPUT_ROOT="${ANEMOI_OUTPUT_ROOT:-${ANEMOI_ROOT}/logs}"
export ANEMOI_VENV="${ANEMOI_VENV:-${ANEMOI_ROOT}/.venv}"
EOF

chmod +x env.sh
source env.sh
ls -lh "$CONTAINER"
```

---

## 2. Install Anemoi into a small venv

Create `requirements.txt`:

```bash
cat > requirements.txt <<'EOF'
git+https://github.com/ecmwf/anemoi-core.git#subdirectory=training
zarr<3
trimesh
pyshtools
EOF
```

Create `install_venv.sh`:

```bash
cat > install_venv.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${ROOT_DIR}/env.sh"

module purge
module use /appl/local/laifs/modules
module load lumi-aif-singularity-bindings

mkdir -p \
  "${ANEMOI_DATA_ROOT}" \
  "${ANEMOI_GRAPH_ROOT}" \
  "${ANEMOI_OUTPUT_ROOT}" \
  "$(dirname "${ANEMOI_VENV}")"

singularity exec "${CONTAINER}" bash -lc "
  set -euo pipefail
  python3 -m venv '${ANEMOI_VENV}' --system-site-packages
  '${ANEMOI_VENV}/bin/python' -m pip install --upgrade pip setuptools wheel
  '${ANEMOI_VENV}/bin/python' -m pip install -r '${ROOT_DIR}/requirements.txt'
"
EOF

chmod +x install_venv.sh
```

Install from a short `dev-g` allocation:

```bash
salloc \
  --account="${PROJECT_ACCOUNT}" \
  --partition=dev-g \
  --nodes=1 \
  --gpus-per-node=1 \
  --ntasks=1 \
  --cpus-per-task=7 \
  --mem-per-gpu=60G \
  --time=00:30:00
```

Inside the allocation:

```bash
cd "${ANEMOI_ROOT}"
./install_venv.sh
exit
```

---

## 3. Download the sample dataset

```bash
cd "${ANEMOI_ROOT}"
source env.sh

curl -L \
  https://data.ecmwf.int/anemoi-datasets/era5-o48-2020-2021-6h-v1.zip \
  -o "${ANEMOI_DATA_ROOT}/era5-o48-2020-2021-6h-v1.zip"

ls -lh "${ANEMOI_DATA_ROOT}/era5-o48-2020-2021-6h-v1.zip"
```

---

## 4. Create the minimal config

Create `configs/training-minimal.yaml`:

```bash
cat > configs/training-minimal.yaml <<'EOF'
defaults:
  - data: zarr
  - dataloader: native_grid
  - diagnostics: evaluation
  - graph: multi_scale
  - model: gnn
  - system: example
  - training: default
  - _self_

config_validation: true

data:
  resolution: o48

system:
  hardware:
    num_gpus_per_node: 1
    num_nodes: 1
    num_gpus_per_model: 1
  output:
    root: ${oc.env:ANEMOI_OUTPUT_ROOT}
  input:
    dataset: ${oc.env:ANEMOI_DATA_ROOT}/era5-o48-2020-2021-6h-v1.zip
    graph: ${oc.env:ANEMOI_GRAPH_ROOT}/first_graph_o48.pt

dataloader:
  num_workers:
    training: 1
    validation: 1
    test: 1
  batch_size:
    training: 1
    validation: 1
    test: 1
  limit_batches:
    training: 8
    validation: 2
    test: 2

training:
  max_epochs: 4
  lr:
    rate: 1.0e-4

diagnostics:
  plot:
    callbacks: []
EOF
```

---

## 5. Create the training job

Create `jobs/train_minimal.sh`:

```bash
cat > jobs/train_minimal.sh <<'EOF'
#!/bin/bash
#SBATCH --job-name=anemoi-train
#SBATCH --account=project_462000131
#SBATCH --partition=small-g
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus=1
#SBATCH --cpus-per-task=7
#SBATCH --time=00:30:00
#SBATCH --output=%x-%j.out

set -euo pipefail

ROOT_DIR="${SLURM_SUBMIT_DIR:-$(cd "$(dirname "$0")"/.. && pwd)}"
cd "${ROOT_DIR}"
source "${ROOT_DIR}/env.sh"

module purge
module use /appl/local/laifs/modules
module load lumi-aif-singularity-bindings

exec singularity exec "${CONTAINER}" bash -lc "
  set -euo pipefail
  VENV_SITE=\$('${ANEMOI_VENV}/bin/python' -c 'import site; print(site.getsitepackages()[0])')
  export PYTHONNOUSERSITE=1
  export PYTHONPATH=\"\${VENV_SITE}\${PYTHONPATH:+:\${PYTHONPATH}}\"
  cd '${ROOT_DIR}/configs'
  exec '${ANEMOI_VENV}/bin/anemoi-training' train --config-name=training-minimal.yaml
"
EOF

sed -i "s/project_462000131/${PROJECT_ACCOUNT}/g" jobs/train_minimal.sh
chmod +x jobs/train_minimal.sh
```

---

## 6. Submit and check

```bash
cd "${ANEMOI_ROOT}"
sbatch jobs/train_minimal.sh
```

Check status:

```bash
squeue -u "$USER"
```

Check the latest log:

```bash
tail -n 100 "$(ls -1t anemoi-train-*.out | head -n 1)"
```

<!-- pages refresh -->
