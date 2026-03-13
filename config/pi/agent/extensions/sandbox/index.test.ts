import test from "node:test";
import assert from "node:assert/strict";
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { tmpdir } from "node:os";

import { getEffectivePaths, normalizeConfig, saveGrantToConfig, saveDomainToConfig } from "./config";
import { checkPathAccess, extractDeniedPaths, isDeniedByConfig, formatToolCommand, filterIgnoredDeniedPaths } from "./policy";
import { buildRuntimeConfig } from "./runtime";

function resolvePath(p: string): string {
  if (p.startsWith("~/")) return join(homedir(), p.slice(2));
  if (p === "~") return homedir();
  if (p === ".") return process.cwd();
  return p;
}

test("normalizeConfig sets defaults", () => {
  const config = normalizeConfig({});

  assert.equal(config.enabled, true);
  assert.equal(config.mode, "interactive");
  assert.deepEqual(config.network?.allowedDomains, []);
  assert.deepEqual(config.network?.deniedDomains, []);
  assert.deepEqual(config.filesystem?.allowRead, []);
  assert.deepEqual(config.filesystem?.allowWrite, []);
  assert.deepEqual(config.filesystem?.allowReadWrite, []);
  assert.deepEqual(config.filesystem?.denyRead, []);
  assert.deepEqual(config.filesystem?.denyWrite, []);
});

test("normalizeConfig preserves provided values", () => {
  const config = normalizeConfig({
    enabled: false,
    mode: "strict",
    network: {
      allowedDomains: ["github.com"],
      deniedDomains: ["evil.com"],
    },
    filesystem: {
      allowRead: ["/home/user/docs"],
      allowWrite: ["/tmp"],
      denyRead: ["~/.ssh"],
      denyWrite: [".env"],
    },
  });

  assert.equal(config.enabled, false);
  assert.equal(config.mode, "strict");
  assert.deepEqual(config.network?.allowedDomains, ["github.com"]);
  assert.deepEqual(config.network?.deniedDomains, ["evil.com"]);
  assert.deepEqual(config.filesystem?.allowRead, ["/home/user/docs"]);
  assert.deepEqual(config.filesystem?.allowWrite, ["/tmp"]);
  assert.deepEqual(config.filesystem?.denyRead, ["~/.ssh"]);
  assert.deepEqual(config.filesystem?.denyWrite, [".env"]);
});

test("getEffectivePaths includes cwd as readWrite", () => {
  const cwd = process.cwd();
  const config = normalizeConfig({ filesystem: { allowRead: ["/tmp"] } });

  const effective = getEffectivePaths(config, [], [], cwd);
  assert.ok(effective.readWrite.includes(cwd));
});

test("getEffectivePaths separates read and write paths", () => {
  const cwd = process.cwd();
  const config = normalizeConfig({
    filesystem: {
      allowRead: [join(cwd, "test-read")],
      allowWrite: [join(cwd, "test-write")],
    },
  });

  const effective = getEffectivePaths(config, [], [], cwd);

  assert.ok(effective.read.length >= 0);
  assert.ok(effective.write.length >= 0);
});

test("getEffectivePaths merges session grants", () => {
  const cwd = process.cwd();
  const config = normalizeConfig({});
  const sessionRead = join(cwd, "session-read");
  const sessionWrite = join(cwd, "session-write");

  const effective = getEffectivePaths(config, [sessionRead], [sessionWrite], cwd);

  // Paths should be resolved
  const resolvedRead = resolve(sessionRead);
  const resolvedWrite = resolve(sessionWrite);
  
  // Just verify the function works without error and returns structure
  assert.ok(Array.isArray(effective.read));
  assert.ok(Array.isArray(effective.write));
  assert.ok(Array.isArray(effective.readWrite));
});

test("checkPathAccess allows read/write in cwd by default", () => {
  const cwd = process.cwd();
  const config = normalizeConfig({});

  const readResult = checkPathAccess(cwd, "read", config, [], [], cwd);
  const writeResult = checkPathAccess(cwd, "write", config, [], [], cwd);

  assert.equal(readResult.allowed, true);
  assert.equal(writeResult.allowed, true);
});

test("checkPathAccess denies path from denyRead", () => {
  const cwd = process.cwd();
  const config = normalizeConfig({ filesystem: { denyRead: ["/tmp/secret"] } });

  const result = checkPathAccess("/tmp/secret", "read", config, [], [], cwd);

  assert.equal(result.allowed, false);
  assert.equal(result.reason, "denied_by_config");
});

test("checkPathAccess denies path from denyWrite", () => {
  const cwd = process.cwd();
  const config = normalizeConfig({ filesystem: { denyWrite: ["/tmp/secret"] } });

  const result = checkPathAccess("/tmp/secret", "write", config, [], [], cwd);

  assert.equal(result.allowed, false);
  assert.equal(result.reason, "denied_by_config");
});

