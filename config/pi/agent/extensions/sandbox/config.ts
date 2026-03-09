import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";

import type { ConfigScope, EffectivePaths, SandboxConfig, SandboxMode } from "./types";

export function normalizeMode(value: unknown): SandboxMode | undefined {
  if (value === "strict" || value === "interactive" || value === "permissive") return value;
  return undefined;
}

function expandPath(p: string): string {
  if (p.startsWith("~/")) return join(homedir(), p.slice(2));
  if (p === "~") return homedir();
  if (p === ".") return process.cwd();
  return p;
}

export function resolvePath(p: string): string {
  return resolve(expandPath(p));
}

export function normalizeConfig(partial: Partial<SandboxConfig>): SandboxConfig {
  return {
    enabled: partial.enabled ?? true,
    mode: normalizeMode(partial.mode) ?? "interactive",
    network: {
      block: partial.network?.block ?? false,
    },
    filesystem: {
      allowRead: partial.filesystem?.allowRead ?? [],
      allowWrite: partial.filesystem?.allowWrite ?? [],
      allowReadWrite: partial.filesystem?.allowReadWrite ?? [],
      denyRead: partial.filesystem?.denyRead ?? [],
      denyWrite: partial.filesystem?.denyWrite ?? [],
    },
  };
}

export function loadConfig(cwd: string): SandboxConfig {
  const globalPath = join(homedir(), ".pi", "agent", "sandbox.json");
  const projectPath = join(cwd, ".pi", "sandbox.json");

  let global: Partial<SandboxConfig> = {};
  let project: Partial<SandboxConfig> = {};

  if (existsSync(globalPath)) {
    try { global = JSON.parse(readFileSync(globalPath, "utf-8")); } catch {}
  }
  if (existsSync(projectPath)) {
    try { project = JSON.parse(readFileSync(projectPath, "utf-8")); } catch {}
  }

  const projectSetsEnabled = Object.prototype.hasOwnProperty.call(project, "enabled");
  const projectSetsMode = Object.prototype.hasOwnProperty.call(project, "mode");

  const mergeArrays = (a: string[] | undefined, b: string[] | undefined): string[] =>
    [...new Set([...(a ?? []), ...(b ?? [])])];

  return normalizeConfig({
    enabled: projectSetsEnabled ? project.enabled : global.enabled,
    mode: projectSetsMode ? project.mode : global.mode,
    network: {
      block: project.network?.block ?? global.network?.block,
    },
    filesystem: {
      allowRead: mergeArrays(global.filesystem?.allowRead, project.filesystem?.allowRead),
      allowWrite: mergeArrays(global.filesystem?.allowWrite, project.filesystem?.allowWrite),
      allowReadWrite: mergeArrays(global.filesystem?.allowReadWrite, project.filesystem?.allowReadWrite),
      denyRead: mergeArrays(global.filesystem?.denyRead, project.filesystem?.denyRead),
      denyWrite: mergeArrays(global.filesystem?.denyWrite, project.filesystem?.denyWrite),
    },
  });
}

export function configPathForScope(scope: ConfigScope, cwd: string): string {
  if (scope === "global") return join(homedir(), ".pi", "agent", "sandbox.json");
  return join(cwd, ".pi", "sandbox.json");
}

export function saveGrantToConfig(
  scope: ConfigScope,
  cwd: string,
  grant: { reads?: string[]; writes?: string[] },
) {
  const path = configPathForScope(scope, cwd);
  let existing: Record<string, any> = {};

  if (existsSync(path)) {
    try { existing = JSON.parse(readFileSync(path, "utf-8")); } catch {}
  }

  if (!existing.filesystem) existing.filesystem = {};

  if (grant.reads?.length) {
    const current: string[] = existing.filesystem.allowRead ?? [];
    existing.filesystem.allowRead = [...new Set([...current, ...grant.reads])];
  }

  if (grant.writes?.length) {
    const current: string[] = existing.filesystem.allowWrite ?? [];
    existing.filesystem.allowWrite = [...new Set([...current, ...grant.writes])];
  }

  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, JSON.stringify(existing, null, 2) + "\n", "utf-8");
}

export function toUniqueResolved(paths: string[]): string[] {
  const resolved: string[] = [];
  for (const path of paths) {
    const value = resolvePath(path);
    if (!resolved.includes(value)) resolved.push(value);
  }
  return resolved;
}

function splitExistingPaths(paths: string[]): { existing: string[]; missing: string[] } {
  const existing: string[] = [];
  const missing: string[] = [];

  for (const path of paths) {
    if (existsSync(path)) existing.push(path);
    else missing.push(path);
  }

  return { existing, missing };
}

export function getEffectivePaths(
  config: SandboxConfig,
  sessionReads: string[],
  sessionWrites: string[],
  cwd: string,
): EffectivePaths {
  const readWriteResolved = toUniqueResolved([...(config.filesystem?.allowReadWrite ?? []), cwd]);
  const readWriteSplit = splitExistingPaths(readWriteResolved);
  const readWriteSet = new Set(readWriteSplit.existing);

  const readResolved = toUniqueResolved([...(config.filesystem?.allowRead ?? []), ...sessionReads])
    .filter((path) => !readWriteSet.has(path));
  const readSplit = splitExistingPaths(readResolved);

  const writeResolved = toUniqueResolved([...(config.filesystem?.allowWrite ?? []), ...sessionWrites])
    .filter((path) => !readWriteSet.has(path));
  const writeSplit = splitExistingPaths(writeResolved);

  return {
    readWrite: readWriteSplit.existing,
    read: readSplit.existing,
    write: writeSplit.existing,
    missing: {
      readWrite: readWriteSplit.missing,
      read: readSplit.missing,
      write: writeSplit.missing,
    },
  };
}
