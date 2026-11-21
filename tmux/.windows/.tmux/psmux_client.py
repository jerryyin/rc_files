"""Send one command to the psmux server that invoked a binding."""

import os
from pathlib import Path
import socket


def request(command: str, target: str = '') -> str:
    directory = Path(os.environ.get('PSMUX_DATA_DIR') or Path.home() / '.psmux')
    session = os.environ['PSMUX_TARGET_SESSION']
    port = int((directory / f'{session}.port').read_text())
    key = (directory / f'{session}.key').read_text().strip()
    with socket.create_connection(('127.0.0.1', port), timeout=3) as client, client.makefile('rb') as reply:
        client.sendall(f'AUTH {key}\n'.encode())
        if reply.readline().strip() != b'OK':
            raise RuntimeError('psmux rejected the session key')
        prefix = f'TARGET {target}\n' if target else ''
        client.sendall(f'{prefix}{command}\n'.encode())
        client.shutdown(socket.SHUT_WR)
        return reply.read().decode().removesuffix('\n')


def command(*args: str) -> str:
    if any('\n' in arg or '\r' in arg for arg in args):
        raise ValueError('psmux command arguments must occupy one line')
    words = ['"' + arg.replace('\\', '\\\\').replace('"', '\\"') + '"' for arg in args[1:]]
    reply = request(' '.join([args[0], *words]))
    if reply.startswith('ERROR:'):
        raise RuntimeError(reply)
    return reply
