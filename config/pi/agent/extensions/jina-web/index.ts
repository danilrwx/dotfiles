/**
 * Jina web tools — WebSearch (s.jina.ai) and FetchContent (r.jina.ai).
 * Aligns with the project web-search skill; set JINA_API_KEY for search rate limits / access.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

const TIMEOUT_MS = 30_000;
const MAX_TEXT_CHARS = 512_000;

function jinaHeaders(extra?: Record<string, string>): Record<string, string> {
	const headers: Record<string, string> = {
		"User-Agent": "pi-jina-extension/1.0",
		Accept: "text/plain",
		...extra,
	};
	const apiKey = process.env.JINA_API_KEY;
	if (apiKey) {
		headers.Authorization = `Bearer ${apiKey}`;
	}
	return headers;
}

function mergeTimeoutSignal(signal: AbortSignal | undefined): AbortSignal {
	const timeout = AbortSignal.timeout(TIMEOUT_MS);
	if (!signal) {
		return timeout;
	}
	return AbortSignal.any([signal, timeout]);
}

function normalizeHttpUrl(raw: string): string | { error: string } {
	const trimmed = raw.trim();
	if (!trimmed) {
		return { error: "URL is empty." };
	}
	let parsed: URL;
	try {
		parsed = new URL(trimmed);
	} catch {
		return { error: `Invalid URL: ${raw}` };
	}
	if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
		return { error: `Only http and https URLs are allowed, got: ${parsed.protocol}` };
	}
	return parsed.toString();
}

async function readJinaResponse(
	response: Response,
): Promise<{ text: string; truncated: boolean }> {
	const text = (await response.text()).trim();
	if (text.length <= MAX_TEXT_CHARS) {
		return { text, truncated: false };
	}
	return {
		text:
			text.slice(0, MAX_TEXT_CHARS) +
			`\n\n… (truncated: ${text.length} characters, showing first ${MAX_TEXT_CHARS})`,
		truncated: true,
	};
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "web_search",
		label: (params) => `Web search: ${params.query}`,
		description:
			"Search the web via Jina Search API (s.jina.ai). Returns markdown snippets with titles, links, and descriptions. Set JINA_API_KEY when the API requires authentication.",
		promptSnippet: "Search the web (Jina); use JINA_API_KEY if search returns auth errors.",
		parameters: Type.Object({
			query: Type.String({
				description: "Search query (keywords or natural language).",
			}),
		}),

		async execute(_toolCallId, params, signal, onUpdate) {
			const { query } = params;
			onUpdate?.({
				content: [{ type: "text", text: `Searching: ${query}` }],
				details: { status: "loading" as const },
			});

			const encoded = encodeURIComponent(query);
			const url = `https://s.jina.ai/?q=${encoded}`;

			let response: Response;
			try {
				response = await fetch(url, {
					method: "GET",
					headers: jinaHeaders({
						"X-Respond-With": "no-content",
					}),
					signal: mergeTimeoutSignal(signal),
				});
			} catch (err) {
				const msg = err instanceof Error ? err.message : String(err);
				return {
					content: [{ type: "text", text: `Web search failed: ${msg}` }],
					details: { error: true },
				};
			}

			const { text, truncated } = await readJinaResponse(response);

			if (!response.ok) {
				return {
					content: [
						{
							type: "text",
							text: `Web search error (HTTP ${response.status}):\n\n${text || response.statusText}`,
						},
					],
					details: { error: true, status: response.status },
				};
			}

			if (!text) {
				return {
					content: [{ type: "text", text: "No search results. Try a different query." }],
					details: { empty: true },
				};
			}

			return {
				content: [{ type: "text", text: `## Search Results\n\n${text}` }],
				details: { query, truncated },
			};
		},
	});

	pi.registerTool({
		name: "fetch_content",
		label: (params) => `Fetch: ${params.url}`,
		description:
			"Fetch a public web page and return readable markdown via Jina Reader (r.jina.ai). Use for documentation, articles, or any http(s) URL. Optional JINA_API_KEY improves rate limits.",
		promptSnippet: "Fetch URL as markdown via Jina Reader.",
		parameters: Type.Object({
			url: Type.String({
				description: "Full http or https URL to fetch (e.g. https://example.com/docs).",
			}),
		}),

		async execute(_toolCallId, params, signal, onUpdate) {
			const normalized = normalizeHttpUrl(params.url);
			if (typeof normalized !== "string") {
				return {
					content: [{ type: "text", text: normalized.error }],
					details: { error: true },
				};
			}

			onUpdate?.({
				content: [{ type: "text", text: `Fetching: ${normalized}` }],
				details: { status: "loading" as const },
			});

			const readerUrl = `https://r.jina.ai/${normalized}`;

			let response: Response;
			try {
				response = await fetch(readerUrl, {
					method: "GET",
					headers: jinaHeaders(),
					signal: mergeTimeoutSignal(signal),
				});
			} catch (err) {
				const msg = err instanceof Error ? err.message : String(err);
				return {
					content: [{ type: "text", text: `Fetch failed: ${msg}` }],
					details: { error: true },
				};
			}

			const { text, truncated } = await readJinaResponse(response);

			if (!response.ok) {
				return {
					content: [
						{
							type: "text",
							text: `Fetch error (HTTP ${response.status}):\n\n${text || response.statusText}`,
						},
					],
					details: { error: true, status: response.status, url: normalized },
				};
			}

			if (!text) {
				return {
					content: [{ type: "text", text: "Empty response from reader." }],
					details: { empty: true, url: normalized },
				};
			}

			return {
				content: [{ type: "text", text }],
				details: { url: normalized, truncated },
			};
		},
	});
}
