# Anemoi Minimal Example On LUMI-G

This repository is a minimal, practical example of how to run one Anemoi training job on LUMI-G with the smallest workable setup.

## What You Need

- access to LUMI-G
- a working project account
- the container path from `env/lumi-env.sh`
- one valid dataset
- a writable graph output location

## Repository Layout

```text
anemoi-demo/
  README.md
  configs/
    training-minimal.yaml
  env/
    lumi-env.sh
    requirements.txt
  jobs/
    validate_minimal.sh
    train_minimal.sh
  scripts/
    install_venv.sh
```

## Step 1: Clone The Repository

```bash
git clone https://github.com/aniskhan25/anemoi-demo
cd anemoi-demo
```

## Step 2: Load The Environment

```bash
source env/lumi-env.sh
```

This defines:

- `CONTAINER`
- `ANEMOI_DATA_ROOT`
- `ANEMOI_GRAPH_ROOT`
- `ANEMOI_OUTPUT_ROOT`
- `ANEMOI_VENV` (defaults to `${SCRATCH_ROOT}/anemoi-demo/.venv`)

## Step 3: Create The Python Environment

Use a short interactive GPU allocation, then run:

```bash
salloc --account=project_462000131 --partition=small-g   --nodes=1 --gpus-per-node=1 --ntasks=1 --cpus-per-task=7   --mem-per-gpu=60G --time=00:15:00
```

Inside that allocation:

```bash
cd /path/to/anemoi-demo
./scripts/install_venv.sh
```

The pinned requirements install Anemoi Training from the official `ecmwf/anemoi-core` git source, pin `zarr<3`, and add `trimesh` plus `pyshtools`. The install script only creates the venv and installs those requirements; the validation job is the runtime check.

## Step 4: Fetch The Sample Dataset

```bash
source env/lumi-env.sh
mkdir -p "${ANEMOI_DATA_ROOT}" "${ANEMOI_GRAPH_ROOT}"
curl -L https://data.ecmwf.int/anemoi-datasets/era5-o48-2020-2021-6h-v1.zip   -o "${ANEMOI_DATA_ROOT}/era5-o48-2020-2021-6h-v1.zip"
```

## Step 5: Minimal Config

`configs/training-minimal.yaml` is already wired for the sample dataset and a runtime-generated graph:

- `data.resolution = o48`
- `system.input.dataset = /scratch/project_462000131/anisrahm/anemoi-demo/data/era5-o48-2020-2021-6h-v1.zip`
- `system.input.graph = /project/project_462000131/anisrahm/anemoi-demo/graphs/first_graph_o48.pt`
- `training.max_epochs = 4`
- `diagnostics.plot.callbacks = []`

## Step 6: Submit The Validation Job

```bash
sbatch jobs/validate_minimal.sh
```

This runs a tiny training job with very small batch limits so it acts as a smoke test.

What success looks like:

- the container starts
- the Anemoi CLI is found
- dataset loading starts
- graph and model initialization start
- the run finishes within the short validation wall time
- checkpoints are written under `${ANEMOI_OUTPUT_ROOT}`

## Step 7: Submit The Full Minimal Job

```bash
sbatch jobs/train_minimal.sh
```

## Common Failure Modes

- `anemoi-training: command not found`
  Re-run `scripts/install_venv.sh`.

- `ModuleNotFoundError` for `trimesh` or `pyshtools`
  Re-run `scripts/install_venv.sh`.

- `AttributeError: module 'zarr.storage' has no attribute 'BaseStore'`
  Re-run `scripts/install_venv.sh`. The repo pins `zarr<3`.

- `Configured container was not found`
  Check `env/lumi-env.sh`.

- dataset or graph path errors
  Check `configs/training-minimal.yaml` and confirm the files exist under `${ANEMOI_DATA_ROOT}` and `${ANEMOI_GRAPH_ROOT}`.
