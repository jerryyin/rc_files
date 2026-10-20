"""Install the font selected by the native terminal configuration."""

import os
from pathlib import Path
import subprocess


if __name__ == '__main__' and os.name == 'nt':
    if os.environ.get('RC_SETUP_REDIRECTED') != '1' and os.environ.get('RC_SETUP_INSTALL') != '0':
        subprocess.run(['powershell.exe', '-NoProfile', '-File',
                        str(Path(__file__).with_name('font.ps1'))], check=True)
