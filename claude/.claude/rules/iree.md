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
