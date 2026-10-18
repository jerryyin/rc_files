#!/usr/bin/env bash
cd "${1:-.}" || exit 1
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git ls-files --recurse-submodules
  find build -name '*.inc' 2>/dev/null
else
  rg --files --glob '!build/**'
fi | if [ -d iree ]; then
  grep -E '^(third_party/llvm-project/mlir/|[^t])'
elif [ -d python/triton ]; then
  grep -v -E '^third_party/(f2reduce|nvidia)/'
else
  cat
fi