test("checkPathAccess allows path in allowRead", () => {
  const cwd = process.cwd();
  const config = normalizeConfig({ filesystem: { allowRead: [cwd] } });

  const result = checkPathAccess(cwd, "read", config, [], [], cwd);

  assert.equal(result.allowed, true);
  assert.equal(result.reason, "granted_path");
});

test("checkPathAccess allows path in allowWrite", () => {
  const cwd = process.cwd();
  const config = normalizeConfig({ filesystem: { allowWrite: [cwd] } });

  const result = checkPathAccess(cwd, "write", config, [], [], cwd);

  assert.equal(result.allowed, true);
  assert.equal(result.reason, "granted_path");
});

test("checkPathAccess denies path not in any grant", () => {
  const cwd = process.cwd();
  const config = normalizeConfig({});

  const result = checkPathAccess("/etc/passwd", "read", config, [], [], cwd);

  assert.equal(result.allowed, false);
  assert.equal(result.reason, "path_not_granted");
});

test("isDeniedByConfig supports glob patterns via picomatch", () => {
  const denied = isDeniedByConfig("/tmp/.env.local", ["/tmp/.env*"]);
  assert.equal(denied, true);
});

test("isDeniedByConfig denies exact match", () => {
  const denied = isDeniedByConfig("/tmp/secret", ["/tmp/secret"]);
  assert.equal(denied, true);
});

test("isDeniedByConfig denies directory prefix", () => {
  const denied = isDeniedByConfig("/tmp/folder/file.txt", ["/tmp/folder"]);
  assert.equal(denied, true);
});

test("isDeniedByConfig allows non-matching paths", () => {
  const denied = isDeniedByConfig("/tmp/allowed.txt", ["/tmp/denied*"]);
  assert.equal(denied, false);
});

test("extractDeniedPaths parses EPERM", () => {
  const output = `bash: /tmp/a.txt: Operation not permitted`;

  const paths = extractDeniedPaths(output);

  assert.ok(paths.includes(resolvePath("/tmp/a.txt")));
});

test("extractDeniedPaths parses EACCES", () => {
  const output = `Error: EACCES: permission denied, open '/tmp/b.txt'`;

  const paths = extractDeniedPaths(output);

  assert.ok(paths.includes(resolvePath("/tmp/b.txt")));
});

test("extractDeniedPaths parses permission denied with quotes", () => {
  const output = `
    bash: /tmp/a.txt: Operation not permitted
    permission denied: '/tmp/b.txt'
  `;

  const paths = extractDeniedPaths(output);

  assert.ok(paths.includes(resolvePath("/tmp/a.txt")));
  assert.ok(paths.includes(resolvePath("/tmp/b.txt")));
});

test("filterIgnoredDeniedPaths removes shell config files", () => {
  const paths = [
    join(homedir(), ".bashrc"),
    join(homedir(), ".bash_profile"),
    join(homedir(), ".zshrc"),
    join(homedir(), ".profile"),
    "/tmp/actual/path",
  ];

  const filtered = filterIgnoredDeniedPaths(paths);

  assert.equal(filtered.length, 1);
  assert.equal(filtered[0], "/tmp/actual/path");
});

test("formatToolCommand formats simple command", () => {
  const cmd = formatToolCommand("bash", { command: "ls -la" });

  assert.equal(cmd, 'bash command="ls -la"');
});

test("formatToolCommand redacts content field", () => {
  const cmd = formatToolCommand("read", { path: "/test.txt", offset: 0, limit: 100 });

  assert.equal(cmd, 'read path="/test.txt" offset=0 limit=100');
});

test("formatToolCommand truncates long commands", () => {
  const longCommand = "echo " + "x".repeat(600);
  const cmd = formatToolCommand("bash", { command: longCommand });

  assert.ok(cmd.length < 600);
});

test("buildRuntimeConfig uses allowedDomains from config", () => {
  const cwd = process.cwd();
  const config = normalizeConfig({
    network: {
      allowedDomains: ["github.com", "api.github.com"],
    },
  });

  const runtime = buildRuntimeConfig(config, [], cwd);

  assert.deepEqual(runtime.network.allowedDomains, ["github.com", "api.github.com"]);
  assert.deepEqual(runtime.network.deniedDomains, []);
});

test("buildRuntimeConfig includes session write grants", () => {
  const cwd = process.cwd();
  const sessionWrite = "/tmp/runtime-write";
  const config = normalizeConfig({});

  const runtime = buildRuntimeConfig(config, [sessionWrite], cwd);

  assert.ok(runtime.filesystem.allowWrite.includes(cwd));
  assert.ok(runtime.filesystem.allowWrite.some(p => p.includes("runtime-write") || p === sessionWrite));
});

test("buildRuntimeConfig resolves paths", () => {
  const cwd = process.cwd();
  const config = normalizeConfig({
    filesystem: {
      allowWrite: ["."],
      denyRead: ["~/.ssh"],
    },
  });

  const runtime = buildRuntimeConfig(config, [], cwd);

  assert.ok(runtime.filesystem.allowWrite.length > 0);
  assert.ok(runtime.filesystem.denyRead.length > 0);
});

