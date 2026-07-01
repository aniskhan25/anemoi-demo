# Anemoi Minimal Example on LUMI-G

A minimal, practical example of running Anemoi training on LUMI-G using the
prebuilt Anemoi container. The full Anemoi stack is baked into the container, so
there is no per-run virtual environment to create.

## Prerequisites

- Access to LUMI-G and a project account
- The Anemoi container built at `${CONTAINER}` (see
  [Extending-containers-on-LUMI](https://github.com/aniskhan25/Extending-containers-on-LUMI),
  branch `feature/anemoi-lumi`). It bakes in the pinned release set:
  - `anemoi-training==0.14.0`, `anemoi-models==0.16.0`, `anemoi-graphs==0.9.4`
  - on PyTorch 2.10 + ROCm 7.0, venv at `/opt/anemoi-venv`

## Setup

```bash
git clone https://github.com/aniskhan25/anemoi-demo
cd anemoi-demo
source env/lumi-env.sh
```

`env/lumi-env.sh` defines everything the jobs need, defaulting to the baked-in
container so no manual exports are required:

- `CONTAINER` → `/scratch/${PROJECT_ACCOUNT}/${LUMI_USER}/anemoi-lumi.sif`
- `ANEMOI_VENV` → `/opt/anemoi-venv`
- `ANEMOI_DATA_ROOT`, `ANEMOI_GRAPH_ROOT`, `ANEMOI_OUTPUT_ROOT`

Override any of them by exporting before `source` if your paths differ.

## Fetch the sample dataset

```bash
mkdir -p "${ANEMOI_DATA_ROOT}" "${ANEMOI_GRAPH_ROOT}"
curl -L https://data.ecmwf.int/anemoi-datasets/era5-o48-2020-2021-6h-v1.zip \
  -o "${ANEMOI_DATA_ROOT}/era5-o48-2020-2021-6h-v1.zip"
```

The graph is created at runtime from the config on the first run.

## Run

Each step is a short smoke test; run them in order. All validation jobs target
`dev-g`.

```bash
sbatch jobs/validate_minimal.sh    # 1 GPU  — smallest smoke test
sbatch jobs/validate_multigpu.sh   # 2 GPU  — data-parallel (DDP)
sbatch jobs/validate_multinode.sh  # 2 nodes — multi-node startup
```

Once a validation passes, submit its full counterpart:

```bash
sbatch jobs/train_minimal.sh
sbatch jobs/train_multigpu.sh
sbatch jobs/train_multinode.sh
```

Success looks like: the container starts, the dataset loads, the graph and model
initialize, the run reaches `Trainer.fit stopped: max_epochs reached`, and
checkpoints appear under `${ANEMOI_OUTPUT_ROOT}`.

## Configs

The configs in `configs/` target the anemoi-training **0.14.0** schema:

- `system.hardware.{num_gpus_per_node,num_nodes,num_gpus_per_model}` — placement
- `system.input.{dataset,graph}` — full paths to the dataset and graph
- `system.output.root` — output directory
- `training.optimization.lr` — learning rate
- `task: forecaster` — the training task

`training-minimal.yaml` is wired for the sample ERA5 dataset out of the box.

## Full-node workflow

Full-node runs (8+ nodes) are a separate workflow using
`configs/training-fullnode*.yaml` and `standard-g` (beyond `dev-g`'s 2-node
limit). See `notes/fullnode-startup-debug.md` for the bring-up procedure and
`ROADMAP.md` for status.
