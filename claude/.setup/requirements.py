from system import Package

DEPENDENCIES = ('node',)
PACKAGES = [Package('claude', npm='@anthropic-ai/claude-code')] if PLATFORM == 'windows' else []
