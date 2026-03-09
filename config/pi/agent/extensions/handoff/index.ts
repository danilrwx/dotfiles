/**
 * Handoff extension - transfer context to a new focused session
 *
 * Instead of compacting (which is lossy), handoff extracts what matters
 * for your next task and creates a new session with a generated prompt.
 *
 * Provides both:
 * - /handoff command: user types `/handoff <goal>`
 * - handoff tool: agent can call when user explicitly requests a handoff
 *
 * Usage:
 *   /handoff now implement this for teams as well
 *   /handoff -mode rush execute phase one of the plan
 *   /handoff -model anthropic/claude-haiku-4-5 check other places that need this fix
 *
 * The generated prompt appears as a draft in the editor for review/editing.
 */

import { complete, type Message } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionCommandContext, ExtensionContext, SessionEntry } from "@mariozechner/pi-coding-agent";
import { BorderedLoader, convertToLlm, serializeConversation } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

const SYSTEM_PROMPT = `You are a context transfer assistant. Given a conversation history and the user's goal for a new thread, generate a focused prompt that:

1. Summarizes relevant context from the conversation (decisions made, approaches taken, key findings)
2. Lists any relevant files that were discussed or modified
3. Clearly states the next task based on the user's goal
4. Is self-contained - the new thread should be able to proceed without the old conversation

Format your response as a prompt the user can send to start the new thread. Be concise but include all necessary context. Do not include any preamble like "Here's the prompt" - just output the prompt itself.

Example output format:
## Context
We've been working on X. Key decisions:
- Decision 1
- Decision 2

Files involved:
- path/to/file1.ts
- path/to/file2.ts

## Task
[Clear description of what to do next based on user's goal]`;

type HandoffOptions = {
	mode?: string;
	model?: string;
};

/**
 * Load a mode spec from modes.json by name.
 * Returns the spec if found, or undefined.
 */
async function loadModeSpec(
	cwd: string,
	modeName: string,
): Promise<{ provider?: string; modelId?: string; thinkingLevel?: string } | undefined> {
	const fsModule = await import("node:fs");
	const pathModule = await import("node:path");
	const osModule = await import("node:os");

	const expandUser = (p: string) => {
		if (p === "~") return osModule.homedir();
		if (p.startsWith("~/")) return pathModule.join(osModule.homedir(), p.slice(2));
		return p;
	};

	const agentDir = process.env.PI_CODING_AGENT_DIR
		? expandUser(process.env.PI_CODING_AGENT_DIR)
		: pathModule.join(osModule.homedir(), ".pi", "agent");

	// Check project modes first, then global
	const candidates = [
		pathModule.join(cwd, ".pi", "modes.json"),
		pathModule.join(agentDir, "modes.json"),
	];

	for (const modesPath of candidates) {
		try {
			const raw = fsModule.readFileSync(modesPath, "utf8");
			const parsed = JSON.parse(raw);
			if (parsed.modes && typeof parsed.modes === "object" && parsed.modes[modeName]) {
				const spec = parsed.modes[modeName];
				return {
					provider: typeof spec.provider === "string" ? spec.provider : undefined,
					modelId: typeof spec.modelId === "string" ? spec.modelId : undefined,
					thinkingLevel: typeof spec.thinkingLevel === "string" ? spec.thinkingLevel : undefined,
				};
			}
		} catch {
			continue;
		}
	}
	return undefined;
}

/**
 * Apply -mode and -model options after a session switch.
 * For -mode, reads mode spec from modes.json and applies model+thinking.
 * For -model, applies the model directly.
 * The modes extension will sync its state from the resulting model_select event.
 */
