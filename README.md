# Anemoi Minimal Example On LUMI-G

Anemoi is ECMWF's framework for developing and training data-driven weather models. It covers the end-to-end stack around datasets, graphs, models, training, and inference, with `anemoi-training` providing the Hydra- and PyTorch-Lightning-based training workflow.

This repository is a minimal LUMI-G example for running Anemoi training inside the container defined in the upstream [`env.sh`](https://github.com/aniskhan25/LUMI-AI-Guide/blob/main/env.sh). The goal here is narrow: use one existing graph, one valid dataset, and one small config to launch a real training run that writes logs and a checkpoint on LUMI-G.

## What This Repo Contains

1. A LUMI container environment file in [env/lumi-env.sh](/Users/anisrahm/Documents/anemoi-demo/env/lumi-env.sh).
2. A runtime validation script in [env/install.sh](/Users/anisrahm/Documents/anemoi-demo/env/install.sh).
3. A minimal user config in [configs/training-minimal.yaml](/Users/anisrahm/Documents/anemoi-demo/configs/training-minimal.yaml).
4. LUMI-only helper scripts in `scripts/`.
5. A short runbook and checklist in `notes/`.

Every execution script in this repository assumes the LUMI container runtime. There is no separate local-machine execution path.

## Layout

```text
anemoi-demo/
  README.md
  .gitignore
  env/
    install.sh
    lumi-env.sh
  jobs/
    validate_minimal.slurm
    train_minimal.slurm
  configs/
    training-minimal.yaml
  data/
    README.md
  logs/
    .gitkeep
  notes/
    issues.md
    checklist.md
    run-metadata-template.md
    runbook.md
  scripts/
    lumi_exec.sh
    run_smoke.sh
    run_train.sh
    validate_install.sh
```

## Prerequisites

- You have access to LUMI-G.
- You can submit Slurm jobs to `dev-g`, `small-g`, or another LUMI-G partition appropriate for your project.
- The container path in [env/lumi-env.sh](/Users/anisrahm/Documents/anemoi-demo/env/lumi-env.sh) is valid on your system.
- You have a valid Anemoi dataset and graph file to point the config at.

## Configure The Minimal Example

Edit [configs/training-minimal.yaml](/Users/anisrahm/Documents/anemoi-demo/configs/training-minimal.yaml) and replace:

- `data.resolution`
- `hardware.files.dataset`
- `hardware.files.graph`

The root directories for data, graphs, and outputs come from [env/lumi-env.sh](/Users/anisrahm/Documents/anemoi-demo/env/lumi-env.sh).

## Commands To Run On LUMI

```bash
git clone <your-repo-url> anemoi-demo
cd anemoi-demo
sbatch jobs/validate_minimal.slurm
```

Submit the short training run after the validation job succeeds:

```bash
cd anemoi-demo
sbatch jobs/train_minimal.slurm
```

Inspect job output with:

```bash
squeue --me
tail -f logs/slurm-validate-<jobid>.out
tail -f logs/slurm-<jobid>.out
```

## Expected Outputs

- logs under `${ANEMOI_OUTPUT_ROOT}`
- at least one training checkpoint
- a captured environment record in `notes/environment.md`
- a completed run record in [notes/run-metadata-template.md](/Users/anisrahm/Documents/anemoi-demo/notes/run-metadata-template.md)
