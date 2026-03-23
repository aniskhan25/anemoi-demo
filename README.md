# Anemoi Minimal Baseline

Phase 1 is scoped to one narrow outcome: run one real Anemoi training job end to end, repeatedly, on a controlled single-node setup.

This workspace is organized around four deliverables:

1. A reproducible LUMI container recipe in [env/install.sh](/Users/anisrahm/Documents/anemoi-demo/env/install.sh).
2. A minimal user config in [configs/training-minimal.yaml](/Users/anisrahm/Documents/anemoi-demo/configs/training-minimal.yaml).
3. A place to capture one successful run and its artifacts under `logs/`.
4. A short rerun guide in [notes/runbook.md](/Users/anisrahm/Documents/anemoi-demo/notes/runbook.md).

## Status

This repository currently contains the Phase 1 scaffold and documentation, not a verified successful Anemoi run yet.

Known local facts:

- Python `3.9.6` is available on this machine.
- The intended runtime is the LUMI container defined in the upstream `env.sh` from `aniskhan25/LUMI-AI-Guide`.
- End-to-end execution has not been validated from this workspace because the current machine is not the target LUMI environment.

## Layout

```text
anemoi-demo/
  README.md
  .gitignore
  env/
    install.sh
    lumi-env.sh
  configs/
    training-minimal.yaml
  data/
    README.md
  logs/
    .gitkeep
  notes/
    issues.md
    phase1-checklist.md
    run-metadata-template.md
    runbook.md
  scripts/
    lumi_exec.sh
    run_smoke.sh
    run_train.sh
    validate_install.sh
```

## Quick Start

1. Review [notes/phase1-checklist.md](/Users/anisrahm/Documents/anemoi-demo/notes/phase1-checklist.md).
2. Validate the LUMI runtime with [env/install.sh](/Users/anisrahm/Documents/anemoi-demo/env/install.sh).
3. Fill in the unresolved values in [configs/training-minimal.yaml](/Users/anisrahm/Documents/anemoi-demo/configs/training-minimal.yaml).
4. Verify the CLI with [scripts/validate_install.sh](/Users/anisrahm/Documents/anemoi-demo/scripts/validate_install.sh).
5. Record the exact run in [notes/run-metadata-template.md](/Users/anisrahm/Documents/anemoi-demo/notes/run-metadata-template.md).

## Definition Of Done

Phase 1 is complete when:

- `anemoi-training` starts successfully in the chosen environment.
- dataset and graph inputs both load successfully;
- a short training job completes;
- at least one checkpoint is written;
- the exact rerun command, config, environment, dataset, graph, and outputs are captured.
