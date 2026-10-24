from system import Package

DEPENDENCIES = ('node',)
PACKAGES = [Package('codex', npm='@openai/codex'),
            Package('codex-acp', npm='@agentclientprotocol/codex-acp')] if PLATFORM == 'windows' else []
