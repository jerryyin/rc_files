set print pretty on
set print object on
set history save on

source ~/iree/third_party/llvm-project/llvm/utils/gdb-scripts/prettyprinters.py
source ~/iree/third_party/llvm-project/mlir/utils/gdb-scripts/prettyprinters.py

# libc++ pretty printers
# See: https://github.com/koutheir/libcxx-pretty-printers
#python
#import sys
#sys.path.insert(0, '~/libcxx-pretty-printers/src')
#from libcxx.v1.printers import register_libcxx_printers
#register_libcxx_printers(None)
#end
