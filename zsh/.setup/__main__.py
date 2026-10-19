"""Load Zsh's declared plugins eagerly during Linux setup."""

import subprocess
import sys


if __name__ == '__main__' and sys.platform == 'linux':
    subprocess.run(['zsh', '-c', 'source "$HOME/.zshrc"'], check=True)
