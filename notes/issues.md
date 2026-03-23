# Phase 1 Issues

## Open blockers

1. `anemoi-training` is not installed in the local environment yet.
2. The LUMI container path and runtime need to be validated on an actual LUMI node.
3. A concrete dataset path has not been selected.
4. A concrete graph file or graph-generation path has not been selected.
5. The minimal config has documented placeholders that must be resolved before execution.
6. End-to-end training has not been validated from this workspace yet.

## First things to check after installation

1. The configured LUMI container exists and starts cleanly.
2. `anemoi-training train` starts inside the container and fails only on unresolved config placeholders.
3. `anemoi-training config generate` works inside the container.
4. The chosen dataset opens without schema or resolution errors.
5. The chosen graph matches the dataset resolution and node layout.
