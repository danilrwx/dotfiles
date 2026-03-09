#!/usr/bin/env bun

import fs from 'node:fs';
import path from 'node:path';

const SKILL_TEMPLATE = `---
name: {skill_name}
description: [TODO: Complete and informative explanation of what the skill does and when to use it. Include WHEN to use this skill - specific scenarios, file types, or tasks that trigger it.]
---

# {skill_title}

## Overview

[TODO: 1-2 sentences explaining what this skill enables]

## Structuring This Skill

[TODO: Choose the structure that best fits this skill's purpose. Common patterns:

**1. Workflow-Based** (best for sequential processes)
- Works well when there are clear step-by-step procedures
- Example: DOCX skill with "Workflow Decision Tree" → "Reading" → "Creating" → "Editing"
- Structure: ## Overview → ## Workflow Decision Tree → ## Step 1 → ## Step 2...

**2. Task-Based** (best for tool collections)
- Works well when the skill offers different operations/capabilities
- Example: PDF skill with "Quick Start" → "Merge PDFs" → "Split PDFs" → "Extract Text"
- Structure: ## Overview → ## Quick Start → ## Task Category 1 → ## Task Category 2...

**3. Reference/Guidelines** (best for standards or specifications)
- Works well for brand guidelines, coding standards, or requirements
- Example: Brand styling with "Brand Guidelines" → "Colors" → "Typography" → "Features"
- Structure: ## Overview → ## Guidelines → ## Specifications → ## Usage...

**4. Capabilities-Based** (best for integrated systems)
- Works well when the skill provides multiple interrelated features
- Example: Product Management with "Core Capabilities" → numbered capability list
- Structure: ## Overview → ## Core Capabilities → ### 1. Feature → ### 2. Feature...

Patterns can be mixed and matched as needed. Most skills combine patterns (e.g., start with task-based, add workflow for complex operations).

Delete this entire "Structuring This Skill" section when done - it's just guidance.]

## [TODO: Replace with the first main section based on chosen structure]

[TODO: Add content here. See examples in existing skills:
- Code samples for technical skills
- Decision trees for complex workflows
- Concrete examples with realistic user requests
- References to scripts/templates/references as needed]

## Resources

This skill includes example resource directories that demonstrate how to organize different types of bundled resources:

### scripts/
Executable code (TypeScript/Bash/etc.) that can be run directly to perform specific operations.

**Examples from other skills:**
- PDF skill: \`fill_fillable_fields.py\`, \`extract_form_field_info.py\` - utilities for PDF manipulation
- DOCX skill: \`document.py\`, \`utilities.py\` - Python modules for document processing

**Appropriate for:** TypeScript scripts, shell scripts, or any executable code that performs automation, data processing, or specific operations.

**Note:** Scripts may be executed without loading into context, but can still be read by Claude for patching or environment adjustments.

### references/
Documentation and reference material intended to be loaded into context to inform Claude's process and thinking.

**Examples from other skills:**
- Product management: \`communication.md\`, \`context_building.md\` - detailed workflow guides
- BigQuery: API reference documentation and query examples
- Finance: Schema documentation, company policies

**Appropriate for:** In-depth documentation, API references, database schemas, comprehensive guides, or any detailed information that Claude should reference while working.

### assets/
Files not intended to be loaded into context, but rather used within the output Claude produces.

**Examples from other skills:**
- Brand styling: PowerPoint template files (.pptx), logo files
- Frontend builder: HTML/React boilerplate project directories
- Typography: Font files (.ttf, .woff2)

**Appropriate for:** Templates, boilerplate code, document templates, images, icons, fonts, or any files meant to be copied or used in the final output.

---

**Any unneeded directories can be deleted.** Not every skill requires all three types of resources.
`;

const EXAMPLE_SCRIPT = `#!/usr/bin/env node

function main(): void {
  console.log('This is an example script for {skill_name}');
}

main();
`;

const EXAMPLE_REFERENCE = `# Reference Documentation for {skill_title}

This is a placeholder for detailed reference documentation.
Replace with actual reference content or delete if not needed.

Example real reference docs from other skills:
- product-management/references/communication.md - Comprehensive guide for status updates
- product-management/references/context_building.md - Deep-dive on gathering context
- bigquery/references/ - API references and query examples

## When Reference Docs Are Useful

Reference docs are ideal for:
- Comprehensive API documentation
- Detailed workflow guides
- Complex multi-step processes
- Information too lengthy for main SKILL.md
- Content that's only needed for specific use cases

## Structure Suggestions

### API Reference Example
- Overview
- Authentication
- Endpoints with examples
- Error codes
- Rate limits

### Workflow Guide Example
- Prerequisites
- Step-by-step instructions
- Common patterns
- Troubleshooting
- Best practices
`;

