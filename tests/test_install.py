"""Exercise the actual install dispatcher in an isolated HOME, without a session."""
import hashlib
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]

def snapshot(root):
    result = {}
    for parent, dirs, files in os.walk(root, followlinks=False):
        for name in dirs + files:
            path = Path(parent) / name
            info = path.lstat()
            content = None
            if path.is_symlink():
                content = os.readlink(path)
            elif stat.S_ISREG(info.st_mode):
                content = hashlib.sha256(path.read_bytes()).hexdigest()
            result[str(path.relative_to(root))] = (info.st_mode, info.st_mtime_ns, content)
    return result

class InstallerTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="dotfiles-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.home = self.root / "home with spaces"
        self.home.mkdir()
        (self.home / "dotfiles").symlink_to(REPO, target_is_directory=True)
        self.stubs = self.root / "stubs"
        self.stubs.mkdir()
        self.calls = self.root / "forbidden-calls"
        for name in ("sudo", "curl", "wget", "git", "go", "npm", "apt", "vim", "gsettings", "labwc"):
            self.stub(name)
        systemctl = self.stubs / "systemctl"
        systemctl.write_text('#!/bin/sh\nprintf "%s\\n" "$0 $*" >> "$FORBIDDEN_CALLS"\nexit 97\n')
        systemctl.chmod(0o755)
        self.env = dict(os.environ)
        for name in ("DISPLAY", "WAYLAND_DISPLAY", "LABWC_PID", "TMUX", "DBUS_SESSION_BUS_ADDRESS", "XDG_RUNTIME_DIR"):
            self.env.pop(name, None)
        self.env.update(HOME=str(self.home), PATH=f"{self.stubs}:/usr/local/bin:/usr/bin:/bin",
                        XDG_STATE_HOME=str(self.home / ".local/state"),
                        XDG_CONFIG_HOME=str(self.home / ".config"),
                        XDG_CACHE_HOME=str(self.home / ".cache"),
                        XDG_DATA_HOME=str(self.home / ".local/share"),
                        FORBIDDEN_CALLS=str(self.calls))

    def stub(self, name):
        script = self.stubs / name
        script.write_text('#!/bin/sh\nprintf "%s\\n" "$0 $*" >> "$FORBIDDEN_CALLS"\nexit 97\n')
        script.chmod(0o755)

    def run_install(self, *args, expected=0):
        proc = subprocess.run([str(REPO / "install"), *args], env=self.env,
                              text=True, capture_output=True, timeout=30)
        self.assertEqual(proc.returncode, expected, proc.stdout + proc.stderr)
        self.assertFalse(self.calls.exists(), self.calls.read_text() if self.calls.exists() else "")
        return proc

    def test_apply_and_repeat_are_idempotent(self):
        self.run_install("--configs")
        before = snapshot(self.home)
        self.assertEqual(before, snapshot(self.home))
        self.run_install("--configs")
        self.assertEqual(before, snapshot(self.home))
        self.assertFalse((self.home / ".local/state/dotfiles/backups").exists())

    def test_foot_updates_color_syntax_when_supported(self):
        foot = self.stubs / "foot"
        foot.write_text("#!/bin/sh\nexit 1\n")
        foot.chmod(0o755)
        self.run_install("--configs")
        config_dir = self.home / ".config/foot"
        self.assertTrue(config_dir.is_symlink())

        foot.write_text('#!/bin/sh\n[ "$*" = "--check-config --config /dev/null --override=initial-color-theme=dark" ]\n')
        self.run_install("--configs")
        self.assertFalse(config_dir.is_symlink())
        rendered = (config_dir / "foot.ini").read_text()
        self.assertIn("[colors-dark]\n", rendered)
        self.assertIn("[colors-light]\n", rendered)
        self.assertIn("/theme/foot-modern.ini\n", rendered)
        self.assertNotIn("[colors2]", rendered)
        self.assertNotIn("[colors]", rendered)
        before = snapshot(self.home)
        self.run_install("--configs")
        self.assertEqual(before, snapshot(self.home))

    def test_conflicts_and_old_bak_are_preserved(self):
        (self.home / ".bashrc").write_text("old bash config\n")
        (self.home / ".bashrc.bak").write_text("older bash config\n")
        (self.home / ".vimrc").write_text("old Vim config\n")
        retired = self.home / ".config/nvim"
        retired.parent.mkdir()
        retired.symlink_to(self.home / "dotfiles/config/nvim")
        (self.home / ".config/htop").symlink_to("missing-htop-config")
        self.run_install("--configs")
        runs = list((self.home / ".local/state/dotfiles/backups").iterdir())
        self.assertEqual(len(runs), 1)
        archive = runs[0] / str(self.home).lstrip("/")
        self.assertEqual((archive / ".bashrc").read_text(), "old bash config\n")
        self.assertEqual((archive / ".bashrc.bak").read_text(), "older bash config\n")
        self.assertEqual((archive / ".vimrc").read_text(), "old Vim config\n")
        self.assertTrue((self.home / ".vimrc").is_symlink())
        self.assertFalse(retired.is_symlink())
        self.assertEqual((archive / ".config/nvim").readlink(), self.home / "dotfiles/config/nvim")
        self.assertEqual(os.readlink(self.home / ".config/htop"), "missing-htop-config")
        first = snapshot(runs[0])
        (self.home / ".bashrc").unlink()
        (self.home / ".bashrc").write_text("second generation\n")
        self.run_install("--configs")
        self.assertEqual(len(list(runs[0].parent.iterdir())), 2)
        self.assertEqual(first, snapshot(runs[0]))

    def test_legacy_archives_migrate_once(self):
        old = self.home / ".local/state/dotfiles/retired/previous"
        old.mkdir(parents=True)
        (old / "config").write_text("preserved\n")
        old_x11 = self.home / ".local/state/dotfiles-x11"
        old_x11.mkdir()
        (old_x11 / "link").symlink_to("missing-legacy-target")
        self.run_install("--configs")
        self.assertFalse(old.exists())
        runs = list((self.home / ".local/state/dotfiles/backups").iterdir())
        self.assertEqual(len(runs), 1)
        archive = runs[0] / str(self.home).lstrip("/") / ".local/state"
        self.assertEqual((archive / "dotfiles/retired/previous/config").read_text(), "preserved\n")
        self.assertEqual(os.readlink(archive / "dotfiles-x11/link"), "missing-legacy-target")
        before = snapshot(self.home)
        self.run_install("--configs")
        self.assertEqual(before, snapshot(self.home))

if __name__ == "__main__":
    unittest.main()
