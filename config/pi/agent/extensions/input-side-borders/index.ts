import { CustomEditor, type ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

const ANSI_RESET = /\x1b\[0m/g;
const OSC_CURSOR_MARKER = /\x1b\]133;A\x07/g;
const OSC_SHELL_INTEGRATION = /\x1b\]133;[BC]\x07/g;
const ANSI_PATTERN = /\x1b\[[0-9;]*m/g;

function stripAnsi(text: string): string {
	return text.replace(OSC_CURSOR_MARKER, "").replace(OSC_SHELL_INTEGRATION, "").replace(ANSI_PATTERN, "");
}

function isEditorBorder(text: string): boolean {
	const clean = stripAnsi(text).trim();
	return clean.length > 0 && /^─+(?: [↑↓] \d+ more ─*)?$/.test(clean);
}

class ScreenshotEditor extends CustomEditor {
	constructor(
		tui: ConstructorParameters<typeof CustomEditor>[0],
		theme: ConstructorParameters<typeof CustomEditor>[1],
		keybindings: ConstructorParameters<typeof CustomEditor>[2],
		private readonly uiTheme: ExtensionAPI["ui"]["theme"],
	) {
		super(tui, theme, keybindings);
		this.setPaddingX(0);
	}

	render(width: number): string[] {
		if (width <= 4) {
			return super.render(width);
		}

		const rawLines = super.render(width - 2);
		const bottomBorderIndex = [...rawLines].reverse().findIndex((line, indexFromEnd) => {
			if (indexFromEnd === rawLines.length - 1) return false;
			return isEditorBorder(line);
		});
		const resolvedBottomBorderIndex =
			bottomBorderIndex === -1 ? rawLines.length - 1 : rawLines.length - 1 - bottomBorderIndex;
		const bodyLines = rawLines.slice(1, resolvedBottomBorderIndex);
		const extraLines = rawLines.slice(resolvedBottomBorderIndex + 1);
		const bgAnsi = this.uiTheme.getBgAnsi("customMessageBg");
		const prompt = this.uiTheme.fg("muted", "› ");
		const continuation = "  ";

		const styledBody = bodyLines.map((line, index) => {
			const prefix = index === 0 ? prompt : continuation;
			const content = truncateToWidth(line, width - 2, "", true);
			const padded = `${prefix}${content}${" ".repeat(Math.max(0, width - visibleWidth(prefix) - visibleWidth(content)))}`;
			const withPersistentBg = padded.replace(ANSI_RESET, `\x1b[0m${bgAnsi}`);
			return `${bgAnsi}${withPersistentBg}\x1b[49m`;
		});

		return [...styledBody, ...extraLines];
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		if (!ctx.hasUI) return;
		ctx.ui.setEditorComponent((tui, theme, keybindings) => new ScreenshotEditor(tui, theme, keybindings, ctx.ui.theme));
	});
}
