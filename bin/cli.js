#!/usr/bin/env node
/**
 * @maestrogtm/quickstart CLI
 *
 * Commands:
 *   install   — copy the skill files into ~/.claude/skills/quickstart/
 *   upgrade   — replace existing skill files with the latest from this package
 *   uninstall — remove ~/.claude/skills/quickstart/
 *   version   — print package version
 *
 * Flags:
 *   --force       overwrite without prompting (install/upgrade)
 *   --dry-run     show what would happen, don't write
 *   --target <p>  install into a custom path (default ~/.claude/skills/quickstart)
 */

'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');
const readline = require('readline');

// ── ANSI colors (no dependencies) ──────────────────────────────────────────
const C = {
  reset: '\x1b[0m',
  dim: '\x1b[2m',
  bold: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
};
const color = (c, s) => `${C[c]}${s}${C.reset}`;

// ── Args ───────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const cmd = args[0] || 'install';
const flags = {
  force: args.includes('--force'),
  dryRun: args.includes('--dry-run'),
  target: null,
};
const tIdx = args.indexOf('--target');
if (tIdx >= 0 && args[tIdx + 1]) flags.target = args[tIdx + 1];

const PKG_ROOT = path.join(__dirname, '..');
const SKILL_SRC = path.join(PKG_ROOT, 'skill');
const SKILL_DST = flags.target
  ? path.resolve(flags.target)
  : path.join(os.homedir(), '.claude', 'skills', 'quickstart');

// ── Helpers ────────────────────────────────────────────────────────────────
function prompt(question) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim().toLowerCase());
    });
  });
}

function copyRecursive(src, dst, { dryRun }) {
  const stat = fs.statSync(src);
  if (stat.isDirectory()) {
    if (!dryRun && !fs.existsSync(dst)) fs.mkdirSync(dst, { recursive: true });
    for (const entry of fs.readdirSync(src)) {
      copyRecursive(path.join(src, entry), path.join(dst, entry), { dryRun });
    }
  } else {
    if (dryRun) {
      console.log(`  ${color('dim', '→')} ${path.relative(SKILL_DST, dst)}`);
    } else {
      fs.copyFileSync(src, dst);
      // Preserve executable bit on shell scripts
      if (dst.endsWith('.sh')) fs.chmodSync(dst, 0o755);
    }
  }
}

function removeRecursive(p) {
  if (!fs.existsSync(p)) return;
  fs.rmSync(p, { recursive: true, force: true });
}

function loadPkgVersion() {
  try {
    const pkg = JSON.parse(fs.readFileSync(path.join(PKG_ROOT, 'package.json'), 'utf8'));
    return pkg.version;
  } catch {
    return 'unknown';
  }
}

// ── Commands ───────────────────────────────────────────────────────────────
async function cmdInstall() {
  const version = loadPkgVersion();
  console.log('');
  console.log(`${color('bold', 'Maestro Quickstart')} ${color('dim', `v${version}`)}`);
  console.log('');

  if (!fs.existsSync(SKILL_SRC)) {
    console.error(color('red', `Source files missing at ${SKILL_SRC}`));
    console.error(color('red', 'This is a package error — please reinstall via `npx @maestrogtm/quickstart@latest install`.'));
    process.exit(1);
  }

  const exists = fs.existsSync(SKILL_DST);
  if (exists && !flags.force && !flags.dryRun) {
    const answer = await prompt(
      `Skill already exists at ${color('cyan', SKILL_DST)}. Overwrite? [y/N] `
    );
    if (answer !== 'y' && answer !== 'yes') {
      console.log(color('yellow', 'Aborted.'));
      console.log(color('dim', 'Tip: use `npx @maestrogtm/quickstart upgrade --force` to overwrite without prompting.'));
      process.exit(0);
    }
    // Save state.json if present so we don't wipe in-progress runs
    const stateFile = path.join(SKILL_DST, 'state.json');
    if (fs.existsSync(stateFile)) {
      const backup = path.join(SKILL_DST, `state.backup.${Date.now()}.json`);
      fs.copyFileSync(stateFile, backup);
      console.log(color('dim', `Backed up state.json → ${path.basename(backup)}`));
    }
  }

  console.log(`Installing to ${color('cyan', SKILL_DST)}${flags.dryRun ? color('yellow', ' (dry run)') : ''}`);
  console.log('');

  copyRecursive(SKILL_SRC, SKILL_DST, { dryRun: flags.dryRun });

  if (flags.dryRun) {
    console.log('');
    console.log(color('dim', 'Dry run complete — no files written.'));
    return;
  }

  // Make sure secrets/ exists with .gitignore
  const secretsDir = path.join(SKILL_DST, 'secrets');
  if (!fs.existsSync(secretsDir)) fs.mkdirSync(secretsDir, { recursive: true });
  const gitignorePath = path.join(secretsDir, '.gitignore');
  if (!fs.existsSync(gitignorePath)) fs.writeFileSync(gitignorePath, '*\n!.gitignore\n');

  // Make sure data/ exists for campaign artifacts
  const dataDir = path.join(SKILL_DST, 'data');
  if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });

  console.log('');
  console.log(color('green', '✓ Installed.'));
  console.log('');
  console.log(`${color('bold', 'Next:')}`);
  console.log(`  1. Open Claude Code: ${color('cyan', 'claude')}`);
  console.log(`  2. Type: ${color('cyan', '/quickstart')}`);
  console.log('');
  console.log(color('dim', `Docs + walkthroughs: https://modernagencysales.com/learn`));
  console.log('');
}

