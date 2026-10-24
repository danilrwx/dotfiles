// bin/theme's current theme as Paseo's "dotfiles" (Settings → Appearance), its palette in shared/palette.ts,
// which bin/theme writes and then reloads this plugin
import { palette } from "./shared/palette";

export default function contribute(client: { addTheme(theme: object): () => void }) {
	client.addTheme({ id: "dotfiles", name: "dotfiles", ...palette });
	return () => {};
}
