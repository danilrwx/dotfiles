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
        result = subprocess.run([str(REPO / "install"), "--check"], env=self.env,
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
        self.assertIn("lolka-x", (REPO / "lib/install-game.sh").read_text())

    def test_old_lolka_does_not_skip_lolka_x_install(self):
        source = (REPO / "lib/install-game.sh").read_text()
        install_lolka = re.search(r"^lolka\(\) \{\n.*?^\}", source, re.MULTILINE | re.DOTALL)[0]
        stubs = r'''
installed() { [ "$1" = lolka ]; }
log() { :; }
curl() {
  [ "$4" = https://updates.lolka.app/desktop/linux/latest ] || return 1
  cat <<'JSON'
{"files":[
  {"name":"lolka-x.rpm"},
  {"name":"lolka-x_2.0_amd64.deb","url":"https://cdn.lolka.app/lolka-x.deb","sha512":"expected-hash"}
]}
JSON
}
deb_from() { printf '%s\n' "$@"; }
'''
        result = subprocess.run(["sh", "-ec", stubs + install_lolka + "\nlolka"],
                                capture_output=True, text=True, check=True, timeout=10)
        self.assertEqual(result.stdout.splitlines(),
                         ["https://cdn.lolka.app/lolka-x.deb", "expected-hash"])

    def test_debloat_preserves_base_packages(self):
        removed = set(re.search(r'^REMOVE="(.*?)"', (REPO / "debloat").read_text(),
                                re.MULTILINE | re.DOTALL)[1].split())
        source = (REPO / "install").read_text()
        for group in ("BASE_PKGS", "DESKTOP_PKGS", "WAYLAND_PKGS"):
            packages = set(re.search(r'^' + group + r'="(.*?)"', source,
                                     re.MULTILINE | re.DOTALL)[1].split())
            self.assertFalse(packages & removed, packages & removed)

class ShellTest(unittest.TestCase):
    def test_debloat_preserves_steam(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name, body in {
                "dpkg-query": 'case "$3" in gdm3|snapd|steam*|zenity|gamemode|lolka-x) echo installed;; esac',
                "snap": 'case "$TEST_STEAM_SNAP" in 1) echo "steam 1";; error) exit 1;; esac',
                "apt-mark": "echo iwd",
                "systemctl": "exit 1",
                "apt-get": 'printf "%s\\n" "$@" > "$HOME/apt-args"; printf "%s\\n" "$PLAN"',
            }.items():
                path = root / name
                path.write_text("#!/bin/sh\n" + body + "\n")
                path.chmod(0o755)

            for steam_snap, plan, expected in (
                ("0", "Purg gdm3", 0),
                ("1", "Purg gdm3", 0),
                ("0", "Purg steam-libs-i386:i386", 1),
                ("0", "Purg gamemode", 1),
                ("1", "Purg snapd", 1),
                ("error", "", 1),
            ):
                with self.subTest(steam_snap=steam_snap, plan=plan):
                    env = dict(os.environ, HOME=directory, PATH=f"{root}:/usr/bin:/bin",
                               TEST_STEAM_SNAP=steam_snap, PLAN=plan)
                    result = subprocess.run([str(REPO / "debloat"), "-n"], env=env,
                                            capture_output=True, text=True, timeout=15)
                    self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
                    if steam_snap == "error":
                        self.assertIn("Cannot list installed snaps", result.stdout)
                        continue
                    args = (root / "apt-args").read_text().splitlines()
                    self.assertIn("gdm3", args)
                    self.assertTrue(any(arg.startswith("APT::NeverAutoRemove::=") and "steam" in arg for arg in args))
                    self.assertFalse(any(arg.startswith("steam") for arg in args))
                    self.assertNotIn("zenity", args)
                    self.assertFalse({"gamemode", "lolka-x"} & set(args))
                    self.assertEqual("snapd" in args, steam_snap == "0")

    def test_alpine_desktop_keeps_device_manager(self):
        script = r'''
. "$1"
platform=alpine
id() {
  case "$1" in
    -un) echo desktop-user ;;
    -Gn) echo users ;;
    *) return 97 ;;
  esac
}
admin() {
  case "$1" in
    apk|addgroup|rc-update|rc-service) printf '%s\n' "$*" ;;
    *) printf 'Unexpected admin command: %s\n' "$*" >&2; return 97 ;;
  esac
}
portable_desktop_packages
'''
        result = subprocess.run(["sh", "-ec", script, "sh", str(REPO / "lib/install-session.sh")],
                                capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        packages, audio, *services = result.stdout.splitlines()
        self.assertTrue(packages.startswith("apk add "))
        self.assertTrue({"labwc", "dbus", "dbus-openrc", "seatd", "greetd-openrc"}
                        .issubset(packages.split()[2:]))
        self.assertTrue(audio.startswith("apk add pipewire "))
        self.assertEqual(services, [
            "addgroup desktop-user seat",
            "rc-update add cgroups default", "rc-service cgroups start",
            "rc-update add dbus default", "rc-service dbus start",
            "rc-update add seatd default", "rc-service seatd start",
        ])

    def test_posix_syntax(self):
        for name in ("install", "debloat", "lib/install.sh", "lib/install-dev.sh",
                     "lib/install-game.sh", "lib/install-session.sh", "bin/start-labwc"):
            with self.subTest(name=name):
                result = subprocess.run(["sh", "-n", str(REPO / name)], capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
        for name in ("install", "debloat", "bin/start-labwc"):
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