async function applyHandoffOptions(
	pi: ExtensionAPI,
	ctx: ExtensionContext,
	options?: HandoffOptions,
): Promise<void> {
	if (!options) return;

	if (options.mode) {
		const spec = await loadModeSpec(ctx.cwd, options.mode);
		if (spec) {
			if (spec.provider && spec.modelId) {
				const model = ctx.modelRegistry.find(spec.provider, spec.modelId);
				if (model) {
					await pi.setModel(model);
				} else {
					ctx.hasUI && ctx.ui.notify(`Handoff: mode "${options.mode}" references unknown model ${spec.provider}/${spec.modelId}`, "warning");
				}
			}
			if (spec.thinkingLevel) {
				pi.setThinkingLevel(spec.thinkingLevel as any);
			}
		} else {
			ctx.hasUI && ctx.ui.notify(`Handoff: unknown mode "${options.mode}"`, "warning");
		}
	}

	if (options.model) {
		// Parse "provider/modelId" format
		const slashIdx = options.model.indexOf("/");
		if (slashIdx > 0) {
			const provider = options.model.slice(0, slashIdx);
			const modelId = options.model.slice(slashIdx + 1);
			const model = ctx.modelRegistry.find(provider, modelId);
			if (model) {
				await pi.setModel(model);
			} else {
				ctx.hasUI && ctx.ui.notify(`Handoff: unknown model ${options.model}`, "warning");
			}
		} else {
			ctx.hasUI && ctx.ui.notify(`Handoff: invalid model format "${options.model}", expected provider/modelId`, "warning");
		}
	}
}

/**
 * Core handoff logic. Returns an error string on failure, or undefined on success.
 */
async function performHandoff(
	pi: ExtensionAPI,
	ctx: ExtensionContext,
	goal: string,
	pendingHandoff: { prompt: string; parentSession: string | undefined; options?: HandoffOptions } | null,
	setPendingHandoff: (v: { prompt: string; parentSession: string | undefined; options?: HandoffOptions } | null) => void,
	fromTool = false,
	options?: HandoffOptions,
): Promise<string | undefined> {
	if (!ctx.hasUI) {
		return "Handoff requires interactive mode.";
	}

	if (!ctx.model) {
		return "No model selected.";
	}

	const branch = ctx.sessionManager.getBranch();
	const messages = branch
		.filter((entry): entry is SessionEntry & { type: "message" } => entry.type === "message")
		.map((entry) => entry.message);

	if (messages.length === 0) {
		return "No conversation to hand off.";
	}

	const llmMessages = convertToLlm(messages);
	const conversationText = serializeConversation(llmMessages);
	const currentSessionFile = ctx.sessionManager.getSessionFile();

	// Generate the handoff prompt with loader UI
	const result = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
		const loader = new BorderedLoader(tui, theme, `Generating handoff prompt...`);
		loader.onAbort = () => done(null);

		const doGenerate = async () => {
			const apiKey = await ctx.modelRegistry.getApiKey(ctx.model!);

			const userMessage: Message = {
				role: "user",
				content: [
					{
						type: "text",
						text: `## Conversation History\n\n${conversationText}\n\n## User's Goal for New Thread\n\n${goal}`,
					},
				],
				timestamp: Date.now(),
			};

			const response = await complete(
				ctx.model!,
				{ systemPrompt: SYSTEM_PROMPT, messages: [userMessage] },
				{ apiKey, signal: loader.signal },
			);

			if (response.stopReason === "aborted") {
				return null;
			}

			return response.content
				.filter((c): c is { type: "text"; text: string } => c.type === "text")
				.map((c) => c.text)
				.join("\n");
		};

		doGenerate()
			.then(done)
			.catch((err) => {
				console.error("Handoff generation failed:", err);
				done(null);
			});

		return loader;
	});

	if (result === null) {
		return "Handoff cancelled.";
	}

	// Build the final prompt with user's goal first for easy identification
	let finalPrompt = result;
	if (currentSessionFile) {
		finalPrompt = `${goal}\n\n/skill:session-query\n\n**Parent session:** \`${currentSessionFile}\`\n\n${result}`;
	} else {
		finalPrompt = `${goal}\n\n${result}`;
	}

	if (!fromTool && "newSession" in ctx) {
		// Command path: full reset via ctx.newSession()
		const cmdCtx = ctx as ExtensionCommandContext;
		const newSessionResult = await cmdCtx.newSession({ parentSession: currentSessionFile });
		if (newSessionResult.cancelled) return;
		await applyHandoffOptions(pi, ctx, options);
		pi.sendUserMessage(finalPrompt);
	} else {
		// Tool path: defer session switch to agent_end handler.
		// We can't call ctx.newSession() from tool context (only ExtensionCommandContext
		// has it). Instead, we store the handoff data and let the agent_end handler
		// perform the session switch after the current agent loop completes.
		// The context event handler ensures the LLM only sees new-session messages.
		setPendingHandoff({ prompt: finalPrompt, parentSession: currentSessionFile, options });
	}

	return undefined;
}

