/**
 * golangci-lint Hook Extension for pi-coding-agent
 *
 * Automatically runs golangci-lint --fix after editing .go files.
 * Can run after each write/edit or once per agent response.
 *
 * Usage:
 *   pi install ./path/to/golangci-lint
 *   Or use npm package if published
 */

import * as path from "node:path";
import * as fs from "node:fs";
import * as child_process from "node:child_process";
import { type ExtensionAPI, type ExtensionContext } from "@mariozechner/pi-coding-agent";

type HookMode = "edit_write" | "agent_end" | "disabled";

const DEFAULT_HOOK_MODE: HookMode = "edit_write";
const SETTINGS_NAMESPACE = "golangci-lint";
const CONFIG_ENTRY = "golangci-lint-config";

const GREEN = "\x1b[32m", YELLOW = "\x1b[33m", RESET = "\x1b[0m";

interface HookConfigEntry {
  scope: "session" | "global";
  hookMode?: HookMode;
}

function normalizeHookMode(value: unknown): HookMode | undefined {
  if (value === "edit_write" || value === "agent_end" || value === "disabled") return value;
  if (value === "turn_end") return "agent_end";
  return undefined;
}

export default function (pi: ExtensionAPI) {
  let statusUpdateFn: ((key: string, text: string | undefined) => void) | null = null;
  let hookMode: HookMode = DEFAULT_HOOK_MODE;
  
  const touchedFiles: Set<string> = new Set();
  const globalSettingsPath = path.join(process.env.HOME || "", ".pi", "agent", "settings.json");

  function readSettingsFile(filePath: string): Record<string, unknown> {
    try {
      if (!fs.existsSync(filePath)) return {};
      const raw = fs.readFileSync(filePath, "utf-8");
      const parsed = JSON.parse(raw);
      return parsed && typeof parsed === "object" ? parsed as Record<string, unknown> : {};
    } catch {
      return {};
    }
  }

  function getGlobalHookMode(): HookMode | undefined {
    const settings = readSettingsFile(globalSettingsPath);
    const lspSettings = settings[SETTINGS_NAMESPACE];
    const hookValue = (lspSettings as { hookMode?: unknown } | undefined)?.hookMode;
    return normalizeHookMode(hookValue);
  }

  function setGlobalHookMode(mode: HookMode): boolean {
    try {
      const settings = readSettingsFile(globalSettingsPath);
      const existing = settings[SETTINGS_NAMESPACE];
      const nextNamespace = (existing && typeof existing === "object")
        ? { ...(existing as Record<string, unknown>), hookMode: mode }
        : { hookMode: mode };

      settings[SETTINGS_NAMESPACE] = nextNamespace;
      fs.mkdirSync(path.dirname(globalSettingsPath), { recursive: true });
      fs.writeFileSync(globalSettingsPath, JSON.stringify(settings, null, 2), "utf-8");
      return true;
    } catch {
      return false;
    }
  }

  function getLastHookEntry(ctx: ExtensionContext): HookConfigEntry | undefined {
    const branchEntries = ctx.sessionManager.getBranch();
    let latest: HookConfigEntry | undefined;

    for (const entry of branchEntries) {
      if (entry.type === "custom" && entry.customType === CONFIG_ENTRY) {
        latest = entry.data as HookConfigEntry | undefined;
      }
    }

    return latest;
  }

  function restoreHookState(ctx: ExtensionContext): void {
    const entry = getLastHookEntry(ctx);
    if (entry?.scope === "session") {
      const normalized = normalizeHookMode(entry.hookMode);
      if (normalized) {
        hookMode = normalized;
        return;
      }
    }

    const globalSetting = getGlobalHookMode();
    hookMode = globalSetting ?? DEFAULT_HOOK_MODE;
  }

  function persistHookEntry(entry: HookConfigEntry): void {
    pi.appendEntry<HookConfigEntry>(CONFIG_ENTRY, entry);
  }

  function updateStatus(): void {
    if (!statusUpdateFn) return;

    if (hookMode === "disabled") {
      statusUpdateFn("golangci-lint", undefined);
      return;
    }

    const color = hookMode === "agent_end" ? YELLOW : GREEN;
    statusUpdateFn("golangci-lint", `${color}golangci-lint${RESET}`);
  }

  function isGoFile(filePath: string): boolean {
    return path.extname(filePath).toLowerCase() === ".go";
  }

  /**
   * Find the nearest go.mod file by traversing up from the given file path.
   * Returns the directory containing go.mod, or undefined if not found.
   */
  function findNearestGoMod(filePath: string): string | undefined {
    let currentDir = path.dirname(filePath);
    const root = path.parse(currentDir).root;

    while (currentDir !== root) {
      if (fs.existsSync(path.join(currentDir, "go.mod"))) {
        return currentDir;
      }
      currentDir = path.dirname(currentDir);
    }

    // Check root as well
    if (fs.existsSync(path.join(root, "go.mod"))) {
      return root;
    }

    return undefined;
  }

  function runGolangciLint(filePath: string, cwd: string): { success: boolean; output: string; fixes: string[]; workingDir: string } {
    const fixes: string[] = [];
    
    // Check if golangci-lint is available
    try {
      child_process.execSync("which golangci-lint", { stdio: "ignore", cwd });
    } catch {
      return { success: false, output: "golangci-lint not found in PATH", fixes: [], workingDir: cwd };
    }

    // Find nearest go.mod from the file, fallback to cwd
    const moduleRoot = findNearestGoMod(filePath) || cwd;

    // Check if go.mod exists in the found directory
    if (!fs.existsSync(path.join(moduleRoot, "go.mod"))) {
      return { success: false, output: "go.mod not found", fixes: [], workingDir: moduleRoot };
    }

    try {
      // Run golangci-lint with --fix for the specific file
      // Use the module root as cwd
      const result = child_process.execSync(
        `golangci-lint run --fix --timeout 5m ${filePath} 2>&1`,
        {
          cwd: moduleRoot,
          encoding: "utf-8",
          maxBuffer: 10 * 1024 * 1024, // 10MB
        }
      );

      return { success: true, output: result || "No fixes applied", fixes, workingDir: moduleRoot };
    } catch (error: any) {
      // golangci-lint returns non-zero if there are errors, but --fix might still work
      if (error.stdout) {
        return { success: true, output: error.stdout as string, fixes, workingDir: moduleRoot };
      }
      return { success: false, output: (error.message as string) || "Unknown error", fixes, workingDir: moduleRoot };
    }
  }

  pi.registerCommand("golangci-lint", {
    description: "golangci-lint settings",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify("golangci-lint settings require UI", "warning");
        return;
      }

      const currentMark = " ✓";
      const modeOptions: { mode: HookMode; label: string }[] = [
        { mode: "edit_write", label: `After each edit/write${hookMode === "edit_write" ? currentMark : ""}` },
        { mode: "agent_end", label: `At agent end${hookMode === "agent_end" ? currentMark : ""}` },
        { mode: "disabled", label: `Disabled${hookMode === "disabled" ? currentMark : ""}` },
      ];

      const modeChoice = await ctx.ui.select(
        "golangci-lint hook mode:",
        modeOptions.map((o) => o.label),
      );
      if (!modeChoice) return;

      const nextMode = modeOptions.find((o) => o.label === modeChoice)?.mode;
      if (!nextMode) return;

      const scopeOptions = [
        { scope: "session" as const, label: "Session only" },
        { scope: "global" as const, label: "Global (all sessions)" },
      ];

      const scopeChoice = await ctx.ui.select(
        "Apply setting to:",
        scopeOptions.map((o) => o.label),
      );
      if (!scopeChoice) return;

      const scope = scopeOptions.find((o) => o.label === scopeChoice)?.scope;
      if (!scope) return;

      if (scope === "global") {
        const ok = setGlobalHookMode(nextMode);
        if (!ok) {
          ctx.ui.notify("Failed to update global settings", "error");
          return;
        }
      }

      hookMode = nextMode;
      touchedFiles.clear();
      persistHookEntry({ scope, hookMode: nextMode });
      updateStatus();
      ctx.ui.notify(`golangci-lint: ${nextMode} (${scope})`, "info");
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    restoreHookState(ctx);
    statusUpdateFn = ctx.hasUI && ctx.ui.setStatus ? ctx.ui.setStatus.bind(ctx.ui) : null;
    updateStatus();
  });

  pi.on("session_switch", async (_event, ctx) => {
    restoreHookState(ctx);
    updateStatus();
  });

  pi.on("session_tree", async (_event, ctx) => {
    restoreHookState(ctx);
    updateStatus();
  });

  pi.on("session_fork", async (_event, ctx) => {
    restoreHookState(ctx);
    updateStatus();
  });

  pi.on("session_shutdown", async () => {
    touchedFiles.clear();
    statusUpdateFn?.("golangci-lint", undefined);
  });

  pi.on("agent_start", async () => {
    touchedFiles.clear();
  });

  pi.on("agent_end", async (_event, ctx) => {
    if (hookMode !== "agent_end") return;
    if (touchedFiles.size === 0) return;
    if (!ctx.isIdle() || ctx.hasPendingMessages()) return;

    const files = Array.from(touchedFiles);
    touchedFiles.clear();

    const outputs: string[] = [];
    for (const filePath of files) {
      const relPath = path.relative(ctx.cwd, filePath);
      const result = runGolangciLint(filePath, ctx.cwd);
      
      if (result.success && result.output !== "No fixes applied") {
        outputs.push(`File: ${relPath}\nModule: ${result.workingDir}\n${result.output}`);
      }
    }

    if (outputs.length) {
      pi.sendMessage({
        customType: "golangci-lint-result",
        content: outputs.join("\n\n"),
        display: true,
      }, {
        triggerTurn: true,
        deliverAs: "followUp",
      });
    }
  });

  pi.on("tool_result", async (event, ctx) => {
    if (event.toolName !== "write" && event.toolName !== "edit") return;

    const filePath = event.input.path as string;
    if (!filePath || !isGoFile(filePath)) return;

    const absPath = path.isAbsolute(filePath) ? filePath : path.resolve(ctx.cwd, filePath);

    if (hookMode === "disabled") return;

    if (hookMode === "agent_end") {
      touchedFiles.add(absPath);
      return;
    }

    // edit_write mode - run immediately
    const relPath = path.relative(ctx.cwd, absPath);
    const result = runGolangciLint(absPath, ctx.cwd);

    let outputText = "";
    
    if (result.success) {
      if (result.output === "No fixes applied") {
        outputText = `✅ golangci-lint: no fixes needed for ${relPath}`;
      } else {
        outputText = `🔧 golangci-lint applied fixes to ${relPath}\nModule: ${result.workingDir}\n${result.output}`;
      }
    } else {
      outputText = `⚠️ golangci-lint: ${result.output}`;
      // Notify only on errors
      if (ctx.hasUI) {
        const relPathOnly = path.basename(absPath);
        ctx.ui.notify(`⚠️ ${relPathOnly}: ${result.output}`, "warning");
      }
    }

    // Add result to tool output
    const newContent = [
      ...event.content,
      { type: "text" as const, text: `\n${outputText}\n` },
    ];

    return { content: newContent };
  });
}
