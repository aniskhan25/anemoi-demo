# Runbook

## Goal

Run one minimal Anemoi training job end to end on a controlled single-node setup and capture enough metadata to repeat it exactly.

## Prerequisites

1. Python 3.9 to 3.12.
2. Access to a LUMI node with `singularity` or `apptainer`.
3. The container path from the upstream LUMI guide:
   `lumi-multitorch-full-u24r64f21m43t29-20260225_144743.sif`.
4. One valid Anemoi dataset.
5. One valid graph file or a graph configuration that Anemoi can materialize at runtime.

## Validate The LUMI Runtime

```bash
./env/install.sh
```

## Validate the CLI

```bash
./scripts/validate_install.sh
```

Expected result:

- the container starts;
- the CLI exists inside the container;
- `anemoi-training train --config-name=debug` starts inside the container;
- if it fails, it should fail because the required data and graph paths are unresolved, not because the install is broken.

## Fill In The User Config

Edit [configs/training-minimal.yaml](/Users/anisrahm/Documents/anemoi-demo/configs/training-minimal.yaml) and replace:

- `data.resolution`
- `hardware.files.dataset`
- `hardware.files.graph`

The path roots come from [env/lumi-env.sh](/Users/anisrahm/Documents/anemoi-demo/env/lumi-env.sh), so the main remaining config choices are dataset resolution and the concrete dataset and graph file names.

## Smoke Test

```bash
./scripts/run_smoke.sh
```

Success means:

- config parses;
- dataset opens;
- graph and model initialize;
- first batches load without crashing immediately.

## Full Minimal Run

```bash
./scripts/run_train.sh
```

Success means:

- the run completes its short configured pass;
- logs are written under `logs/`;
- at least one checkpoint exists.

## Capture Metadata

Immediately copy the exact command, resolved config, environment details, dataset identity, graph identity, and output paths into [notes/run-metadata-template.md](/Users/anisrahm/Documents/anemoi-demo/notes/run-metadata-template.md).

## Common Failure Modes

1. Container path is stale or not visible on the current node.
2. `anemoi-training` is missing inside the container or module state is incomplete.
3. Dataset path is correct but `data.resolution` does not match the dataset.
4. Graph file exists but is incompatible with the chosen dataset.
5. The job starts but batch size or GPU count is too aggressive for the machine.
