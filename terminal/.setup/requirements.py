from system import Package

DEPENDENCIES = ('powershell',) if PLATFORM == 'windows' else ()
PACKAGES = [Package('wt', winget='Microsoft.WindowsTerminal')]
