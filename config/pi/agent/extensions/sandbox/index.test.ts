import test from "node:test";
import assert from "node:assert/strict";

import { getEffectivePaths, normalizeConfig } from "./config";
import { checkPathAccess, extractDeniedPaths, isDeniedByConfig } from "./policy";
import { buildRuntimeConfig } from "./runtime";

test("normalizeConfig sets defaults", () => {
  const config = normalizeConfig({});

  assert.equal(config.enabled, true);
  assert.equal(config.mode, "interactive");
  assert.equal(config.network?.block, false);
  assert.deepEqual(config.filesystem?.allowRead, []);
  assert.deepEqual(config.filesystem?.allowWrite, []);
});

test("getEffectivePaths includes cwd as readWrite", () => {
  const cwd = process.cwd();
  const config = normalizeConfig({ filesystem: { allowRead: ["/tmp"] } });

  const effective = getEffectivePaths(config, [], [], cwd);
  assert.ok(effective.readWrite.includes(cwd));
});

test("checkPathAccess allows read/write in cwd by default", () => {
  const cwd = process.cwd();
  const config = normalizeConfig({});

  const readResult = checkPathAccess(cwd, "read", config, [], [], cwd);
  const writeResult = checkPathAccess(cwd, "write", config, [], [], cwd);

  assert.equal(readResult.allowed, true);
  assert.equal(writeResult.allowed, true);
});

test("isDeniedByConfig supports glob patterns via picomatch", () => {
  const denied = isDeniedByConfig("/tmp/.env.local", ["/tmp/.env*"]);
  assert.equal(denied, true);
});

test("checkPathAccess denies path from denyWrite", () => {
  const cwd = process.cwd();
  const config = normalizeConfig({ filesystem: { denyWrite: ["/tmp/secret"] } });

  const result = checkPathAccess("/tmp/secret", "write", config, [], [], cwd);

  assert.equal(result.allowed, false);
  assert.equal(result.reason, "denied_by_config");
});

test("extractDeniedPaths parses permission denied output", () => {
  const output = `
    bash: /tmp/a.txt: Operation not permitted
    permission denied: '/tmp/b.txt'
  `;

  const paths = extractDeniedPaths(output);

  assert.ok(paths.includes("/tmp/a.txt"));
  assert.ok(paths.includes("/tmp/b.txt"));
});

test("buildRuntimeConfig maps network.block=true to blocked network", () => {
  const cwd = process.cwd();
  const config = normalizeConfig({ network: { block: true } });

  const runtime = buildRuntimeConfig(config, [], cwd);

  assert.deepEqual(runtime.network.allowedDomains, []);
  assert.deepEqual(runtime.network.deniedDomains, ["*"]);
});

test("buildRuntimeConfig includes session write grants", () => {
  const cwd = process.cwd();
  const sessionWrite = "/tmp/runtime-write";
  const config = normalizeConfig({});

  const runtime = buildRuntimeConfig(config, [sessionWrite], cwd);

  assert.ok(runtime.filesystem.allowWrite.includes(cwd));
  assert.ok(runtime.filesystem.allowWrite.includes(sessionWrite));
});
