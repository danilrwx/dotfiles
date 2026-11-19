import os
from pathlib import Path
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class LauncherTest(unittest.TestCase):
    def test_apps_and_commands_work_without_calculator_or_search(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            helpers = home / "dotfiles/bin"
            helpers.mkdir(parents=True)
            stubs = home / "stubs"
            stubs.mkdir()
            apps = home / "data/applications"
            apps.mkdir(parents=True)
            (apps / "dotfiles-test-app.desktop").write_text(
                "[Desktop Entry]\nType=Application\nName=Dotfiles launcher test app\nExec=true\n")
            scripts = {
                helpers / "x-menu": 'cat >/dev/null\nprintf "%s\\n" "$MENU_VALUE"',
                helpers / "clip": 'echo clip >> "$FORBIDDEN"',
                helpers / "web-url": 'echo search >> "$FORBIDDEN"',
                stubs / "gtk-launch": 'printf "%s\\n" "$1" > "$RESULT"',
                stubs / "launcher-test-command": 'printf "%s\\n" "$1" > "$RESULT"',
                stubs / "xdg-open": 'echo browser >> "$FORBIDDEN"',
                stubs / "notify-send": 'echo notification >> "$FORBIDDEN"',
            }
            for path, script in scripts.items():
                path.write_text("#!/bin/sh\n" + script + "\n")
                path.chmod(0o755)
            result = home / "result"
            forbidden = home / "forbidden"
            env = dict(os.environ, HOME=str(home), XDG_DATA_HOME=str(home / "data"),
                       PATH=f"{stubs}:/usr/bin:/bin", RESULT=str(result), FORBIDDEN=str(forbidden))
            cases = {
                "Dotfiles launcher test app": "dotfiles-test-app",
                "launcher-test-command 'argument with spaces'": "argument with spaces",
                "": None,
                "2 + 2": None,
                "https://example.org/": None,
                "a search query": None,
            }
            for query, expected in cases.items():
                with self.subTest(query=query):
                    result.unlink(missing_ok=True)
                    run = subprocess.run([str(REPO / "bin/x-run")],
                                         env=dict(env, MENU_VALUE=query),
                                         text=True, capture_output=True, timeout=10)
                    self.assertEqual(run.returncode, 0, run.stderr)
                    self.assertFalse(forbidden.exists())
                    if expected is None:
                        self.assertFalse(result.exists())
                    else:
                        self.assertEqual(result.read_text().strip(), expected)


if __name__ == "__main__":
    unittest.main()
