---
description: Build system and dependency debugging — CMake, Make/Ninja, linkers, submodules
---

# Debugging Tips

## Build System

```bash
cmake /path/to/source --debug-output          # Verbose CMake configuration
cmake /path/to/source --trace                  # Trace CMake execution
cmake -LAH /path/to/build                      # See all CMake variables
cmake /path/to/source -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
make VERBOSE=1                                 # Make verbose
ninja -v                                       # Ninja verbose
ninja -t commands path/to/file.cpp             # View compile command for file
```

## Dependencies

```bash
ldd /path/to/binary                            # Runtime dependencies
nm -D /path/to/library.so                      # What a library provides
nm -u /path/to/binary                          # Undefined symbols
cmake /path/to/source -DCMAKE_FIND_DEBUG_MODE=ON  # Debug find_package
```

## Incremental Build Issues

```bash
cmake --build . --target clean                 # Clean artifacts, keep CMake cache
rm -rf * && cmake /path/to/source [flags]      # Full rebuild
ccache -C                                      # Clear ccache
ccache -s                                      # Check ccache stats
```

## Git/Submodule Issues

```bash
git submodule status                           # Check submodule status
git submodule update --init --recursive        # Update submodules
git submodule foreach --recursive git clean -xfd  # Clean submodules
git worktree list                              # List worktrees
git worktree repair                            # Repair worktrees
```

## Common Issues

- **"Could not find package"**: Check `CMAKE_PREFIX_PATH`, ensure dependency is installed
- **Build hangs**: Check for infinite loops in CMake, reduce parallelism with `-j4`
- **Linker errors**: Check library order, ensure all dependencies are linked
