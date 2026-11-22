"""Open or reuse an answer beside or below the selected pane."""

from collections.abc import Callable
import subprocess
import sys


def tmux(*args: str) -> str:
    return subprocess.check_output(['tmux', *args], encoding='utf-8').rstrip('\n')


def open_answer(agent: str, window: str, layout: str, *command: str,
                mux: Callable[..., str] = tmux, psmux: bool = False) -> None:
    """Run command in the answer pane for agent: the one this layout opened earlier,
    else a new split. psmux keeps options per server, sizes splits with -p, and has
    no popups, so a lone pane is split instead."""
    side_option = f'@ask-agent-pane-{window[1:]}' if psmux else '@ask-agent-pane'
    bottom_option = f'@ask-agent-bottom-{agent[1:]}'
    option = {'side': side_option, 'bottom': bottom_option}[layout]
    fields = '#{pane_id} #{pane_left} #{pane_width} #{pane_height} ' + '#{' + side_option + '}|#{' + bottom_option + '}'
    listing = mux('list-panes', '-t', agent, '-F', fields)
    panes = {}
    side = bottom = ''
    for row in listing.splitlines():
        pane, left, width, height, saved = row.split()
        panes[pane] = (int(left), int(width), int(height))
        if pane == agent:
            side, bottom = saved.split('|')
    if agent not in panes:
        raise ValueError('the source pane has closed')
    left, width, _ = panes.pop(agent)
    answer = bottom if layout == 'bottom' else side
    if answer in panes:
        mux('respawn-pane', '-k', '-t', answer, *command)
        mux('select-pane', '-t', answer)
        return

    def score(pane: str) -> tuple[bool, int]:
        x, w, h = panes[pane]
        return x + w <= left or x >= left + width, w * h

    panes.pop(bottom, None)
    if layout == 'bottom':
        target, direction, size = agent, '-v', '20%'
    elif panes:
        target, direction, size = max(panes, key=score), '-v', '60%'
    elif psmux:
        target, direction, size = agent, '-h', '45%'
    else:
        mux('display-popup', '-E', '-x', 'R', '-y', '0', '-w', '45%', '-h', '100%',
            '-T', ' ask-agent ', *command)
        return
    length = ('-p', size.rstrip('%')) if psmux else ('-l', size)
    new = mux('split-window', direction, *length, '-t', target,
              '-P', '-F', '#{pane_id}', *command).strip()
    if not new.startswith('%') or not new[1:].isdecimal():
        raise RuntimeError(f'could not open the answer pane: {new}')
    mux('set-option', '-g' if psmux else '-w', '-t', window, option, new)


if __name__ == '__main__':
    open_answer(*sys.argv[1:])
