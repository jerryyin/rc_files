---
globs: "**/triton*/**"
description: Triton kernel development — tile sizes, masking, anti-patterns, performance
---

# Triton Kernel Development Rules

## Tile Size Constraints

- **Always use power-of-2** for `BLOCK_SIZE`, `BLOCK_M`, `BLOCK_N`, `BLOCK_K`
- Tile dimensions in `tl.arange(start, end)` must be compile-time constants (`tl.constexpr`)
- Non-power-of-2 tile sizes will fail compilation

## Masking Rules

Always mask at boundaries:
```python
offsets = pid * BLOCK_SIZE + tl.arange(0, BLOCK_SIZE)
mask = offsets < n_elements
data = tl.load(ptr + offsets, mask=mask, other=0.0)
tl.store(ptr + offsets, result, mask=mask)
```

## Anti-Patterns to Avoid

- **Scalar loops**: use vectorized `tl.load(ptr + tl.arange(0, BLOCK))`, not per-element loops
- **Runtime values in tl.arange()**: use `tl.constexpr` parameters
- **Low-precision accumulation**: accumulate in `tl.float32`, cast inputs to `tl.float16` for dot

## Type Conversion

- FP8 inputs -> FP16/FP32 accumulation -> output type
- Use explicit `.to()` for type conversions
- Avoid unnecessary back-and-forth conversions

## num_warps vs CUDA blockDim

`num_warps` is NOT like CUDA `blockDim`. It controls parallelism within tile operations.
The compiler maps tile operations to warps. Don't confuse with iteration space.

## Performance Quick Checks

1. **Register spills:** Look for `scratch_load`/`scratch_store` in assembly
2. **Layout conversions in loops:** Check TTGIR for `convert_layout` in hot paths
3. **Memory coalescing:** Adjacent threads should access adjacent memory