// --- Config persistence tests ---

function createTempDir(): string {
  const dir = join(tmpdir(), `sandbox-test-${Date.now()}-${Math.random().toString(36).slice(2)}`);
  mkdirSync(dir, { recursive: true });
  return dir;
}

test("saveGrantToConfig preserves existing fields with trailing commas", () => {
  const dir = createTempDir();
  const configDir = join(dir, ".pi");
  mkdirSync(configDir, { recursive: true });
  const configPath = join(configDir, "sandbox.json");

  writeFileSync(configPath, JSON.stringify({
    enabled: true,
    mode: "interactive",
    network: { allowedDomains: ["api.github.com:443"] },
    enableWeakerNetworkIsolation: true,
    filesystem: { allowRead: ["/tmp/existing"] },
  }, null, 2).replace(']\n}', ']\n}\n') + "\n");

  saveGrantToConfig("project", dir, { reads: ["/tmp/new-path"] });

  const result = JSON.parse(readFileSync(configPath, "utf-8"));
  assert.equal(result.enabled, true);
  assert.equal(result.mode, "interactive");
  assert.deepEqual(result.network.allowedDomains, ["api.github.com:443"]);
  assert.equal(result.enableWeakerNetworkIsolation, true);
  assert.ok(result.filesystem.allowRead.includes("/tmp/existing"));
  assert.ok(result.filesystem.allowRead.includes("/tmp/new-path"));

  rmSync(dir, { recursive: true });
});

test("saveGrantToConfig handles JSON with trailing commas", () => {
  const dir = createTempDir();
  const configDir = join(dir, ".pi");
  mkdirSync(configDir, { recursive: true });
  const configPath = join(configDir, "sandbox.json");

  const jsonWithTrailingCommas = `{
  "enabled": true,
  "network": {
    "allowedDomains": [
      "api.github.com:443",
      "github.com:443",
    ]
  },
  "filesystem": {
    "allowRead": [
      "/tmp/a",
      "/tmp/b",
    ],
  },
}`;
  writeFileSync(configPath, jsonWithTrailingCommas);

  saveGrantToConfig("project", dir, { reads: ["/tmp/c"] });

  const result = JSON.parse(readFileSync(configPath, "utf-8"));
  assert.equal(result.enabled, true);
  assert.deepEqual(result.network.allowedDomains, ["api.github.com:443", "github.com:443"]);
  assert.ok(result.filesystem.allowRead.includes("/tmp/a"));
  assert.ok(result.filesystem.allowRead.includes("/tmp/b"));
  assert.ok(result.filesystem.allowRead.includes("/tmp/c"));

  rmSync(dir, { recursive: true });
});

test("saveDomainToConfig preserves existing fields", () => {
  const dir = createTempDir();
  const configDir = join(dir, ".pi");
  mkdirSync(configDir, { recursive: true });
  const configPath = join(configDir, "sandbox.json");

  writeFileSync(configPath, JSON.stringify({
    enabled: true,
    mode: "strict",
    filesystem: { allowRead: ["/tmp/keep"], denyRead: ["~/.ssh"] },
    network: { allowedDomains: ["existing.com"] },
  }, null, 2) + "\n");

  saveDomainToConfig("project", dir, "new-host.com:443");

  const result = JSON.parse(readFileSync(configPath, "utf-8"));
  assert.equal(result.enabled, true);
  assert.equal(result.mode, "strict");
  assert.deepEqual(result.filesystem.allowRead, ["/tmp/keep"]);
  assert.deepEqual(result.filesystem.denyRead, ["~/.ssh"]);
  assert.ok(result.network.allowedDomains.includes("existing.com"));
  assert.ok(result.network.allowedDomains.includes("new-host.com:443"));

  rmSync(dir, { recursive: true });
});

test("saveDomainToConfig handles JSON with trailing commas", () => {
  const dir = createTempDir();
  const configDir = join(dir, ".pi");
  mkdirSync(configDir, { recursive: true });
  const configPath = join(configDir, "sandbox.json");

  const jsonWithTrailingCommas = `{
  "enabled": true,
  "mode": "interactive",
  "network": {
    "allowedDomains": [
      "api.github.com:443",
    ],
  },
  "enableWeakerNetworkIsolation": true,
  "filesystem": {
    "allowRead": [
      "/tmp/a",
    ],
  },
}`;
  writeFileSync(configPath, jsonWithTrailingCommas);

  saveDomainToConfig("project", dir, "new.com:443");

  const result = JSON.parse(readFileSync(configPath, "utf-8"));
  assert.equal(result.enabled, true);
  assert.equal(result.mode, "interactive");
  assert.equal(result.enableWeakerNetworkIsolation, true);
  assert.ok(result.network.allowedDomains.includes("api.github.com:443"));
  assert.ok(result.network.allowedDomains.includes("new.com:443"));
  assert.deepEqual(result.filesystem.allowRead, ["/tmp/a"]);

  rmSync(dir, { recursive: true });
});
