"""Persist Git's optional plaintext login store in trusted container storage."""

from private import persist, run

if __name__ == '__main__':
    run(lambda: persist('.git-credentials'))
