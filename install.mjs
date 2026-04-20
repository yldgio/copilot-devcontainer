#!/usr/bin/env node
/**
 * Copies .devcontainer/ and .mcp.json from this bundle into the current directory.
 * Run via: npx github:yldgio/copilot-devcontainer
 *          npx github:yldgio/copilot-devcontainer#v1.0.0  (pinned version)
 */
import { existsSync, cpSync, copyFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = fileURLToPath(new URL('.', import.meta.url));
const dest = process.cwd();
const force = process.argv.includes('--force');

const srcDevcontainer = join(__dirname, '.devcontainer');
const srcMcp = join(__dirname, '.mcp.json');
const destDevcontainer = join(dest, '.devcontainer');
const destMcp = join(dest, '.mcp.json');

if (existsSync(destDevcontainer) && !force) {
  console.error(`\n❌  .devcontainer/ already exists in ${dest}`);
  console.error('    Use --force to overwrite:\n');
  console.error('    npx github:yldgio/copilot-devcontainer -- --force\n');
  process.exit(1);
}

console.log('\n  › Copying .devcontainer/ ...');
cpSync(srcDevcontainer, destDevcontainer, { recursive: true });

console.log('  › Copying .mcp.json ...');
copyFileSync(srcMcp, destMcp);

console.log('\n✅  Dev container files installed successfully.');
console.log('    Open this folder in VS Code and choose:');
console.log('    Dev Containers: Reopen in Container\n');
