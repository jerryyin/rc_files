"""Install Claude and seed public preferences without accessing credentials."""

from pathlib import Path

from npm import install
from private import run
from settings import setup


def main() -> None:
    install('@anthropic-ai/claude-code', 'claude')
    setup(Path.home())


if __name__ == '__main__':
    run(main)
