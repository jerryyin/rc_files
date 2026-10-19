"""Restrict the installed SSH directory on Unix hosts."""

import os
from pathlib import Path


if __name__ == '__main__' and os.name != 'nt':
    directory = Path.home() / '.ssh'
    if directory.is_dir():
        directory.chmod(0o700)
