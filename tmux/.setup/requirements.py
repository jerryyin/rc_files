from system import Package

DEPENDENCIES = ('powershell',) if PLATFORM == 'windows' else ('zsh',)
PACKAGES = [Package('psmux', winget='marlocarlo.psmux')] if PLATFORM == 'windows' else [Package('tmux', ('tmux',))]
