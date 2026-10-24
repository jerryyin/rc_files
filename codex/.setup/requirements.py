from system import Package

DEPENDENCIES = ('node',)
PACKAGES = [Package('codex', winget='OpenAI.Codex')]
if PLATFORM == 'windows':
    PACKAGES += [Package('codex-acp', npm='@agentclientprotocol/codex-acp')]
