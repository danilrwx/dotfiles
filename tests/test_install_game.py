import json
from pathlib import Path
import unittest

REPO = Path(__file__).resolve().parents[1]

class GamingInstallerTest(unittest.TestCase):

    def test_gaming_installer_uses_flatpak_without_host_i386_packages(self):
        source = (REPO / "lib/install-game.sh").read_text()
        self.assertIn("flathub com.valvesoftware.Steam", source)
        for native_setup in ("steam-installer", "--add-architecture", ":i386"):
            self.assertNotIn(native_setup, source)

    def test_gaming_setup_has_no_separate_login_session(self):
        source = (REPO / "lib/install-game.sh").read_text()
        self.assertNotIn("greetd", source)
        self.assertIn("--cmd /usr/bin/labwc", (REPO / "etc/greetd/config.toml").read_text())

    def test_drm_enabled(self):
        policies = json.loads((REPO / "etc/firefox/policies/policies.json").read_text())
        self.assertTrue(policies["policies"]["EncryptedMediaExtensions"]["Enabled"])
        self.assertIn('user_pref("media.eme.enabled", true);',
                      (REPO / "config/firefox/user.js").read_text())

if __name__ == "__main__":
    unittest.main()
