import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class ThemeTest(unittest.TestCase):
    def test_selection_toggle_and_invalid_argument(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            (home / 'dotfiles').symlink_to(REPO)
            stubs = home / 'stubs'
            stubs.mkdir()
            calls = home / 'calls'
            for name in ('pkill', 'gsettings', 'dunstctl', 'labwc', 'systemctl', 'systemd-run'):
                tool = stubs / name
                tool.write_text('#!/bin/sh\nprintf "%s\\n" "${0##*/} $*" >> "$CALLS"\n')
                tool.chmod(0o755)
            with (stubs / 'systemctl').open('a') as script:
                script.write('exit 5\n')  # The transient unit does not exist on the first switch.
            env = dict(os.environ, HOME=str(home), PATH=f'{stubs}:/usr/bin:/bin',
                       CALLS=str(calls), XDG_DATA_HOME=str(home / 'data'),
                       XDG_STATE_HOME=str(home / 'state'),
                       XDG_CURRENT_DESKTOP='labwc', WAYLAND_DISPLAY='wayland-test')
            def run(mode):
                return subprocess.run([str(REPO / 'bin/x-theme'), mode], env=env,
                                      text=True, capture_output=True, timeout=10)
            theme = home / '.config/dotfiles/theme'
            self.assertEqual(run('light').returncode, 0)
            self.assertEqual((theme / 'name').read_text(), 'light\n')
            self.assertIn('pkill -USR2', calls.read_text())
            self.assertIn('color-scheme prefer-light', calls.read_text())
            self.assertIn('--image ' + str(theme / 'wallpaper.jpg') + ' --mode fill', calls.read_text())
            self.assertIn('--setenv=WAYLAND_DISPLAY=wayland-test', calls.read_text())
            self.assertEqual(run('toggle').returncode, 0)
            self.assertEqual((theme / 'name').read_text(), 'dark\n')
            self.assertIn('pkill -USR1', calls.read_text())
            self.assertEqual(run('light').returncode, 0)
            self.assertIn('swaybg --color #b9a477', calls.read_text())
            self.assertIn('labwc --reconfigure', calls.read_text())
            self.assertEqual(run('dark').returncode, 0)
            self.assertIn('swaybg --color #000000', calls.read_text())
            gallery = home / 'data/wallpapers/paintings/light'
            gallery.mkdir(parents=True)
            first, second = gallery / 'first.jpg', gallery / 'second.jpg'
            first.touch()
            self.assertEqual(run('light').returncode, 0)
            state = home / 'state/dotfiles/wallpaper-light'
            self.assertEqual(state.read_text().strip(), str(first))
            second.touch()
            for _ in range(6):
                previous = state.read_text().strip()
                self.assertEqual(run('light').returncode, 0)
                selected = state.read_text().strip()
                self.assertIn(selected, (str(first), str(second)))
                self.assertNotEqual(selected, previous)
                self.assertIn('--image ' + selected + ' --mode fill', calls.read_text())
            first.unlink()
            second.unlink()
            self.assertEqual(run('light').returncode, 0)
            self.assertEqual(state.read_text().strip(), str(theme / 'wallpaper.jpg'))
            self.assertEqual(run('dark').returncode, 0)
            before = calls.read_text()
            self.assertEqual(run('invalid').returncode, 1)
            self.assertEqual(calls.read_text(), before)
            self.assertEqual((theme / 'name').read_text(), 'dark\n')
