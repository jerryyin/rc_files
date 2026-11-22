"""Capture the invoking psmux pane before opening its side question."""

from contextlib import closing
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

from psmux_client import command as mux, request

shared = Path.home() / '.config/tmux'
sys.path.insert(0, str(shared))
from ask_pane import open_answer
import codex_session


def capture(pane: str, window: str, selected: str, layout: str = 'side') -> None:
    if selected != '1':
        raise ValueError('select text in copy mode first')
    copied = request('display-message -p "#{pane_id} #{pane_in_mode} #{selection_present}" ; '
                     'send-keys -X copy-selection-no-clear ; show-buffer', pane)
    source, _, passage = copied.partition('\n')
    if source != f'{pane} 1 1' or not passage:
        raise ValueError('the selection is empty or has moved')
    fields = request('display-message -p "#{pane_pid}\t#{pane_current_command}\t#{pane_current_path}\t#{pane_title}"', pane)
    pid, command, cwd, title = fields.split('\t', 3)
    screen = '' if codex_session.THREAD_TITLE.fullmatch(title) else request('capture-pane -p -S -3000', pane)
    prompts = [line.strip()[2:] for line in screen.splitlines() if line.lstrip().startswith('› ')]
    git = shutil.which('git.exe')
    if not git:
        raise ValueError('Git for Windows is required for the question prompt')
    bash = Path(git).resolve().parents[1] / 'usr/bin/bash.exe'
    if not bash.is_file():
        git_core = subprocess.check_output([git, '--exec-path'], encoding='utf-8').strip()
        bash = Path(git_core).parents[2] / 'usr/bin/bash.exe'
    with tempfile.NamedTemporaryFile('w', encoding='utf-8', newline='', delete=False) as f:
        f.write(passage)
        selection = Path(f.name)
    # The question loop deletes every file named after the passage file on exit.
    context = selection.with_name(selection.name + '.context')
    try:
        context.write_text(json.dumps(dict(pid=pid, command=command, cwd=cwd, title=title, prompts=prompts))
                           + '\n' + passage, encoding='utf-8', newline='')
        args = [str(bash), str(Path(__file__).with_name('ask-agent-run.sh')), str(shared / 'ask-agent-chat.sh'),
                pane.removeprefix('%'), str(selection), '--', 'py', '-3', str(Path(__file__)), 'resolve', str(context)]
        open_answer(pane, window, layout, '--', *args, mux=mux, psmux=True)
    except Exception:
        selection.unlink(missing_ok=True)
        context.unlink(missing_ok=True)
        raise


def resolve(path: str) -> None:
    """Print "<tool>\t<session-id>\t<cwd>" for the source pane, asking the user to
    pick the Codex conversation when it is ambiguous; print nothing if they decline."""
    with open(path, 'rb') as stream:
        context = json.loads(stream.readline())
        passage = stream.read().decode('utf-8')
    tool = context['command'].lower().removesuffix('.exe')
    if tool != 'codex':
        probe = Path(__file__).with_suffix('.ps1')
        result = subprocess.check_output(['pwsh', '-NoProfile', '-File', str(probe), context['pid']], encoding='utf-8')
        tool = result.strip()
        if tool.startswith('claude\t'):
            sys.stdout.buffer.write(tool.encode())
            return
        if tool != 'codex':
            raise ValueError('no Claude or Codex session in the source pane')
    home = Path(os.environ.get('CODEX_HOME') or Path.home() / '.codex')
    with closing(codex_session.database()) as db:
        found = codex_session.identify(db, home, context['title'], context['prompts'], passage)
        sid, cwd = found or codex_session.choose(db, context['cwd'])
    sys.stdout.buffer.write(f'codex\t{sid}\t{codex_session.local_path(cwd)}'.encode())


if __name__ == '__main__':
    try:
        if sys.argv[1] == 'resolve':
            resolve(sys.argv[2])
        else:
            capture(*sys.argv[1:])
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as error:
        if sys.argv[1] != 'resolve':
            subprocess.run(['psmux.exe', 'display-message', f'ask-agent: {error}'])
        sys.exit(f'ask-agent: {error}')
