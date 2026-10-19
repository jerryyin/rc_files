from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from threading import Thread
import unittest


@unittest.skipUnless(os.environ.get('RC_CLAUDE_CLI_TEST') == '1',
                     'Set RC_CLAUDE_CLI_TEST=1 to check the installed CLI against a local gateway')
class InstalledCliTests(unittest.TestCase):
    def test_normal_cli_uses_saved_credentials_until_setup_refreshes_them(self) -> None:
        received: list[tuple[str | None, str | None]] = []

        class Gateway(BaseHTTPRequestHandler):
            def do_POST(self) -> None:
                body = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
                received.append((self.headers.get('Ocp-Apim-Subscription-Key'),
                                 self.headers.get('x-api-key')))
                message = dict(id='msg_fixture', type='message', role='assistant',
                               model=body.get('model', 'fixture-model'), content=[],
                               stop_reason=None, stop_sequence=None,
                               usage=dict(input_tokens=1, output_tokens=1))
                self.send_response(200)
                self.send_header('Content-Type', 'text/event-stream' if body.get('stream') else 'application/json')
                self.end_headers()
                if body.get('stream'):
                    events = [
                        dict(type='message_start', message=message),
                        dict(type='content_block_start', index=0, content_block=dict(type='text', text='')),
                        dict(type='content_block_delta', index=0,
                             delta=dict(type='text_delta', text='fixture response')),
                        dict(type='content_block_stop', index=0),
                        dict(type='message_delta', delta=dict(stop_reason='end_turn', stop_sequence=None),
                             usage=dict(output_tokens=1)),
                        dict(type='message_stop'),
                    ]
                    for event in events:
                        self.wfile.write(f'event: {event["type"]}\ndata: {json.dumps(event)}\n\n'.encode())
                else:
                    message.update(content=[dict(type='text', text='fixture response')], stop_reason='end_turn')
                    self.wfile.write(json.dumps(message).encode())
                self.wfile.flush()

            def log_message(self, format: str, *args: object) -> None:
                pass

        server = ThreadingHTTPServer(('127.0.0.1', 0), Gateway)
        thread = Thread(target=server.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        checkout = Path(__file__).resolve().parents[3]
        with tempfile.TemporaryDirectory(prefix='claude-cli-') as directory:
            home = Path(directory)
            (home / '.claude.json').write_text(json.dumps(dict(
                projects={'existing': {}},
                env=dict(ANTHROPIC_CUSTOM_HEADERS='Ocp-Apim-Subscription-Key: fixture-obsolete'))))
            settings = home / '.claude/settings.json'
            key = home / 'vault/claude_key.txt'
            key.parent.mkdir()
            environment = dict(os.environ, HOME=str(home), USERPROFILE=str(home),
                               CLAUDE_CONFIG_DIR=str(settings.parent), CLAUDE_KEY_FILE=str(key),
                               CLAUDE_CODE_DISABLE_OFFICIAL_MARKETPLACE_AUTOINSTALL='1',
                               RC_SETUP_REDIRECTED='0', RC_SETUP_UPDATE='0')
            if os.name == 'nt':
                for name, suffix in (('LOCALAPPDATA', 'Local'), ('APPDATA', 'Roaming')):
                    directory = home / 'AppData' / suffix
                    directory.mkdir(parents=True)
                    environment[name] = str(directory)
            for name in ('ANTHROPIC_AUTH_TOKEN', 'ANTHROPIC_API_KEY', 'ANTHROPIC_CUSTOM_HEADERS',
                         'CLAUDE_CODE_OAUTH_TOKEN'):
                environment.pop(name, None)
            overrides = home / 'test-overrides.json'
            overrides.write_text(json.dumps(dict(env=dict(ANTHROPIC_BASE_URL=f'http://127.0.0.1:{server.server_port}'),
                                                 enabledPlugins={'clangd-lsp@claude-plugins-official': False})))
            executable = shutil.which('claude')
            self.assertIsNotNone(executable, 'Install Claude Code and put it on PATH before this check')
            key.write_text('fixture-key-one')
            for value, refresh in (('fixture-key-one', True), ('fixture-key-one', False), ('fixture-key-two', True)):
                if refresh:
                    prepared = subprocess.run([sys.executable, '-B', str(checkout / 'claude/.setup')],
                                              env=environment, text=True, capture_output=True)
                    self.assertEqual(prepared.returncode, 0, prepared.stdout + prepared.stderr)
                received.clear()
                result = subprocess.run(
                    [executable, '--print', '--model', 'fixture-model', '--max-turns', '1',
                     '--settings', str(overrides), 'fixture question'], cwd=home, env=environment,
                    text=True, encoding='utf-8', capture_output=True, timeout=45)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn('fixture response', result.stdout)
                self.assertTrue(received, 'The real CLI did not contact the local gateway')
                self.assertTrue(all(pair == (value, 'dummy') for pair in received), received)
                self.assertNotIn(value, result.stdout + result.stderr)
                key.write_text('fixture-key-two')


if __name__ == '__main__':
    unittest.main()
