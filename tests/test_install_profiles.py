import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

import test_install as fixture

REPO = fixture.REPO

class ProfileTest(unittest.TestCase):
    setUp = fixture.InstallerTest.setUp
    stub = fixture.InstallerTest.stub
    run_install = fixture.InstallerTest.run_install

    def test_removed_check_option_fails_before_changes(self):
        before = fixture.snapshot(self.home)
        for name in ("install", "install_dev", "install_game"):
            with self.subTest(name=name):
                result = subprocess.run([str(REPO / name), "--check"], env=self.env,
                                        text=True, capture_output=True, timeout=10)
                self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                self.assertIn("Unknown option", result.stderr)
        self.assertEqual(before, fixture.snapshot(self.home))
        self.assertFalse(self.calls.exists())

    def test_fetch_preserves_callers_variables_and_checks_hash(self):
        source = self.root / "asset"
        source.write_text("expected contents\n")
        curl = self.stubs / "curl"
        curl.write_text('#!/bin/sh\ncp "$ASSET" "$3"\n')
        curl.chmod(0o755)
        target = self.root / "download"
        script = '''. "$LIB"
src=caller-src; dst=caller-dst; file=caller-file
checksum=$(sha256sum "$ASSET" | cut -d ' ' -f 1)
fetch https://example.org/asset "$TARGET" "$checksum" || exit 1
cmp "$ASSET" "$TARGET" || exit 2
fetch https://example.org/asset "$TARGET" invalid && exit 3
[ ! -e "$TARGET" ] || exit 4
[ "$src:$dst:$file" = caller-src:caller-dst:caller-file ]
'''
        env = dict(self.env, ASSET=str(source), TARGET=str(target),
                   LIB=str(REPO / "lib/install.sh"))
        result = subprocess.run(["sh", "-c", script], env=env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_deb_download_failure_is_not_success(self):
        env = dict(self.env, LIB=str(REPO / "lib/install.sh"), TMPDIR=str(self.root))
        script = '. "$LIB"\ndeb_from https://example.org/missing.deb\n'
        result = subprocess.run(["sh", "-c", script], env=env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 97, result.stdout + result.stderr)
        self.assertEqual(list(self.root.glob("*.deb")), [])

    def test_lolka_and_bluetui_are_not_base_requirements(self):
        source = (REPO / "install").read_text()
        self.assertNotIn("lolka", source)
        self.assertNotIn("bluetui", source)
        self.assertIn("lolka-x", (REPO / "install_game").read_text())

    def test_debloat_preserves_base_packages(self):
        removed = set(re.search(r'^REMOVE="(.*?)"', (REPO / "debloat").read_text(),
                                re.MULTILINE | re.DOTALL)[1].split())
        source = (REPO / "install").read_text()
        for group in ("BASE_PKGS", "DESKTOP_PKGS", "WAYLAND_PKGS"):
            packages = set(re.search(r'^' + group + r'="(.*?)"', source,
                                     re.MULTILINE | re.DOTALL)[1].split())
            self.assertFalse(packages & removed, packages & removed)

class ShellTest(unittest.TestCase):
    def test_posix_syntax(self):
        for name in ("install", "install_dev", "install_game", "debloat", "lib/install.sh"):
            with self.subTest(name=name):
                result = subprocess.run(["sh", "-n", str(REPO / name)], capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
        for name in ("install", "install_dev", "install_game", "debloat"):
            self.assertEqual((REPO / name).read_text().splitlines()[0], "#!/bin/sh")

    def test_debloat_empty_list_does_not_autoremove(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            home = root / "home"
            home.mkdir()
            for name, body in {
                "dpkg-query": "exit 1",
                "snap": "exit 0",
                "apt-mark": "echo iwd",
                "systemctl": "exit 1",
                "sudo": 'echo forbidden >&2; exit 97',
                "apt-get": 'echo forbidden >&2; exit 97',
            }.items():
                path = root / name
                path.write_text("#!/bin/sh\n" + body + "\n")
                path.chmod(0o755)
            env = dict(os.environ, HOME=str(home), PATH=f"{root}:/usr/bin:/bin")
            result = subprocess.run([str(REPO / "debloat"), "-n"], env=env,
                                    text=True, capture_output=True, timeout=15)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertNotIn("forbidden", result.stderr)
            self.assertEqual(list(home.iterdir()), [])

if __name__ == "__main__":
    unittest.main()