const EXAMPLE_ASSET = `# Example Asset File

This placeholder represents where asset files would be stored.
Replace with actual asset files (templates, images, fonts, etc.) or delete if not needed.

Asset files are NOT intended to be loaded into context, but rather used within
the output Claude produces.

Example asset files from other skills:
- Brand guidelines: logo.png, slides_template.pptx
- Frontend builder: hello-world/ directory with HTML/React boilerplate
- Typography: custom-font.ttf, font-family.woff2
- Data: sample_data.csv, test_dataset.json

## Common Asset Types

- Templates: .pptx, .docx, boilerplate directories
- Images: .png, .jpg, .svg, .gif
- Fonts: .ttf, .otf, .woff, .woff2
- Boilerplate code: Project directories, starter files
- Icons: .ico, .svg
- Data files: .csv, .json, .xml, .yaml

Note: This is a text placeholder. Actual assets can be any file type.
`;

function formatTemplate(template: string, values: Record<string, string>): string {
  return template.replace(/\{(\w+)\}/g, (_, key: string) => values[key] ?? '');
}

function titleCaseSkillName(skillName: string): string {
  return skillName
    .split('-')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

export function initSkill(skillName: string, targetPath: string): string | null {
  const skillDir = path.resolve(targetPath, skillName);

  if (fs.existsSync(skillDir)) {
    console.log(`❌ Error: Skill directory already exists: ${skillDir}`);
    return null;
  }

  try {
    fs.mkdirSync(skillDir, { recursive: true });
    console.log(`✅ Created skill directory: ${skillDir}`);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.log(`❌ Error creating directory: ${message}`);
    return null;
  }

  const skillTitle = titleCaseSkillName(skillName);
  const values = { skill_name: skillName, skill_title: skillTitle };
  const skillContent = formatTemplate(SKILL_TEMPLATE, values);
  const skillMdPath = path.join(skillDir, 'SKILL.md');

  try {
    fs.writeFileSync(skillMdPath, skillContent);
    console.log('✅ Created SKILL.md');
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.log(`❌ Error creating SKILL.md: ${message}`);
    return null;
  }

  try {
    const scriptsDir = path.join(skillDir, 'scripts');
    fs.mkdirSync(scriptsDir, { recursive: true });
    const exampleScript = path.join(scriptsDir, 'example.ts');
    fs.writeFileSync(exampleScript, formatTemplate(EXAMPLE_SCRIPT, values));
    fs.chmodSync(exampleScript, 0o755);
    console.log('✅ Created scripts/example.ts');

    const referencesDir = path.join(skillDir, 'references');
    fs.mkdirSync(referencesDir, { recursive: true });
    const exampleReference = path.join(referencesDir, 'api_reference.md');
    fs.writeFileSync(exampleReference, formatTemplate(EXAMPLE_REFERENCE, values));
    console.log('✅ Created references/api_reference.md');

    const assetsDir = path.join(skillDir, 'assets');
    fs.mkdirSync(assetsDir, { recursive: true });
    const exampleAsset = path.join(assetsDir, 'example_asset.txt');
    fs.writeFileSync(exampleAsset, EXAMPLE_ASSET);
    console.log('✅ Created assets/example_asset.txt');
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.log(`❌ Error creating resource directories: ${message}`);
    return null;
  }

  console.log(`\n✅ Skill '${skillName}' initialized successfully at ${skillDir}`);
  console.log('\nNext steps:');
  console.log('1. Edit SKILL.md to complete the TODO items and update the description');
  console.log('2. Customize or delete the example files in scripts/, references/, and assets/');
  console.log('3. Run the validator when ready to check the skill structure');

  return skillDir;
}

function main(): void {
  if (process.argv.length < 5 || process.argv[3] !== '--path') {
    console.log('Usage: ./init_skill.ts <skill-name> --path <path>');
    console.log('\nSkill name requirements:');
    console.log("  - Kebab-case identifier (e.g., 'my-data-analyzer')");
    console.log('  - Lowercase letters, digits, and hyphens only');
    console.log('  - Max 64 characters');
    console.log('  - Must match directory name exactly');
    console.log('\nExamples:');
    console.log('  ./init_skill.ts my-new-skill --path skills/public');
    console.log('  ./init_skill.ts my-api-helper --path skills/private');
    console.log('  ./init_skill.ts custom-skill --path /custom/location');
    process.exit(1);
  }

  const skillName = process.argv[2];
  const targetPath = process.argv[4];

  console.log(`🚀 Initializing skill: ${skillName}`);
  console.log(`   Location: ${targetPath}`);
  console.log();

  const result = initSkill(skillName, targetPath);
  process.exit(result ? 0 : 1);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
