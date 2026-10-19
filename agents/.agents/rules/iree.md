# IREE

Applies when: Working in an IREE compiler/runtime checkout, identified by its project instructions and compiler/src/iree or runtime/src/iree source tree, including a renamed checkout or Git worktree.

## Project Context

This is the IREE compiler project - a retargetable MLIR-based machine learning compiler and runtime toolkit.

### Project Structure
- `compiler/` - MLIR-based compiler (follows LLVM/MLIR style guide)
- `runtime/` - Lightweight runtime (follows Google style guide)
- `tools/` - Command-line tools (`iree-opt`, `iree-compile`, etc.)
- `tests/` - End-to-end and integration tests

### Build System

1. **Find the build directory**: Resolve the `compile_commands.json` link with the current host's filesystem tools. Python's `Path("compile_commands.json").resolve()` works on either platform; use the available Python launcher. On Linux, `readlink -f compile_commands.json` is also suitable.
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

### Useful Scripts (`~/scripts/iree/`)

- `gen_matmul.py` — generate MLIR for matmul/batch-matmul with arbitrary transpose and dtype
- `iree_bench.py` — compile MLIR to VMFB and benchmark with `iree-benchmark-module`
- `inspect_isa.py` — parse and summarize stats from compiled `.rocmasm` assembly files
- `gen_conv.sh` — generate and test convolution MLIR
- `test.sh` — Generic test configurations
- `bisect_boo_gemm.sh` — bisect GEMM performance regressions against BOO thresholds
