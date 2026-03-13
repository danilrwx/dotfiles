/**
 * Model price extension - shows price per 1M tokens in the status bar.
 *
 * Displays model pricing (input/output per 1M tokens) next to the session cost.
 * Updates automatically when model changes via /model command or Ctrl+P.
 *
 * Usage: Place in ~/.pi/agent/extensions/model-price.ts
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

interface ModelCost {
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
}

interface ModelInfo {
	id: string;
	provider: string;
	cost?: ModelCost;
}

export default function (pi: ExtensionAPI) {
	function updatePrice(ctx: ExtensionContext, model: ModelInfo) {
		if (!model?.cost) {
			ctx.ui.setStatus("model-price", "");
			return;
		}

		const { input, output } = model.cost;
		const inputStr = input === 0 ? "free" : `$${input.toFixed(1)}`;
		const outputStr = output === 0 ? "free" : `$${output.toFixed(1)}`;

		ctx.ui.setStatus("model-price", `💰 ${inputStr}/${outputStr}/1M`);
	}

	pi.on("model_select", async (event, ctx) => {
		updatePrice(ctx, event.model as ModelInfo);
	});

	pi.on("session_start", async (_event, ctx) => {
		const model = ctx.model;
		if (model) {
			updatePrice(ctx, {
				id: model.id,
				provider: "",
				cost: (model as any).cost,
			});
		}
	});
}
