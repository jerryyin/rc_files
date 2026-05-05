---
description: General-purpose scripts in ~/scripts/tools/ — binary comparison, input generation, GDB helpers, GitHub downloads, benchmarking drivers
---

# Available Scripts (`~/scripts/tools/`)

Before writing one-off scripts, check if one of these already does what you need.

| Script | Purpose |
|--------|---------|
| `compare.py` | Compare two binary files element-wise (bf16/f16/f32/i32) with configurable threshold |
| `genRandInput.py` | Generate random binary input files: `python genRandInput.py out.bin --shape 2 235 363 224 --dtype bf16` |
| `gdb_print_lanes.py` | GDB helper: print a variable across GPU lanes in compact format. Source in GDB, call `print_variable_for_lanes("var")` |
| `att_analyze.py` | Analyze ATT profiling CSVs — instruction categorization, latency/stall breakdown, cross-run comparison |
| `run_on_model.sh` | Run a command under AM or FFM simulator environment (sets up HSA env vars, library paths) |
| `ffm_teardown.py` | Pytest plugin: `hipDeviceReset` + `os._exit` after session to prevent FFM hangs |
| `prof.sh` | Fix `/opt/rocm` symlink and set up ROCm profiling environment |
| `download_github_attachment.py` | Download attachments from a GitHub issue by issue ID |
| `torch_event_replay.py` | Replay TraceLens op events (e.g. `aten::addmm`) for benchmarking |

## Benchmarking Drivers (`~/scripts/bench/`)

| Script | Purpose |
|--------|---------|
| `hipblaslt.py` | Run hipBLASLt benchmark commands from a file, parse results to CSV |
| `miopen.py` | Run MIOpenDriver commands across multiple GPUs with multiprocessing, collect results to CSV |
