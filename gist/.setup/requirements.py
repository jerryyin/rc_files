from system import Package

PACKAGES = [Package('gist-paste', ('gist',))] if PLATFORM == 'linux' else []
