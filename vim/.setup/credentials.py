"""Persist Copilot's login independently of tracked editor configuration."""

from private import persist, run

if __name__ == '__main__':
    run(lambda: persist('.config/github-copilot'))
