set print pretty on
set print object on
set history save on

python
from pathlib import Path
import gdb

llvm_root = Path.home() / "iree/third_party/llvm-project"
for project in ("llvm", "mlir"):
    printer = llvm_root / project / "utils/gdb-scripts/prettyprinters.py"
    if printer.is_file():
        gdb.execute("source " + str(printer))
end

# libc++ pretty printers
# See: https://github.com/koutheir/libcxx-pretty-printers
#python
#import sys
#sys.path.insert(0, '~/libcxx-pretty-printers/src')
#from libcxx.v1.printers import register_libcxx_printers
#register_libcxx_printers(None)
#end
