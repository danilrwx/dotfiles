import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class WallpapersFetchTest(unittest.TestCase):
    def test_download_resume_and_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            catalog = home / 'dotfiles/config/themes/wallpapers.tsv'
            catalog.parent.mkdir(parents=True)
            catalog.write_text('# mode\tfilename\turl\tartist\ttitle\tsource\n'
                               'light\tone.jpg\tgood\tArtist\tTitle\tMuseum\n'
                               'dark\ttwo.jpg\tbad\tArtist\tTitle\tMuseum\n')
            stubs = home / 'stubs'
            stubs.mkdir()
            curl = stubs / 'curl'
            curl.write_text('#!/bin/sh\n'
                            'for arg do previous=$last; last=$arg; done\n'
                            'printf data > "$previous"\n'
                            '[ "$last" != bad ]\n')
            curl.chmod(0o755)
            env = dict(os.environ, HOME=str(home), XDG_DATA_HOME=str(home / 'data'),
                       PATH=f'{stubs}:/usr/bin:/bin')
            result = subprocess.run([str(REPO / 'bin/wallpapers-fetch')], env=env,
                                    capture_output=True, timeout=10)
            gallery = home / 'data/wallpapers/paintings'
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual((gallery / 'light/one.jpg').read_text(), 'data')
            self.assertFalse((gallery / 'dark/two.jpg').exists())
            (gallery / 'light/one.jpg').write_text('keep existing')
            catalog.write_text(catalog.read_text().replace('\tbad\t', '\tgood\t'))
            result = subprocess.run([str(REPO / 'bin/wallpapers-fetch')], env=env,
                                    capture_output=True, timeout=10)
            self.assertEqual(result.returncode, 0)
            self.assertEqual((gallery / 'light/one.jpg').read_text(), 'keep existing')
            self.assertEqual((gallery / 'dark/two.jpg').read_text(), 'data')
            self.assertFalse((gallery / 'dark/two.jpg.part').exists())
