import json
from pathlib import Path
import unittest

REPO = Path(__file__).resolve().parents[1]

class GamingInstallerTest(unittest.TestCase):

    def test_base_does_not_install_gaming_stack(self):
        source = (REPO / "install").read_text()
        for retired in ("scx_lavd", "sched_ext", "SCX_TAG", "steam-installer", "rust-clippy"):
            self.assertNotIn(retired, source)

    def test_drm_enabled(self):
        policies = json.loads((REPO / "etc/firefox/policies/policies.json").read_text())
        self.assertTrue(policies["policies"]["EncryptedMediaExtensions"]["Enabled"])
        self.assertIn('user_pref("media.eme.enabled", true);',
                      (REPO / "config/firefox/user.js").read_text())

if __name__ == "__main__":
    unittest.main()
