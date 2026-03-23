# Data Notes

Phase 1 should use the smallest valid dataset that Anemoi training accepts.

Preferred order:

1. Reuse a small existing internal or test dataset.
2. Build a deliberately tiny dataset with `anemoi-datasets`.
3. Avoid large public ERA5 downloads for this phase.

Capture the following once the dataset is chosen:

- source or recipe used;
- date range;
- variables included;
- on-disk format and size;
- exact filesystem location;
- any preprocessing command needed to recreate it.

Suggested local layout:

```text
data/
  README.md
  raw/        # ignored by git
  generated/  # ignored by git
```
