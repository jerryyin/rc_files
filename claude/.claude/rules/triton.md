---
globs: "**/triton*/**"
description: Triton project specifics — pass pipeline, environment, FFM, kernel constraints, and layout checks
---

# Triton

## Compiler Pipeline

- Use `third_party/amd/backend/compiler.py` to determine pass ordering and
  flags: `make_ttir` -> `make_ttgir` -> `make_llir`.
- For `BlockedEncodingAttr`, check: CTA tile size, number of tiles, warp
  mapping, lane mapping, registers per thread, free/broadcast dimensions, and
  `SliceEncodingAttr` projection effects.

## Environment, Cache, and Dumps

| Variable | Effect |
|----------|--------|
| `MLIR_ENABLE_DUMP=1` | Dump MLIR IR after each pass, or `=func_name` for one function |
| `LLVM_IR_ENABLE_DUMP=1` | Dump LLVM IR |
| `AMDGCN_ENABLE_DUMP=1` | Dump AMD GCN assembly |
| `TRITON_SAVETEMPS_DIR=<path>` | Save intermediate IR files |
| `TRITON_ALWAYS_COMPILE=1` | Skip cache and always recompile |
| `TRITON_CACHE_DIR=<path>` | Override cache directory |
| `DISABLE_LLVM_OPT=1` | Disable LLVM optimizations |
| `MLIR_DISABLE_MULTITHREADING=1` | Disable MLIR multithreading |

Cache files live under `~/.triton/cache/<hash>/`: `.ttir`, `.ttgir`,
`.llir`, `.amdgcn`, `.hsaco`, and `.json`.

## Build

```bash
pip install -e . --no-build-isolation
DEBUG=1 pip install -e . --no-build-isolation
make all
LLVM_BUILD_DIR=/path/to/llvm/build pip install -e .
MAX_JOBS=8 pip install -e .
```

## AM/FFM

- Canonical wrapper: `~/scripts/tools/run_on_model.sh`.
- Defaults: package `/am-ffm`, backend FFM (`ffmlite_env.sh`).
- `~/.zshrc` loads the FFM env for interactive shells and prepends
  `/opt/rocm/lib` so system ROCm libraries shadow bundled copies.

```bash
~/scripts/tools/run_on_model.sh -- python3 kernel.py
~/scripts/tools/run_on_model.sh --backend am -- python3 kernel.py
~/scripts/tools/run_on_model.sh --capture -- ./hip_tdm_1d 3
```

## Kernel Rules

- `BLOCK_SIZE`, `BLOCK_M`, `BLOCK_N`, and `BLOCK_K` should be powers of two.
- `tl.arange` bounds must be compile-time constants (`tl.constexpr`).
- Mask boundary loads/stores.
- Use vectorized `tl.load(ptr + tl.arange(...))`, not scalar per-element loops.
- Accumulate low-precision dot products in `tl.float32`.
- `num_warps` controls tile-operation parallelism; it is not CUDA `blockDim`.

## Quick Performance Checks

- Register spills: look for `scratch_load` / `scratch_store` in assembly.
- Layout conversions: check TTGIR for `convert_layout` in hot paths.
- Memory coalescing: adjacent threads should access adjacent memory.

Useful scripts:
- `~/scripts/triton/tdm/triton/dump_asm.py`
- `~/scripts/triton/lds/lds_bank_conflict_analyzer.py`
- `~/scripts/triton/lds/lds_access_pattern_analysis.py`
- `~/scripts/triton/spills/run_spill_benchmark.sh`
- `~/scripts/triton/ds_load_tr/analyze_ds_load_tr.py`
