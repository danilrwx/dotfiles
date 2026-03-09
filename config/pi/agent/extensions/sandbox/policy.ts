import picomatch from "picomatch";

import { getEffectivePaths, resolvePath } from "./config";
import type { AccessMode, SandboxConfig } from "./types";

function hasGlob(pattern: string): boolean {
  return /[*?[\]{}()]/.test(pattern);
}

function matchesPath(absPath: string, pattern: string): boolean {
  const expanded = resolvePath(pattern);

  if (!hasGlob(pattern)) {
    return absPath === expanded || absPath.startsWith(expanded + "/");
  }

  const matcher = picomatch(expanded, { dot: true });
  return matcher(absPath);
}

export function isDeniedByConfig(filePath: string, patterns: string[]): boolean {
  const abs = resolvePath(filePath);
  return patterns.some((pattern) => matchesPath(abs, pattern));
}

export function checkPathAccess(
  filePath: string,
  accessMode: AccessMode,
  config: SandboxConfig,
  sessionReads: string[],
  sessionWrites: string[],
  cwd: string,
): { allowed: boolean; reason: string; details?: string } {
  const resolved = resolvePath(filePath);

  const denyList = accessMode === "read"
    ? (config.filesystem?.denyRead ?? [])
    : (config.filesystem?.denyWrite ?? []);

  if (isDeniedByConfig(resolved, denyList)) {
    return { allowed: false, reason: "denied_by_config", details: `Path ${resolved} is in deny list` };
  }

  const effective = getEffectivePaths(config, sessionReads, sessionWrites, cwd);

  const allowPatterns = accessMode === "read"
    ? [...effective.readWrite, ...effective.read]
    : [...effective.readWrite, ...effective.write];

  const allowed = allowPatterns.some((pattern) => matchesPath(resolved, pattern));

  if (allowed) return { allowed: true, reason: "granted_path" };

  return {
    allowed: false,
    reason: "path_not_granted",
    details: "Path not covered by any grant",
  };
}

export function formatToolCommand(toolName: string, input: unknown): string {
  if (!input || typeof input !== "object") return toolName;
  const MAX_LEN = 500;
  const REDACTED = new Set(["content", "oldText", "newText"]);

  const entries = Object.entries(input as Record<string, unknown>)
    .filter(([, v]) => v !== undefined && v !== null)
    .map(([key, value]) => {
      if (REDACTED.has(key) && typeof value === "string") {
        return `${key}="<${value.length} chars>"`;
      }
      if (typeof value === "string") {
        const preview = value.length > 120 ? value.slice(0, 120) + "…" : value;
        return `${key}="${preview}"`;
      }
      return `${key}=${JSON.stringify(value)}`;
    });

  const cmd = entries.length > 0 ? `${toolName} ${entries.join(" ")}` : toolName;
  return cmd.length > MAX_LEN ? cmd.slice(0, MAX_LEN) + "…" : cmd;
}

export function extractDeniedPaths(output: string): string[] {
  const patterns = [
    /Operation not permitted.*?['"]([^'"]+)['"]/i,
    /EPERM.*?['"]([^'"]+)['"]/i,
    /EACCES.*?['"]([^'"]+)['"]/i,
    /permission denied[,:]\s*'([^']+)'/i,
    /permission denied[,:]\s*"([^"]+)"/i,
    /unable to access ['"]([^'"]+)['"]:\s*Operation not permitted/i,
    /['"]([^'"]+)['"]:\s*Operation not permitted/i,
    /:\s*([/~][^\s:]+):\s*Operation not permitted/i,
  ];

  const paths = new Set<string>();
  for (const line of output.split("\n")) {
    for (const pattern of patterns) {
      const match = line.match(pattern);
      if (match?.[1]) paths.add(resolvePath(match[1]));
    }
  }
  return [...paths];
}

export function filterIgnoredDeniedPaths(paths: string[]): string[] {
  const ignored = new Set([
    resolvePath("~/.bash_profile"),
    resolvePath("~/.bashrc"),
    resolvePath("~/.zshrc"),
    resolvePath("~/.profile"),
  ]);
  return paths.filter((path) => !ignored.has(resolvePath(path)));
}
