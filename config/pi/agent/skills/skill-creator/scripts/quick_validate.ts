#!/usr/bin/env bun

import fs from 'node:fs';
import path from 'node:path';

export type ValidateResult = [valid: boolean, message: string];

type Frontmatter = Record<string, unknown>;

function extractFrontmatter(content: string): string | null {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/);
  return match ? match[1] : null;
}

function parseInlineValue(raw: string): unknown {
  const value = raw.trim();
  if (!value) {
    return '';
  }

  if (
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    return value.slice(1, -1);
  }

  if (value === 'true') return true;
  if (value === 'false') return false;
  if (value === 'null') return null;

  if (/^-?\d+(\.\d+)?$/.test(value)) {
    return Number(value);
  }

  if (value.startsWith('[') && value.endsWith(']')) {
    return value
      .slice(1, -1)
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean)
      .map((item) => parseInlineValue(item));
  }

  return value;
}

function parseFrontmatter(text: string): Frontmatter | null {
  const lines = text.split(/\r?\n/);
  const result: Frontmatter = {};

  let i = 0;
  while (i < lines.length) {
    const line = lines[i];

    if (!line.trim() || line.trimStart().startsWith('#')) {
      i += 1;
      continue;
    }

    const topLevel = line.match(/^([a-zA-Z0-9_-]+):(.*)$/);
    if (!topLevel) {
      if (/^\s+/.test(line)) {
        i += 1;
        continue;
      }
      return null;
    }

    const key = topLevel[1];
    const rest = topLevel[2].trim();

    if (rest) {
      result[key] = parseInlineValue(rest);
      i += 1;
      continue;
    }

    const nestedLines: string[] = [];
    i += 1;
    while (i < lines.length) {
      const next = lines[i];
      if (!next.trim()) {
        nestedLines.push(next);
        i += 1;
        continue;
      }
      if (/^\s+/.test(next)) {
        nestedLines.push(next);
        i += 1;
        continue;
      }
      break;
    }

    const trimmed = nestedLines.map((lineValue) => lineValue.trim()).filter(Boolean);
    if (trimmed.length === 0) {
      result[key] = '';
      continue;
    }

    if (trimmed.every((lineValue) => lineValue.startsWith('- '))) {
      result[key] = trimmed.map((lineValue) => parseInlineValue(lineValue.slice(2)));
      continue;
    }

    if (trimmed.every((lineValue) => /^[a-zA-Z0-9_-]+\s*:/.test(lineValue))) {
      result[key] = {};
      continue;
    }

    result[key] = trimmed.join('\n');
  }

  return result;
}

export function validateSkill(skillPathInput: string): ValidateResult {
  const skillPath = path.resolve(skillPathInput);
  const skillMdPath = path.join(skillPath, 'SKILL.md');

  if (!fs.existsSync(skillMdPath)) {
    return [false, 'SKILL.md not found'];
  }

  const content = fs.readFileSync(skillMdPath, 'utf8');
  if (!content.startsWith('---')) {
    return [false, 'No YAML frontmatter found'];
  }

  const frontmatterText = extractFrontmatter(content);
  if (!frontmatterText) {
    return [false, 'Invalid frontmatter format'];
  }

  const frontmatter = parseFrontmatter(frontmatterText);
  if (!frontmatter || typeof frontmatter !== 'object' || Array.isArray(frontmatter)) {
    return [false, 'Frontmatter must be a YAML dictionary'];
  }

  const allowedProperties = new Set([
    'name',
    'description',
    'license',
    'allowed-tools',
    'metadata',
    'compatibility',
  ]);

  const keys = Object.keys(frontmatter);
  const unexpectedKeys = keys.filter((key) => !allowedProperties.has(key));

  if (unexpectedKeys.length > 0) {
    return [
      false,
      `Unexpected key(s) in SKILL.md frontmatter: ${unexpectedKeys.sort().join(', ')}. Allowed properties are: ${Array.from(allowedProperties).sort().join(', ')}`,
    ];
  }

  if (!Object.hasOwn(frontmatter, 'name')) {
    return [false, "Missing 'name' in frontmatter"];
  }
  if (!Object.hasOwn(frontmatter, 'description')) {
    return [false, "Missing 'description' in frontmatter"];
  }

  const name = frontmatter.name;
  if (typeof name !== 'string') {
    return [false, `Name must be a string, got ${typeof name}`];
  }

  const normalizedName = name.trim();
  if (normalizedName) {
    if (!/^[a-z0-9-]+$/.test(normalizedName)) {
      return [false, `Name '${normalizedName}' should be kebab-case (lowercase letters, digits, and hyphens only)`];
    }
    if (normalizedName.startsWith('-') || normalizedName.endsWith('-') || normalizedName.includes('--')) {
      return [false, `Name '${normalizedName}' cannot start/end with hyphen or contain consecutive hyphens`];
    }
    if (normalizedName.length > 64) {
      return [false, `Name is too long (${normalizedName.length} characters). Maximum is 64 characters.`];
    }
  }

  const description = frontmatter.description;
  if (typeof description !== 'string') {
    return [false, `Description must be a string, got ${typeof description}`];
  }

  const normalizedDescription = description.trim();
  if (normalizedDescription) {
    if (normalizedDescription.includes('<') || normalizedDescription.includes('>')) {
      return [false, 'Description cannot contain angle brackets (< or >)'];
    }
    if (normalizedDescription.length > 1024) {
      return [false, `Description is too long (${normalizedDescription.length} characters). Maximum is 1024 characters.`];
    }
  }

  const compatibility = frontmatter.compatibility;
  if (compatibility !== undefined && compatibility !== null && compatibility !== '') {
    if (typeof compatibility !== 'string') {
      return [false, `Compatibility must be a string, got ${typeof compatibility}`];
    }
    if (compatibility.length > 500) {
      return [false, `Compatibility is too long (${compatibility.length} characters). Maximum is 500 characters.`];
    }
  }

  return [true, 'Skill is valid!'];
}

function main(): void {
  if (process.argv.length !== 3) {
    console.log('Usage: ./quick_validate.ts <skill_directory>');
    process.exit(1);
  }

  const [valid, message] = validateSkill(process.argv[2]);
  console.log(message);
  process.exit(valid ? 0 : 1);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