async function cmdUpgrade() {
  flags.force = true; // upgrade implies overwrite
  await cmdInstall();
}

async function cmdUninstall() {
  console.log('');
  if (!fs.existsSync(SKILL_DST)) {
    console.log(color('yellow', `Nothing to uninstall — ${SKILL_DST} does not exist.`));
    return;
  }
  const answer = await prompt(
    `Remove ${color('cyan', SKILL_DST)} (state.json + any data/ artifacts will be lost)? [y/N] `
  );
  if (answer !== 'y' && answer !== 'yes') {
    console.log(color('yellow', 'Aborted.'));
    return;
  }
  removeRecursive(SKILL_DST);
  console.log(color('green', '✓ Removed.'));
}

function cmdVersion() {
  console.log(loadPkgVersion());
}

function cmdHelp() {
  const version = loadPkgVersion();
  console.log(`
${color('bold', 'Maestro Quickstart')} ${color('dim', `v${version}`)}

${color('bold', 'Usage:')}
  npx @maestrogtm/quickstart <command> [flags]

${color('bold', 'Commands:')}
  install      Install the skill into ~/.claude/skills/quickstart/  ${color('dim', '(default)')}
  upgrade      Overwrite existing skill files with the latest
  uninstall    Remove ~/.claude/skills/quickstart/
  version      Print package version
  help         Show this message

${color('bold', 'Flags:')}
  --force            Overwrite without prompting
  --dry-run          Show what would be written, don't write
  --target <path>    Install into a custom path

${color('bold', 'Examples:')}
  npx @maestrogtm/quickstart                       ${color('dim', '# install')}
  npx @maestrogtm/quickstart install               ${color('dim', '# same')}
  npx @maestrogtm/quickstart upgrade               ${color('dim', '# update to latest')}
  npx @maestrogtm/quickstart install --dry-run     ${color('dim', '# preview only')}

${color('dim', 'Docs: https://modernagencysales.com/learn')}
`);
}

// ── Main ───────────────────────────────────────────────────────────────────
(async () => {
  try {
    switch (cmd) {
      case 'install':
        await cmdInstall();
        break;
      case 'upgrade':
        await cmdUpgrade();
        break;
      case 'uninstall':
        await cmdUninstall();
        break;
      case 'version':
      case '-v':
      case '--version':
        cmdVersion();
        break;
      case 'help':
      case '-h':
      case '--help':
        cmdHelp();
        break;
      default:
        console.error(color('red', `Unknown command: ${cmd}`));
        cmdHelp();
        process.exit(1);
    }
  } catch (err) {
    console.error(color('red', `Error: ${err.message}`));
    if (process.env.DEBUG) console.error(err.stack);
    process.exit(1);
  }
})();
