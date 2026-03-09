import { existsSync } from "node:fs";

import { SandboxManager } from "@anthropic-ai/sandbox-runtime";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType, type BashOperations, createBashTool } from "@mariozechner/pi-coding-agent";

import {
  configPathForScope,
  getEffectivePaths,
  loadConfig,
  normalizeConfig,
  resolvePath,
  saveGrantToConfig,
} from "./config";
import {
  checkPathAccess,
  extractDeniedPaths,
  filterIgnoredDeniedPaths,
  formatToolCommand,
  isDeniedByConfig,
} from "./policy";
import { buildRuntimeConfig, runBashCommand } from "./runtime";
import type { AccessMode, ConfigScope, SandboxConfig, SandboxMode } from "./types";

const MODE_LABELS: Record<SandboxMode, { icon: string; label: string }> = {
  strict: { icon: "🔒", label: "strict" },
  interactive: { icon: "🛡️", label: "interactive" },
  permissive: { icon: "⚠️", label: "permissive" },
};

export default function (pi: ExtensionAPI) {
  pi.registerFlag("no-sandbox", {
    description: "Disable sandbox",
    type: "boolean",
    default: false,
  });

  pi.registerFlag("sandbox-mode", {
    description: "Sandbox mode: strict, interactive, permissive",
    type: "string",
    default: "interactive",
  });

  const localCwd = process.cwd();
  const localBash = createBashTool(localCwd);

  let mode: SandboxMode = "interactive";
  let sandboxReady = false;
  let config: SandboxConfig = normalizeConfig({});
  let sessionGrantedReads: string[] = [];
  let sessionGrantedWrites: string[] = [];
  let runtimeAvailable = false;
  let runtimeReason = "not_initialized";
  let allowUnsandboxedBashForSession = false;

  function addSessionGrant(filePath: string, accessMode: AccessMode): string {
    const resolved = resolvePath(filePath);
    const target = accessMode === "read" ? sessionGrantedReads : sessionGrantedWrites;
    if (!target.includes(resolved)) target.push(resolved);
    return resolved;
  }

  function updateStatus(ctx: ExtensionContext) {
    const m = MODE_LABELS[mode];
    const grants = sessionGrantedReads.length + sessionGrantedWrites.length;
    const extra = grants > 0 ? ` (+${grants} granted)` : "";

    if (mode === "permissive") {
      ctx.ui.setStatus("sandbox", ctx.ui.theme.fg("warning", `${m.icon} Sandbox: ${m.label}`));
      return;
    }

    ctx.ui.setStatus("sandbox", ctx.ui.theme.fg("accent", `${m.icon} Sandbox: ${m.label}${extra}`));
  }

  async function applyRuntimeConfig(ctx: ExtensionContext, silent = false): Promise<void> {
    if (mode === "permissive") {
      runtimeAvailable = false;
      runtimeReason = "permissive_mode";
      updateStatus(ctx);
      return;
    }

    if (!SandboxManager.isSupportedPlatform()) {
      runtimeAvailable = false;
      runtimeReason = "unsupported_platform";
      updateStatus(ctx);
      if (!silent) ctx.ui.notify("Sandbox runtime is not supported on this platform. Using policy-only mode.", "warning");
      return;
    }

    const deps = SandboxManager.checkDependencies();
    if (deps.errors.length > 0) {
      runtimeAvailable = false;
      runtimeReason = `missing_deps:${deps.errors.join(", ")}`;
      updateStatus(ctx);
      if (!silent) ctx.ui.notify(`Sandbox runtime dependencies missing: ${deps.errors.join("; ")}`, "warning");
      return;
    }

    try {
      const runtimeConfig = buildRuntimeConfig(config, sessionGrantedWrites, ctx.cwd);
      if (SandboxManager.isSandboxingEnabled()) {
        SandboxManager.updateConfig(runtimeConfig);
      } else {
        await SandboxManager.initialize(runtimeConfig);
      }

      runtimeAvailable = true;
      runtimeReason = "ok";
      updateStatus(ctx);
    } catch (error) {
      runtimeAvailable = false;
      runtimeReason = error instanceof Error ? error.message : String(error);
      updateStatus(ctx);
      if (!silent) ctx.ui.notify(`Sandbox initialization failed: ${runtimeReason}`, "warning");
    }
  }

  async function promptForAccess(
    filePath: string,
    operation: string,
    accessMode: AccessMode,
    command: string,
    ctx: ExtensionContext,
  ): Promise<{ block: boolean; reason?: string } | undefined> {
    if (mode === "strict") {
      return { block: true, reason: `[sandbox:strict] ${operation} ${filePath} blocked` };
    }

    if (mode !== "interactive") return undefined;

    const options = [
      "Allow for this session",
      "Allow & save to project config",
      "Allow & save to global config",
      "Block",
    ];

    const choice = await ctx.ui.select(
      `🛡️ Sandbox: ${operation} outside allowed paths\nCommand: ${command}\nPath: ${filePath}`,
      options,
    );

    if (choice === "Block" || choice === undefined) {
      return { block: true, reason: `${operation} ${filePath} blocked by user` };
    }

    const resolved = addSessionGrant(filePath, accessMode);

    if (choice === "Allow & save to project config" || choice === "Allow & save to global config") {
      const scope: ConfigScope = choice.includes("global") ? "global" : "project";
      const grant = accessMode === "read" ? { reads: [resolved] } : { writes: [resolved] };
      saveGrantToConfig(scope, ctx.cwd, grant);
      config = loadConfig(ctx.cwd);
      ctx.ui.notify(`Saved to ${configPathForScope(scope, ctx.cwd)}`, "info");
    }

    await applyRuntimeConfig(ctx, true);
    updateStatus(ctx);
    return undefined;
  }

  async function promptForUnsandboxedBash(ctx: ExtensionContext, command: string): Promise<boolean> {
    if (mode === "strict") return false;
    if (mode !== "interactive") return true;
    if (allowUnsandboxedBashForSession) return true;

    const choice = await ctx.ui.select(
      `🛡️ Sandbox backend unavailable\nCommand: ${command}\nRun unsandboxed?`,
      ["Run once", "Allow unsandboxed for this session", "Block"],
    );

    if (choice === "Allow unsandboxed for this session") {
      allowUnsandboxedBashForSession = true;
      return true;
    }

    return choice === "Run once";
  }

  async function promptForBashGrant(
    command: string,
    paths: string[],
    ctx: ExtensionContext,
  ): Promise<boolean> {
    if (mode !== "interactive" || paths.length === 0) return false;

    const options = [
      "Grant for this session & retry",
      "Grant & save to project config & retry",
      "Grant & save to global config & retry",
      "Block",
    ];

    const choice = await ctx.ui.select(
      `🛡️ Sandbox violation\nCommand: ${command}\nBlocked path(s): ${paths.join(", ")}`,
      options,
    );

    if (choice === "Block" || choice === undefined) return false;

    for (const path of paths) {
      addSessionGrant(path, "read");
      addSessionGrant(path, "write");
    }

    if (choice === "Grant & save to project config & retry" || choice === "Grant & save to global config & retry") {
      const scope: ConfigScope = choice.includes("global") ? "global" : "project";
      saveGrantToConfig(scope, ctx.cwd, { reads: paths, writes: paths });
      config = loadConfig(ctx.cwd);
      ctx.ui.notify(`Saved to ${configPathForScope(scope, ctx.cwd)}`, "info");
    }

    await applyRuntimeConfig(ctx, true);
    updateStatus(ctx);
    return true;
  }

  function createSandboxedOps(ctx: ExtensionContext): BashOperations {
    return {
      async exec(command, cwd, { onData, signal, timeout }) {
        if (!existsSync(cwd)) throw new Error(`Working directory does not exist: ${cwd}`);

        if (!runtimeAvailable) {
          const allowed = await promptForUnsandboxedBash(ctx, command);
          if (!allowed) throw new Error("[sandbox] blocked: backend unavailable and command not approved");
          return runBashCommand(command, cwd, signal, timeout, onData);
        }

        const wrappedCommand = await SandboxManager.wrapWithSandbox(command);
        const firstRun = await runBashCommand(wrappedCommand, cwd, signal, timeout, onData);

        if (mode !== "interactive") {
          SandboxManager.cleanupAfterCommand();
          return { exitCode: firstRun.exitCode };
        }

        const hasDenied = /Operation not permitted|EPERM|EACCES|permission denied/i.test(firstRun.output);
        if (!hasDenied) {
          SandboxManager.cleanupAfterCommand();
          return { exitCode: firstRun.exitCode };
        }

        const deniedPaths = filterIgnoredDeniedPaths(extractDeniedPaths(firstRun.output));
        if (deniedPaths.length === 0) {
          SandboxManager.cleanupAfterCommand();
          return { exitCode: firstRun.exitCode };
        }

        const granted = await promptForBashGrant(command, deniedPaths, ctx);
        if (!granted) {
          SandboxManager.cleanupAfterCommand();
          return { exitCode: firstRun.exitCode };
        }

        onData?.(Buffer.from("[sandbox] Permission granted, retrying...\n"));

        const retryWrapped = await SandboxManager.wrapWithSandbox(command);
        const retryRun = await runBashCommand(retryWrapped, cwd, signal, timeout, onData);
        SandboxManager.cleanupAfterCommand();
        return { exitCode: retryRun.exitCode };
      },
    };
  }

  pi.registerTool({
    ...localBash,
    label: "bash (sandbox)",
    async execute(id, params, signal, onUpdate, ctx) {
      if (mode === "permissive" || !sandboxReady) {
        return localBash.execute(id, params, signal, onUpdate);
      }

      const sandboxedBash = createBashTool(localCwd, {
        operations: createSandboxedOps(ctx),
      });

      return sandboxedBash.execute(id, params, signal, onUpdate);
    },
  });

  pi.on("user_bash", (_event, ctx) => {
    if (mode === "permissive" || !sandboxReady) return;
    return { operations: createSandboxedOps(ctx) };
  });

  async function handlePathToolCall(
    filePath: string | undefined,
    accessMode: AccessMode,
    operation: string,
    toolName: string,
    input: unknown,
    ctx: ExtensionContext,
  ) {
    const normalizedPath = filePath?.replace(/^@/, "");
    if (!normalizedPath) return;

    const check = checkPathAccess(normalizedPath, accessMode, config, sessionGrantedReads, sessionGrantedWrites, localCwd);
    if (check.allowed) return;

    const command = formatToolCommand(toolName, input);
    return promptForAccess(normalizedPath, operation, accessMode, command, ctx);
  }

  pi.on("tool_call", async (event, ctx) => {
    if (mode === "permissive" || !sandboxReady) return;

    if (isToolCallEventType("read", event)) {
      return handlePathToolCall(event.input.path, "read", "Read", event.toolName, event.input, ctx);
    }

    if (isToolCallEventType("write", event)) {
      return handlePathToolCall(event.input.path, "write", "Write to", event.toolName, event.input, ctx);
    }

    if (isToolCallEventType("edit", event)) {
      return handlePathToolCall(event.input.path, "write", "Edit", event.toolName, event.input, ctx);
    }
  });

  pi.on("session_start", async (_event, ctx) => {
    const noSandbox = pi.getFlag("no-sandbox") as boolean;
    const flagMode = pi.getFlag("sandbox-mode") as string | undefined;

    config = loadConfig(ctx.cwd);

    if (noSandbox) {
      mode = "permissive";
      sandboxReady = true;
      updateStatus(ctx);
      ctx.ui.notify("Sandbox disabled via --no-sandbox", "warning");
      return;
    }

    if (!config.enabled) {
      mode = "permissive";
      sandboxReady = true;
      updateStatus(ctx);
      ctx.ui.notify("Sandbox disabled via config", "info");
      return;
    }

    if (flagMode && ["strict", "interactive", "permissive"].includes(flagMode)) {
      mode = flagMode as SandboxMode;
    } else if (config.mode) {
      mode = config.mode;
    }

    sandboxReady = true;
    allowUnsandboxedBashForSession = false;

    await applyRuntimeConfig(ctx);

    const backend = runtimeAvailable
      ? "sandbox-runtime"
      : `policy-only (${runtimeReason})`;
    ctx.ui.notify(`Sandbox initialized [${mode}] — ${backend}`, "info");
  });

  pi.on("session_shutdown", async () => {
    if (SandboxManager.isSandboxingEnabled()) {
      try {
        await SandboxManager.reset();
      } catch {}
    }
  });

  pi.registerCommand("sandbox", {
    description: "Sandbox control: /sandbox [status|strict|interactive|permissive|grants|reset|why <path>]",
    getArgumentCompletions: (prefix) => {
      const items = ["status", "strict", "interactive", "permissive", "grants", "reset", "why"].map(
        (v) => ({ value: v, label: v }),
      );
      const filtered = items.filter((i) => i.value.startsWith(prefix));
      return filtered.length > 0 ? filtered : null;
    },
    handler: async (args, ctx) => {
      const parts = args?.trim().split(/\s+/) ?? ["status"];
      const sub = parts[0] || "status";

      if (["strict", "interactive", "permissive"].includes(sub)) {
        mode = sub as SandboxMode;
        await applyRuntimeConfig(ctx, true);
        updateStatus(ctx);
        ctx.ui.notify(`Sandbox mode: ${MODE_LABELS[mode].icon} ${mode}`, "info");
        return;
      }

      if (sub === "grants") {
        const lines = [
          "Session grants:",
          `  Read: ${sessionGrantedReads.length > 0 ? sessionGrantedReads.join(", ") : "(none)"}`,
          `  Write: ${sessionGrantedWrites.length > 0 ? sessionGrantedWrites.join(", ") : "(none)"}`,
        ];
        ctx.ui.notify(lines.join("\n"), "info");
        return;
      }

      if (sub === "reset") {
        sessionGrantedReads = [];
        sessionGrantedWrites = [];
        config = loadConfig(ctx.cwd);
        allowUnsandboxedBashForSession = false;
        await applyRuntimeConfig(ctx, true);
        updateStatus(ctx);
        ctx.ui.notify("Sandbox reset to original config", "info");
        return;
      }

      if (sub === "why" && parts[1]) {
        const targetPath = parts[1];
        const resolved = resolvePath(targetPath);

        const readResult = checkPathAccess(resolved, "read", config, sessionGrantedReads, sessionGrantedWrites, localCwd);
        const writeResult = checkPathAccess(resolved, "write", config, sessionGrantedReads, sessionGrantedWrites, localCwd);

        const lines = [
          `Path: ${resolved}`,
          `  Read:  ${readResult.allowed ? "allowed" : "denied"} (${readResult.reason})`,
          `  Write: ${writeResult.allowed ? "allowed" : "denied"} (${writeResult.reason})`,
        ];

        const denyRead = config.filesystem?.denyRead ?? [];
        const denyWrite = config.filesystem?.denyWrite ?? [];
        if (isDeniedByConfig(resolved, denyRead)) lines.push("  ⚠️ In denyRead config list");
        if (isDeniedByConfig(resolved, denyWrite)) lines.push("  ⚠️ In denyWrite config list");

        ctx.ui.notify(lines.join("\n"), "info");
        return;
      }

      const m = MODE_LABELS[mode];
      const grants = sessionGrantedReads.length + sessionGrantedWrites.length;
      const globalPath = configPathForScope("global", ctx.cwd);
      const projectPath = configPathForScope("project", ctx.cwd);

      const effective = getEffectivePaths(config, sessionGrantedReads, sessionGrantedWrites, localCwd);
      const missingPaths = [...effective.missing.readWrite, ...effective.missing.read, ...effective.missing.write];

      const lines = [
        `Mode: ${m.icon} ${mode}`,
        `Backend: ${runtimeAvailable ? "sandbox-runtime" : `policy-only (${runtimeReason})`}`,
        `Sandbox active: ${sandboxReady}`,
        `Session grants: ${grants}`,
        `Network: ${config.network?.block ? "blocked" : "allowed"}`,
        `Global config: ${globalPath}`,
        `Project config: ${projectPath}`,
        `ReadWrite paths: ${effective.readWrite.length}`,
        `Read paths: ${effective.read.length}`,
        `Write paths: ${effective.write.length}`,
        `Skipped missing paths: ${missingPaths.length}`,
        ...(missingPaths.length > 0 ? missingPaths.map((path) => `  - ${path}`) : []),
      ];
      ctx.ui.notify(lines.join("\n"), "info");
    },
  });
}
