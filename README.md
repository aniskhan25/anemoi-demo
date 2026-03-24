# Anemoi Minimal Example On LUMI-G

This repository is a small, practical example of how to run [Anemoi](https://anemoi.readthedocs.io/) training on LUMI-G.

Anemoi is ECMWF's framework for machine-learning weather models. In practice, for this repo, that means:

- a dataset
- a graph definition
- a Hydra config
- the `anemoi-training` CLI
- a container-based runtime on LUMI

The goal of this repository is narrow: run one real Anemoi training job on LUMI-G with the smallest workable setup, write logs, and produce a checkpoint.

## What You Need Before Starting

- access to LUMI-G
- a working project account
- the LUMI container path from [env/lumi-env.sh](/Users/anisrahm/Documents/anemoi-demo/env/lumi-env.sh)
- one valid dataset
- a writable graph output location (the graph can be built on first run)

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
    lumi_exec.sh
    lumi_anemoi_exec.sh
    validate_install.sh
    run_smoke.sh
    run_train.sh
```

## Step 1: Clone The Repository

Run this on LUMI in a location under `/project` or `/scratch`:

```bash
git clone https://github.com/aniskhan25/anemoi-demo
cd anemoi-demo
```

## Step 2: Load The Shared LUMI Environment

This repository uses the same baseline described in the LUMI guide:

- `module load singularity-AI-bindings`
- `srun singularity exec "$CONTAINER" ...`
- an optional venv layered on top of the base container

Load the shared environment variables:

```bash
source env/lumi-env.sh
```

This defines:

- `CONTAINER`
- `ANEMOI_DATA_ROOT`
- `ANEMOI_GRAPH_ROOT`
- `ANEMOI_OUTPUT_ROOT`
- `ANEMOI_VENV` (defaults to `${SCRATCH_ROOT}/anemoi-demo/.venv`)

If you need a different container, set it before sourcing:

```bash
export CONTAINER=/path/to/your/container.sif
source env/lumi-env.sh
```

## Step 3: Create The Python Environment Once

Do this once before submitting jobs.

The easiest way is to use a short interactive GPU allocation, then create the venv inside the container:

```bash
salloc --account=project_462000131 --partition=small-g \
  --nodes=1 --gpus-per-node=1 --ntasks=1 --cpus-per-task=7 \
  --mem-per-gpu=60G --time=00:15:00
```

Inside that allocation, run:

```bash
cd /path/to/anemoi-demo
source env/lumi-env.sh
module use "${AI_MODULE_PATH}"
module load singularity-AI-bindings

mkdir -p \
  "${ANEMOI_DATA_ROOT}" \
  "${ANEMOI_GRAPH_ROOT}" \
  "${ANEMOI_OUTPUT_ROOT}" \
  "$(dirname "${ANEMOI_VENV}")"

srun singularity exec "${CONTAINER}" bash -lc "
python3 -m venv '${ANEMOI_VENV}' --system-site-packages
'${ANEMOI_VENV}/bin/python' -m pip install --upgrade pip setuptools wheel
'${ANEMOI_VENV}/bin/python' -m pip install -r '$(pwd)/env/requirements.txt'
"
```

The pinned requirements include `zarr<3` because current Anemoi dataset loading still uses the `zarr.storage.BaseStore` API from zarr 2.x.

What this does:

- loads the LUMI container bindings
- creates the output/data/graph directories
- creates a venv at `${ANEMOI_VENV}`
- installs `anemoi-training` into that venv

## Step 4: Verify The Environment

Still in the same allocation, check that GPU access works:

```bash
./scripts/lumi_exec.sh python -c "import torch; print(torch.cuda.is_available(), torch.cuda.device_count())"
```

Check that Anemoi is available from the venv:

```bash
./scripts/lumi_anemoi_exec.sh bash -lc "'${ANEMOI_VENV}/bin/anemoi-training' --help"
```

If this fails, do not submit jobs yet. Fix the environment first.

## Step 5: Fetch The Minimal Sample Dataset And Fill In The Training Config

For the first working example, use the Anemoi documentation sample dataset. Download it into `${ANEMOI_DATA_ROOT}`:

```bash
mkdir -p "${ANEMOI_DATA_ROOT}" "${ANEMOI_GRAPH_ROOT}"
curl -L https://data.ecmwf.int/anemoi-datasets/era5-o48-2020-2021-6h-v1.zip \
  -o "${ANEMOI_DATA_ROOT}/era5-o48-2020-2021-6h-v1.zip"
```

Then set [configs/training-minimal.yaml](/Users/anisrahm/Documents/anemoi-demo/configs/training-minimal.yaml) to:

- `data.resolution = o48`
- `system.input.dataset = /scratch/project_462000131/anisrahm/anemoi-demo/data/era5-o48-2020-2021-6h-v1.zip`
- `system.input.graph = /project/project_462000131/anisrahm/anemoi-demo/graphs/first_graph_o48.pt`

The graph file does not need to exist yet. Anemoi can construct it on first run and write it to the configured filename.

The output root already comes from [env/lumi-env.sh](/Users/anisrahm/Documents/anemoi-demo/env/lumi-env.sh):

- `system.output.root = ${ANEMOI_OUTPUT_ROOT}`

## Step 6: Submit The Validation Job

Once the environment exists and the config placeholders are filled in, submit:

```bash
sbatch jobs/validate_minimal.sh
```

This job runs:

- [scripts/validate_install.sh](/Users/anisrahm/Documents/anemoi-demo/scripts/validate_install.sh)
- [scripts/run_smoke.sh](/Users/anisrahm/Documents/anemoi-demo/scripts/run_smoke.sh)

What success looks like:

- the container starts
- the Anemoi CLI is found
- config parsing works
- dataset loading starts
- graph and model initialization start

Watch the job:

```bash
squeue --me
tail -f logs/slurm-validate-<jobid>.out
tail -f logs/validation/debug-startup.log
```

## Step 7: Submit The Training Job

After validation succeeds, run:

```bash
sbatch jobs/train_minimal.sh
```

This job runs:

- [scripts/validate_install.sh](/Users/anisrahm/Documents/anemoi-demo/scripts/validate_install.sh)
- [scripts/run_train.sh](/Users/anisrahm/Documents/anemoi-demo/scripts/run_train.sh)

Watch the training output:

```bash
squeue --me
tail -f logs/slurm-<jobid>.out
```

## Expected Outputs

After a successful run, you should have:

- logs under `${ANEMOI_OUTPUT_ROOT}`
- at least one checkpoint
- a reproducible config in [configs/training-minimal.yaml](/Users/anisrahm/Documents/anemoi-demo/configs/training-minimal.yaml)
- a run record you can fill in at [notes/run-metadata-template.md](/Users/anisrahm/Documents/anemoi-demo/notes/run-metadata-template.md)

## Common Failure Modes

- `anemoi-training: command not found`
  The venv was not created, or the install failed.

- `Configured container was not found`
  `CONTAINER` in [env/lumi-env.sh](/Users/anisrahm/Documents/anemoi-demo/env/lumi-env.sh) is wrong for your environment.

- GPU count is zero
  You are not inside a GPU allocation, or `singularity-AI-bindings` was not loaded.

- Config placeholder errors
  You did not replace one of the `???` values in [configs/training-minimal.yaml](/Users/anisrahm/Documents/anemoi-demo/configs/training-minimal.yaml).

- Dataset or graph file not found
  The dataset filename in the config does not match what exists under `${ANEMOI_DATA_ROOT}`, or the graph output path is not writable under `${ANEMOI_GRAPH_ROOT}`.

- `AttributeError: module 'zarr.storage' has no attribute 'BaseStore'`
  Your venv picked up zarr 3.x. Reinstall with [env/requirements.txt](/Users/anisrahm/Documents/anemoi-demo/env/requirements.txt), which pins `zarr<3`.
