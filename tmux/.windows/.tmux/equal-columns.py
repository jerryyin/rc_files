"""Equalize the top-row columns in the psmux window that invoked the binding."""

from collections.abc import Iterator
import json
import os
from pathlib import Path
import socket
import sys


def top_columns(node: dict) -> int:
    if node["type"] == "leaf":
        return 1
    if node["kind"] == "Vertical":
        return top_columns(node["children"][0])
    return sum(map(top_columns, node["children"]))


def split_commands(node: dict, widths: list[int], path: tuple[int, ...] = ()) -> Iterator[str]:
    if node["type"] == "leaf":
        return
    children = node["children"]
    if node["kind"] == "Vertical":
        yield from split_commands(children[0], widths, (*path, 0))
        return

    sizes = []
    offset = 0
    for index, child in enumerate(children):
        count = top_columns(child)
        columns = widths[offset:offset + count]
        sizes.append(sum(columns) + count - 1)
        yield from split_commands(child, columns, (*path, index))
        offset += count

    # Use the same split weights as a border drag. resize-pane -x in
    # psmux 3.4 treats a cell count as a weight and can collapse its neighbour.
    weights = node["sizes"]
    available = sum(sizes)
    total_weight = sum(weights)
    if any(available * weight // total_weight != size
           for weight, size in zip(weights[:-1], sizes[:-1])):
        address = ".".join(map(str, path)) or "_"
        yield f"split-sizes {address} {','.join(map(str, sizes))}"


def equal_columns(window: int, width: int) -> None:
    directory = Path(os.environ.get("PSMUX_DATA_DIR") or Path.home() / ".psmux")
    session = os.environ["PSMUX_TARGET_SESSION"]
    port = int((directory / f"{session}.port").read_text())
    key = (directory / f"{session}.key").read_text().strip()

    def request(command: str) -> str:
        with socket.create_connection(("127.0.0.1", port), timeout=3) as client, client.makefile("rb") as reply:
            client.sendall(f"AUTH {key}\n".encode())
            if reply.readline().strip() != b"OK":
                raise RuntimeError("psmux rejected the session key")
            client.sendall(f"TARGET @{window}\n{command}\n".encode())
            client.shutdown(socket.SHUT_WR)
            return reply.read().decode().strip()

    layout = json.loads(request(f"window-layout {window}"))
    count = top_columns(layout)
    cells, extra = divmod(width - (count - 1), count)
    # A native psmux pane needs at least two cells horizontally.
    if count == 1 or cells < 2:
        return
    widths = [cells] * count
    widths[-1] += extra
    commands = list(split_commands(layout, widths))
    if commands:
        for command in [*commands, "split-resize-done"]:
            error = request(command)
            if error:
                raise RuntimeError(error)


if __name__ == "__main__":
    equal_columns(int(sys.argv[1].removeprefix("@")), int(sys.argv[2]))
