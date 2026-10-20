"""Install Codex and seed local defaults without replacing application state."""

import os
from pathlib import Path

from npm import install


def setup(home: Path) -> None:
    if os.name != 'nt':
        install('@openai/codex', 'codex')
    target = home / '.codex/config.toml'
    if not target.exists():
        template = Path(__file__).resolve().parents[1] / '.codex.config.toml.template'
        target.parent.mkdir(parents=True, exist_ok=True)
        text = template.read_text(encoding='utf-8').replace('/home/zhuoryin', str(home).replace('\\', '\\\\'))
        with target.open('x', encoding='utf-8') as stream:
            stream.write(text)
        target.chmod(0o600)


if __name__ == '__main__':
    setup(Path.home())
