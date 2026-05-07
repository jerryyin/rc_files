---
globs: "**/iree/**"
description: IREE compiler project — build system, testing, MLIR style
---

## Project Context

This is the IREE compiler project - a retargetable MLIR-based machine learning compiler and runtime toolkit.

### Project Structure
- `compiler/` - MLIR-based compiler (follows LLVM/MLIR style guide)
- `runtime/` - Lightweight runtime (follows Google style guide)
- `tools/` - Command-line tools (`iree-opt`, `iree-compile`, etc.)
- `tests/` - End-to-end and integration tests

### Build System

1. **Find the build directory**: Check the `compile_commands.json` symlink:
   ```bash
   readlink -f compile_commands.json
   ```
   Use this build directory for all cmake/ninja/ctest commands.

2. **Build a specific target**:
   ```bash
   cmake --build <build-dir> --target <target-name>
   ```
   Common targets: `iree-opt`, `iree-compile`, `iree-run-module`

3. **Run tests**: Use ctest from the build directory:
   ```bash
   cd <build-dir> && ctest -R <test-pattern> --output-on-failure
   ```

### Experiment Discipline

Before comparing compiler performance or correctness results, freeze the
experiment: branch/SHA, build directory, input, flags, baseline, variant,
metric, and sanity checks. If any dimension changes, do not compare the numbers
as the same run.

### Useful Scripts (`~/scripts/iree/`)

- `gen_matmul.py` — generate MLIR for matmul/batch-matmul with arbitrary transpose and dtype
- `iree_bench.py` — compile MLIR to VMFB and benchmark with `iree-benchmark-module`
- `inspect_isa.py` — parse and summarize stats from compiled `.rocmasm` assembly files
- `gen_conv.sh` — generate and test convolution MLIR
- `test.sh` — Generic test configurations
- `bisect_boo_gemm.sh` — bisect GEMM performance regressions against BOO thresholds
