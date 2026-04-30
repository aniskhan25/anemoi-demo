# Full-Node Startup Debug

This note is for the 8 -> 16 -> 32 node bring-up of the full-node LUMI-G run.

## Goal

Separate startup problems from steady-state scaling problems.

The first success criterion is not throughput. It is:

- the job reaches the first epoch progress line on all ranks

Only after that should the run be used for throughput comparisons.

## Step 1: Precreate The Graph

Run this once:

```bash
cd /scratch/project_462000131/anisrahm/anemoi-demo
sbatch jobs/precreate_graph.sh
```

Expected artifact:

```bash
/project/project_462000131/${USER}/anemoi-demo/graphs/first_graph_o48.pt
```

## Step 2: Full-Node Startup Sweep

Submit the same startup-debug job at increasing node counts.

### 8 nodes

```bash
cd /scratch/project_462000131/anisrahm/anemoi-demo
sbatch --nodes=8 --export=ALL,ANEMOI_NODES=8,ANEMOI_BATCH_SIZE=8,ANEMOI_TRAIN_LIMIT=500,ANEMOI_VAL_LIMIT=10 jobs/debug_fullnode_startup.sh
```

### 16 nodes

```bash
cd /scratch/project_462000131/anisrahm/anemoi-demo
sbatch --nodes=16 --export=ALL,ANEMOI_NODES=16,ANEMOI_BATCH_SIZE=8,ANEMOI_TRAIN_LIMIT=500,ANEMOI_VAL_LIMIT=10 jobs/debug_fullnode_startup.sh
```

### 32 nodes

```bash
cd /scratch/project_462000131/anisrahm/anemoi-demo
sbatch --nodes=32 --export=ALL,ANEMOI_NODES=32,ANEMOI_BATCH_SIZE=8,ANEMOI_TRAIN_LIMIT=500,ANEMOI_VAL_LIMIT=10 jobs/debug_fullnode_startup.sh
```

## Step 3: Check Progress

Batch log:

```bash
tail -n 80 /scratch/project_462000131/anisrahm/anemoi-demo/logs/slurm-fullnode-startup-<jobid>.out
```

Per-rank logs:

```bash
ls /scratch/project_462000131/anisrahm/anemoi-demo/logs/step-<jobid>-*.out | wc -l
grep -n "Seed set\|Normalizing\|Trainable params\|Epoch" /scratch/project_462000131/anisrahm/anemoi-demo/logs/step-<jobid>-*.out | head -n 100
```

## Step 4: Find The Slow Phase

Ranks that never got past seed:

```bash
grep -L "Normalizing:" /scratch/project_462000131/anisrahm/anemoi-demo/logs/step-<jobid>-*.out
```

Ranks that got into preprocessing:

```bash
grep -l "Normalizing:" /scratch/project_462000131/anisrahm/anemoi-demo/logs/step-<jobid>-*.out | head
```

Ranks that reached the model summary:

```bash
grep -l "Trainable params:" /scratch/project_462000131/anisrahm/anemoi-demo/logs/step-<jobid>-*.out
```

Ranks that reached training:

```bash
grep -l "Epoch " /scratch/project_462000131/anisrahm/anemoi-demo/logs/step-<jobid>-*.out
```

## Interpretation

- If most ranks stop before `Seed set`, distributed startup is failing.
- If ranks stop between `Seed set` and `Normalizing`, data/module initialization is slow or blocked.
- If rank 0 reaches `Trainable params` but most ranks stay earlier, startup is progressing unevenly and shared I/O is the likely bottleneck.
- If all ranks reach `Epoch`, startup is no longer the blocker and the next issue is steady-state throughput.
