---
globs: "**/*.py"
description: Python coding standards — fail-fast, dataclasses, type hints, error handling
---

# Python Style Guide

## Core Principles

### 1. Fail-Fast Behavior

Always fail immediately on errors. Never silently continue or produce incomplete results.

- If data is missing, corrupted, or unreadable → raise an exception
- Don't catch exceptions unless you can meaningfully handle them
- "Warnings" that indicate data problems should be errors

### 2. Use Dataclasses, Not Tuples

For non-trivial data with multiple fields, use dataclasses instead of tuples.

Tuples are OK for simple pairs where meaning is obvious: `(x, y)`, `(min, max)`, or unpacking from standard library functions.

### 3. Type Hints

Always use specific type hints. Never use `Any` except in rare generic code. Extract complex type signatures into named types (NamedTuple or dataclass).

### 4. Error Handling

Distinguish between different error conditions. Don't treat all errors the same.

```python
try:
    output = subprocess.check_output([tool, "-S", str(file_path)])
    return ".target_section" in output
except subprocess.CalledProcessError as e:
    if e.returncode == 1:
        return False  # Tool returns 1 for valid file without target section
    raise RuntimeError(f"{tool} failed on {file_path}: {e.output}") from e
```

### 5. No Timeouts on Basic Tools

NEVER add timeouts to basic operations (readelf, objcopy, etc.).

### 6. Output Validation

Validate that operations actually succeeded. Don't assume.

### 7. No Magic Numbers

Don't use unexplained magic numbers, especially for estimates.

### 8. Performance

Compile regex once at module level. Adjacent threads should access adjacent memory.

### 9. Imports at Top

Put all imports at the top of the file. Inline imports only for circular dependency workarounds (document with comment).

### 10. Code Organization

- Classes should be < 200 lines
- Methods should be < 30 lines
- If a class has 7+ responsibilities, split it
