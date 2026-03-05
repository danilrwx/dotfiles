#!/usr/bin/env bun

import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { validateSkill } from './quick_validate';

function listFilesRecursive(dirPath: string): string[] {
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });
  const files: string[] = [];

  for (const entry of entries) {
    const fullPath = path.join(dirPath, entry.name);
    if (entry.isDirectory()) {
      files.push(...listFilesRecursive(fullPath));
    } else if (entry.isFile()) {
      files.push(fullPath);
    }
  }

  return files;
}

export function packageSkill(skillPathInput: string, outputDir?: string): string | null {
  const skillPath = path.resolve(skillPathInput);

  if (!fs.existsSync(skillPath)) {
    console.log(`❌ Error: Skill folder not found: ${skillPath}`);
    return null;
  }

  if (!fs.statSync(skillPath).isDirectory()) {
    console.log(`❌ Error: Path is not a directory: ${skillPath}`);
    return null;
  }

  const skillMd = path.join(skillPath, 'SKILL.md');
  if (!fs.existsSync(skillMd)) {
    console.log(`❌ Error: SKILL.md not found in ${skillPath}`);
    return null;
  }

  console.log('🔍 Validating skill...');
  const [valid, message] = validateSkill(skillPath);
  if (!valid) {
    console.log(`❌ Validation failed: ${message}`);
    console.log('   Please fix the validation errors before packaging.');
    return null;
  }
  console.log(`✅ ${message}\n`);

  const skillName = path.basename(skillPath);
  const outputPath = outputDir ? path.resolve(outputDir) : process.cwd();

  fs.mkdirSync(outputPath, { recursive: true });

  const skillFilename = path.join(outputPath, `${skillName}.skill`);
  const parentDir = path.dirname(skillPath);

  const files = listFilesRecursive(skillPath)
    .map((filePath) => path.relative(parentDir, filePath))
    .sort();

  for (const file of files) {
    console.log(`  Added: ${file}`);
  }

  try {
    if (fs.existsSync(skillFilename)) {
      fs.unlinkSync(skillFilename);
    }

    execFileSync('zip', ['-rq', skillFilename, skillName], { cwd: parentDir, stdio: 'ignore' });
    console.log(`\n✅ Successfully packaged skill to: ${skillFilename}`);
    return skillFilename;
  } catch (error) {
    const messageText = error instanceof Error ? error.message : String(error);
    console.log(`❌ Error creating .skill file: ${messageText}`);
    return null;
  }
}

function main(): void {
  if (process.argv.length < 3) {
    console.log('Usage: ./package_skill.ts <path/to/skill-folder> [output-directory]');
    console.log('\nExample:');
    console.log('  ./package_skill.ts skills/public/my-skill');
    console.log('  ./package_skill.ts skills/public/my-skill ./dist');
    process.exit(1);
  }

  const skillPath = process.argv[2];
  const outputDir = process.argv[3];

  console.log(`📦 Packaging skill: ${skillPath}`);
  if (outputDir) {
    console.log(`   Output directory: ${outputDir}`);
  }
  console.log();

  const result = packageSkill(skillPath, outputDir);
  process.exit(result ? 0 : 1);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