export default function (pi: ExtensionAPI) {
	// Shared state for tool-path handoff coordination between handlers
	let pendingHandoff: { prompt: string; parentSession: string | undefined; options?: HandoffOptions } | null = null;

	// Timestamp marking when the handoff session switch occurred.
	// Used by the context event handler to filter out pre-handoff messages
	// from agent.state.messages (which aren't cleared by the low-level switch).
	let handoffTimestamp: number | null = null;

	const setPendingHandoff = (v: { prompt: string; parentSession: string | undefined; options?: HandoffOptions } | null) => {
		pendingHandoff = v;
	};

	// --- Event handlers for tool-path handoff ---
	//
	// WHY IS THIS SO COMPLICATED?
	//
	// The /handoff command path is simple: it has ExtensionCommandContext with
	// ctx.newSession() which does a full agent state reset (agent.reset() +
	// UI clear + queue reset + event emission). But the tool path only gets
	// ExtensionContext, which lacks newSession().
	//
	// Simpler approaches don't work:
	// - sendUserMessage("/new") doesn't expand slash commands
	// - There's no public API to programmatically invoke commands from tool context
	// - sessionManager.newSession() only switches the session file; it does NOT
	//   clear agent.state.messages, so the LLM would still see the entire old
	//   conversation
	// - We can't call agent.reset() from tool context either
	//
	// The solution uses three coordinated event handlers:
	//
	// 1. agent_end: Defers the session switch until after the agent loop completes.
	//    This ensures the tool_result is recorded in the old session first, and
	//    avoids concurrent _runLoop instances. Uses sessionManager.newSession()
	//    for the file switch, then setTimeout(() => sendUserMessage()) to start
	//    the new session in the next macrotask.
	//
	// 2. context: Filters pre-handoff messages using a timestamp. Since we can't
	//    call agent.reset(), old messages remain in agent.state.messages, but the
	//    context event's transformContext mechanism lets us control what the LLM
	//    actually sees. This is safe because getContextUsage() uses the last
	//    assistant's actual usage data (correct after the first response), and
	//    auto-compaction checks assistant usage tokens rather than the messages
	//    array length.
	//
	// 3. session_switch: Clears the context filter when a proper session switch
	//    occurs (e.g., /new), since those fully reset agent.state.messages and
	//    our filter would incorrectly hide the new session's messages.

	// After the agent loop ends, perform the deferred session switch.
	// At this point:
	// - The tool_result has been recorded in the OLD session
	// - The agent is idle (isStreaming = false)
	// - We can safely switch sessions and start a new prompt
	pi.on("agent_end", (_event, ctx) => {
		if (!pendingHandoff) return;

		const { prompt, parentSession, options } = pendingHandoff;
		pendingHandoff = null;

		// Record timestamp BEFORE switching - all old messages have timestamps
		// before this, all new messages will have timestamps after.
		handoffTimestamp = Date.now();

		// Low-level session switch: creates new session file, resets entries.
		// This does NOT clear agent.state.messages (we handle that via context event).
		(ctx.sessionManager as any).newSession({ parentSession });

		// Defer sendUserMessage to the next macrotask to ensure the old agent
		// loop's _runLoop cleanup has fully completed (isStreaming reset,
		// runningPrompt resolved). Without this, we'd have two concurrent
		// _runLoop instances with conflicting state.
		setTimeout(async () => {
			await applyHandoffOptions(pi, ctx, options);
			pi.sendUserMessage(prompt);
		}, 0);
	});

	// Before each LLM call, filter out pre-handoff messages.
	// After a tool-path handoff, agent.state.messages still contains all old
	// messages (since we can't call agent.reset()). The context event lets us
	// replace what the LLM sees without affecting agent internals.
	//
	// This is safe because:
	// - getContextUsage() uses the last assistant message's usage data, which
	//   will reflect the small new-session context after the first response
	// - Auto-compaction checks the assistant message's usage tokens, not
	//   agent.state.messages, so won't trigger incorrectly
	// - The session file only contains new-session entries (correct for
	//   token/cost display and session persistence)
	pi.on("context", (event) => {
		if (handoffTimestamp === null) return;

		const newMessages = event.messages.filter((m: any) => m.timestamp >= handoffTimestamp);
		if (newMessages.length > 0) {
			return { messages: newMessages };
		}
		// No messages pass the filter - shouldn't happen in normal flow,
		// but don't break things by returning empty messages
	});

	// When a proper session switch occurs (e.g., /new, tree navigation, /switch),
	// agent.state.messages is fully reset by AgentSession.newSession(). Clear our
	// filter so we don't interfere with the properly-reset state.
	pi.on("session_switch", () => {
		handoffTimestamp = null;
	});

	// /handoff command
	pi.registerCommand("handoff", {
		description: "Transfer context to a new focused session (-mode <name>, -model <provider/id>)",
		handler: async (args, ctx) => {
			// Parse optional -mode and -model flags from args
			const options: HandoffOptions = {};
			let remaining = args;

			const modeMatch = remaining.match(/(?:^|\s)-mode\s+(\S+)/);
			if (modeMatch) {
				options.mode = modeMatch[1];
				remaining = remaining.replace(modeMatch[0], " ");
			}

			const modelMatch = remaining.match(/(?:^|\s)-model\s+(\S+)/);
			if (modelMatch) {
				options.model = modelMatch[1];
				remaining = remaining.replace(modelMatch[0], " ");
			}

			const goal = remaining.trim();
			if (!goal) {
				ctx.ui.notify("Usage: /handoff [-mode <name>] [-model <provider/id>] <goal>", "error");
				return;
			}

			const hasOptions = options.mode || options.model;
			const error = await performHandoff(pi, ctx, goal, pendingHandoff, setPendingHandoff, false, hasOptions ? options : undefined);
			if (error) {
				ctx.ui.notify(error, "error");
			}
		},
	});

	// handoff tool (agent-callable)
	pi.registerTool({
		name: "handoff",
		label: "Handoff",
		description:
			"Transfer context to a new focused session. ONLY use this when the user explicitly asks for a handoff. Provide a goal describing what the new session should focus on.",
		parameters: Type.Object({
			goal: Type.String({ description: "The goal/task for the new session" }),
			mode: Type.Optional(Type.String({ description: "Amplike mode name to start the new session with (e.g. 'rush', 'smart', 'deep')" })),
			model: Type.Optional(Type.String({ description: "Model to start the new session with, as provider/modelId (e.g. 'anthropic/claude-haiku-4-5')" })),
		}),

		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const options: HandoffOptions = {};
			if (params.mode) options.mode = params.mode;
			if (params.model) options.model = params.model;
			const hasOptions = options.mode || options.model;
			const error = await performHandoff(pi, ctx, params.goal, pendingHandoff, setPendingHandoff, true, hasOptions ? options : undefined);
			return {
				content: [{ type: "text", text: error ?? "Handoff initiated. The session will switch after the current turn completes." }],
			};
		},
	});
}
