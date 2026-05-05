---
globs: "**/triton*/**"
description: Triton environment variables, cache management, and build configuration
---

# Triton Environment, Cache, and Build Reference

## IR Dump Environment Variables

| Variable | Effect |
|----------|--------|
| `MLIR_ENABLE_DUMP=1` | Dump MLIR IR after each pass (or `=func_name` for specific function) |
| `LLVM_IR_ENABLE_DUMP=1` | Dump LLVM IR |
| `AMDGCN_ENABLE_DUMP=1` | Dump AMD GCN assembly |
| `TRITON_SAVETEMPS_DIR=<path>` | Save all intermediate IR files to directory |

## Debug Logging

| Variable | Effect |
|----------|--------|
| `TRITON_ENABLE_LLVM_DEBUG=1` | Enable ALL LLVM debug output (very verbose) |
| `TRITON_LLVM_DEBUG_ONLY=<type>` | Enable debug only for specific `DEBUG_TYPE` |
| `MLIR_ENABLE_TIMING=1` | Show pass timing information |

Requires `DEBUG=1` build. Use `LDBG("message " << value)` macro in C++ passes.

## Compilation Control

| Variable | Effect |
|----------|--------|
| `TRITON_ALWAYS_COMPILE=1` | Skip cache, always recompile |
| `TRITON_CACHE_DIR=<path>` | Override cache directory |
| `DISABLE_LLVM_OPT=1` | Disable LLVM optimizations |
| `MLIR_DISABLE_MULTITHREADING=1` | Disable multithreading (useful for debugging) |

## AMD Backend Variables

| Variable | Default | Effect |
|----------|---------|--------|
| `AMDGCN_USE_BUFFER_OPS` | off | Enable buffer_load/store instructions |
| `TRITON_HIP_USE_BLOCK_PINGPONG` | auto | Enable ping-pong scheduling for matmul |
| `TRITON_HIP_USE_IN_THREAD_TRANSPOSE` | auto | Transpose loaded elements within thread before LDS store |
| `TRITON_HIP_USE_ASYNC_COPY` | off | Enable direct-to-LDS loads |

## Cache Structure

**Location:** `~/.triton/cache/<hash>/`

Files: `.ttir` (Triton IR), `.ttgir` (GPU IR with layouts), `.llir` (LLVM IR), `.amdgcn` (AMD assembly), `.hsaco` (AMD binary), `.json` (metadata).

Clear cache: `rm -rf ~/.triton/cache`

## Build from Source

```bash
pip install -e . --no-build-isolation              # Standard build
DEBUG=1 pip install -e . --no-build-isolation       # Debug build
make all                                            # Incremental C++ rebuild
LLVM_BUILD_DIR=/path/to/llvm/build pip install -e . # Custom LLVM
MAX_JOBS=8 pip install -e .                         # Limit parallel jobs
```

## Programmatic Access

```python
compiled = compile(kernel, ...)
print(compiled.asm['ttir'])    # Triton IR
print(compiled.asm['ttgir'])   # Triton GPU IR
print(compiled.asm['amdgcn'])  # Assembly
print(f"Shared memory: {compiled.metadata.shared}")
```
