# Roadmap

Status of the Anemoi-on-LUMI-G bring-up. Verified runs are recorded here for
future reference so we know which paths are known-good under the current stack.

## Current stack

- Container: `anemoi-lumi.sif` — `anemoi-training==0.14.0`, `anemoi-models==0.16.0`,
  `anemoi-graphs==0.9.4` on PyTorch 2.10 + ROCm 7.0 (venv baked in at
  `/opt/anemoi-venv`).
- Configs migrated to the 0.14.0 `system` / `task` schema.
- `env/lumi-env.sh` defaults to the container above; validation jobs run on `dev-g`.

## Verified runs

| Date | Path | Job | Result |
|------|------|-----|--------|
| 2026-06-30 | Container build + smoke test | — | ✅ torch 2.10 ROCm, all anemoi imports OK |
| 2026-06-30 | `validate_minimal` (1 GPU) | 19619611 | ✅ COMPLETED |
| 2026-07-01 | `validate_multigpu` (2 GPU, DDP) | 19640776 | ✅ COMPLETED — 1m43s on `dev-g`, train_loss 0.0925 / val_loss 0.095, checkpoints written |
| 2026-07-01 | `validate_multinode` (2 nodes × 2 GPU, DDP) | 19644704 | ✅ COMPLETED — 2m07s on `dev-g`, train_loss 0.106 / val_loss 0.112, checkpoints written |

## Next steps
- [ ] `train_multigpu` / `train_multinode` — full (non-smoke) distributed runs
- [ ] Full-node bring-up (8 → 16 → 32 nodes) on `standard-g` — see
      `notes/fullnode-startup-debug.md`
- [ ] Experimental sharded / FSDP full-node paths
      (`training-fullnode-sharded.yaml`, `training-fullnode-fsdp.yaml`)

## Notes

- The 0.7.0 → 0.14.0 upgrade was a breaking schema change: `hardware` → `system`,
  new `task` group, `training.lr.rate` → `training.optimization.lr`, and
  `diagnostics.log.mlflow.tracking_uri` must be set (null when mlflow is off).
- If a job reports training options `default, diffusion, ensemble, interpolator,
  lam, stretched`, it is running the **old** anemoi (wrong container). The 0.14.0
  container lists `single, multi, transport, …`.
