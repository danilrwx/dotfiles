import { CustomEditor, type ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth } from "@mariozechner/pi-tui";

class SideBorderEditor extends CustomEditor {
	render(width: number): string[] {
		if (width <= 2) {
			return super.render(width);
		}

		const innerWidth = width - 2;
		const border = this.borderColor("│");

		return super
			.render(innerWidth)
			.map((line) => `${border}${truncateToWidth(line, innerWidth, "", true)}${border}`);
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		if (!ctx.hasUI) return;
		ctx.ui.setEditorComponent((tui, theme, keybindings) => new SideBorderEditor(tui, theme, keybindings));
	});
}
