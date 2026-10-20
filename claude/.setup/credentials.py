"""Apply the Claude gateway key only during explicit credential setup."""

import os
from pathlib import Path

from private import run
from settings import setup


if __name__ == '__main__' and os.environ.get('RC_CREDENTIALS_SAVE') != '1':
    run(lambda: setup(Path.home(), credentials=True))
