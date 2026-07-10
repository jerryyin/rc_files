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

Cache files live under `~/.triton/cache/<hash>/`: `.ttgir`, `.llir`, `.amdgcn`,
`.hsaco`, `.json`, and `.source` (plus `.ttir` when emitted).

## Build

LLVM is auto-resolved to the pinned prebuilt under `~/.triton/llvm/llvm-<hash>`.
An already-configured build dir has that path baked into `CMakeCache.txt` /
`build.ninja`, so `ninja` needs no env var. Set `LLVM_SYSPATH=/path/to/llvm` only
to override with a custom LLVM (it's a cmake passthrough in `setup.py`, not
`LLVM_BUILD_DIR`).

```bash
# Iterate: find the configured build dir via the symlink, build one target.
readlink -f compile_commands.json        # -> build/cmake.linux-x86_64-cpython-3.12
ninja -C build/cmake.linux-x86_64-cpython-3.12 libtriton.so   # or triton-opt, etc.

# Full (re)build / install:
pip install -e . --no-build-isolation
DEBUG=1 pip install -e . --no-build-isolation
MAX_JOBS=8 pip install -e .
```

## AM/FFM

Interactive shells already have the FFM env loaded by `~/.zshrc` (`load_ffm_env`
sources `/am-ffm/ffmlite_env.sh`, prepends `/opt/rocm/lib`, sets
`PYTEST_PLUGINS=ffm_teardown`). So for FFM work in a normal shell, just run the
command directly — no wrapper needed:

```bash
python3 kernel.py
```

Use `~/scripts/tools/run_on_model.sh` when the auto-load doesn't apply or isn't
enough — it sets up the env from scratch and adds what `.zshrc` doesn't:
- **AM backend** (`--backend am`; the auto-load is FFM-only),
- **`--capture`** an AQL trace via roccap (forces FFM),
- **non-interactive / `docker exec` / cron** contexts where `.zshrc` never ran,
- a fuller ROCm overlay that shadows bundled libs and excludes `libamd_smi`.

```bash
~/scripts/tools/run_on_model.sh --backend am -- python3 kernel.py
~/scripts/tools/run_on_model.sh --capture   -- ./hip_tdm_1d 3
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
