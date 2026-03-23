# Checklist

## Environment Bring-Up

- [ ] Validate the LUMI container runtime with [env/install.sh](/Users/anisrahm/Documents/anemoi-demo/env/install.sh).
- [ ] Confirm `anemoi-training` is available inside the container.
- [ ] Record container path, module state, and LUMI paths in `notes/environment.md`.
- [ ] Submit [jobs/validate_minimal.slurm](/Users/anisrahm/Documents/anemoi-demo/jobs/validate_minimal.slurm).

## Minimal Data Path

- [ ] Pick the smallest valid dataset source.
- [ ] Record dataset identity, size, and path in [notes/run-metadata-template.md](/Users/anisrahm/Documents/anemoi-demo/notes/run-metadata-template.md).
- [ ] Verify the dataset resolution value needed by the training config.

## Graph Selection

- [ ] Choose an existing graph definition or precomputed graph file.
- [ ] Record whether the graph is reused or generated on the fly.
- [ ] Verify graph and dataset compatibility before the full run.

## Minimal Training Config

- [ ] Fill in every `???` in [configs/training-minimal.yaml](/Users/anisrahm/Documents/anemoi-demo/configs/training-minimal.yaml).
- [ ] Keep `hardware.num_gpus_per_node=1` unless a larger count is required to run at all.
- [ ] Keep batch sizes and batch limits small for the first pass.

## First Successful Run

- [ ] Run the smoke test through [jobs/validate_minimal.slurm](/Users/anisrahm/Documents/anemoi-demo/jobs/validate_minimal.slurm).
- [ ] Run the full minimal job with [jobs/train_minimal.slurm](/Users/anisrahm/Documents/anemoi-demo/jobs/train_minimal.slurm).
- [ ] Confirm logs are written under `logs/`.
- [ ] Confirm at least one checkpoint is produced.
- [ ] Save the exact command, config, and output paths in [notes/run-metadata-template.md](/Users/anisrahm/Documents/anemoi-demo/notes/run-metadata-template.md).
