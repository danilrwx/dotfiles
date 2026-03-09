import { spawn } from "node:child_process";

import { type SandboxRuntimeConfig } from "@anthropic-ai/sandbox-runtime";

import { toUniqueResolved } from "./config";
import type { ExecResult, RuntimeConfigExtras, SandboxConfig } from "./types";

export function buildRuntimeConfig(
  config: SandboxConfig,
  sessionWrites: string[],
  cwd: string,
): SandboxRuntimeConfig {
  const allowWrite = toUniqueResolved([
    cwd,
    ...(config.filesystem?.allowWrite ?? []),
    ...(config.filesystem?.allowReadWrite ?? []),
    ...sessionWrites,
  ]);

  const denyRead = toUniqueResolved(config.filesystem?.denyRead ?? []);
  const denyWrite = toUniqueResolved(config.filesystem?.denyWrite ?? []);

  const network = {
    allowedDomains: config.network?.allowedDomains && config.network.allowedDomains.length > 0
      ? config.network.allowedDomains
      : ["*"],
    deniedDomains: config.network?.deniedDomains ?? [],
  };

  const extras = config as SandboxConfig & RuntimeConfigExtras;

  return {
    network,
    filesystem: {
      denyRead,
      allowWrite,
      denyWrite,
    },
    ignoreViolations: extras.ignoreViolations,
    enableWeakerNestedSandbox: extras.enableWeakerNestedSandbox,
    enableWeakerNetworkIsolation: extras.enableWeakerNetworkIsolation,
    allowPty: extras.allowPty,
  };
}

export async function runBashCommand(
  command: string,
  cwd: string,
  signal?: AbortSignal,
  timeout?: number,
  onData?: (data: Buffer) => void,
): Promise<ExecResult> {
  return new Promise((resolvePromise, reject) => {
    const child = spawn("bash", ["-c", command], {
      cwd,
      detached: true,
      stdio: ["ignore", "pipe", "pipe"],
    });

    const chunks: Buffer[] = [];
    let timedOut = false;
    let timeoutHandle: NodeJS.Timeout | undefined;

    if (timeout && timeout > 0) {
      timeoutHandle = setTimeout(() => {
        timedOut = true;
        try {
          if (child.pid) process.kill(-child.pid, "SIGKILL");
        } catch {
          child.kill("SIGKILL");
        }
      }, timeout * 1000);
    }

    child.stdout?.on("data", (data: Buffer) => {
      chunks.push(data);
      onData?.(data);
    });
    child.stderr?.on("data", (data: Buffer) => {
      chunks.push(data);
      onData?.(data);
    });

    child.on("error", (err) => {
      if (timeoutHandle) clearTimeout(timeoutHandle);
      reject(err);
    });

    const onAbort = () => {
      try {
        if (child.pid) process.kill(-child.pid, "SIGKILL");
      } catch {
        child.kill("SIGKILL");
      }
    };
    signal?.addEventListener("abort", onAbort, { once: true });

    child.on("close", (code) => {
      if (timeoutHandle) clearTimeout(timeoutHandle);
      signal?.removeEventListener("abort", onAbort);

      if (signal?.aborted) reject(new Error("aborted"));
      else if (timedOut) reject(new Error(`timeout:${timeout}`));
      else resolvePromise({ exitCode: code, output: Buffer.concat(chunks).toString("utf-8") });
    });
  });
}
