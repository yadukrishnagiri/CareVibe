#!/usr/bin/env node
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

// Resolve project root (workspace root)
const projectRoot = process.cwd();
const backendDir = path.join(projectRoot, 'backend');
const fixqlDir = path.join(backendDir, 'fixql');
const processSarifPath = path.join(fixqlDir, 'process-sarif.js');

function color(text, code) {
  return `\u001b[${code}m${text}\u001b[0m`;
}
const green = (s) => color(s, '32');
const red = (s) => color(s, '31');
const yellow = (s) => color(s, '33');
const cyan = (s) => color(s, '36');

function parseArgs(argv) {
  const out = { name: null, debug: false };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--name' && i + 1 < argv.length) {
      out.name = argv[++i];
    } else if (a.startsWith('--name=')) {
      out.name = a.split('=')[1];
    } else if (a === '--debug') {
      out.debug = true;
    } else if (a === '-h' || a === '--help') {
      printHelpAndExit();
    }
  }
  return out;
}

function printHelpAndExit(code = 0) {
  console.log(`\nUsage: node backend/fixql/run-codeql.js [--name <base>] [--debug]\n\nSteps executed:\n  1) codeql database create <name>-db --language=javascript\n  2) codeql database analyze <name>-db codeql/javascript-queries@2.1.2 --format=sarif-latest --output=<name>.sarif\n  3) node backend/fixql/process-sarif.js <name>.sarif -o fixprompt/<name>-prompts\n\nExamples:\n  node backend/fixql/run-codeql.js\n  node backend/fixql/run-codeql.js --name myscan\n`);
  process.exit(code);
}

function ask(question) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => rl.question(question, (ans) => { rl.close(); resolve(ans); }));
}

function execCmd(cmd, args, options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { stdio: 'pipe', shell: false, ...options });
    child.stdout.on('data', (d) => process.stdout.write(d));
    child.stderr.on('data', (d) => process.stderr.write(d));
    child.on('close', (code) => {
      if (code === 0) return resolve();
      reject(new Error(`${cmd} exited with code ${code}`));
    });
    child.on('error', (err) => reject(err));
  });
}

async function which(cmd) {
  const probe = process.platform === 'win32' ? 'where' : 'which';
  try {
    await execCmd(probe, [cmd]);
    return true;
  } catch (_) {
    return false;
  }
}

function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function loadBackendEnv() {
  const envPath = path.join(backendDir, '.env');
  if (fs.existsSync(envPath)) {
    try {
      const dotenv = require('dotenv');
      dotenv.config({ path: envPath });
    } catch (_) {
      // dotenv not found or failed; ignore silently
    }
  }
}

async function main() {
  const { name: argName } = parseArgs(process.argv);

  console.log(cyan('CodeQL automation starting...'));

  // Load backend/.env to make GROQ_API_KEY available if present
  loadBackendEnv();

  // 1) Collect base name
  let base = argName;
  if (!base) {
    base = (await ask('Enter a base name (e.g., x): ')).trim();
  }
  if (!base) {
    console.error(red('A non-empty name is required.'));
    process.exit(1);
  }

  const dbName = `${base}-db`;
  const sarifName = `${base}.sarif`;
  const outputDir = path.join(projectRoot, 'fixprompt', `${base}-prompts`);

  // 2) Prerequisite checks
  console.log(cyan('Checking prerequisites...'));
  const hasCodeQL = await which('codeql');
  if (!hasCodeQL) {
    console.error(red('\nCodeQL CLI not found in PATH.'));
    console.log(yellow('Install instructions: https://codeql.github.com/docs/codeql-cli/using-the-codeql-cli/'));
    console.log(yellow('On Windows, ensure the CodeQL CLI directory is added to your PATH.'));
    process.exit(1);
  }

  if (!fs.existsSync(processSarifPath)) {
    console.error(red(`Missing script: ${processSarifPath}`));
    process.exit(1);
  }

  if (!process.env.GROQ_API_KEY) {
    console.error(red('GROQ_API_KEY is not set.'));
    console.log(yellow('Set it in backend/.env or as an environment variable before running.'));
    process.exit(1);
  }

  // 3) Create DB
  console.log(cyan(`\n[1/3] Creating database ${dbName} ...`));
  await execCmd('codeql', ['database', 'create', dbName, '--language=javascript']);
  console.log(green(`Database created: ${dbName}`));

  // 4) Analyze DB
  console.log(cyan(`\n[2/3] Analyzing database ${dbName} ...`));
  await execCmd('codeql', [
    'database', 'analyze', dbName,
    'codeql/javascript-queries@2.1.2',
    '--format=sarif-latest',
    `--output=${sarifName}`
  ]);
  console.log(green(`SARIF generated: ${sarifName}`));

  // 5) Process SARIF to prompts
  console.log(cyan(`\n[3/3] Generating fix prompts ...`));
  ensureDir(path.dirname(outputDir));
  ensureDir(outputDir);
  await execCmd(process.execPath, [processSarifPath, sarifName, '-o', outputDir]);
  console.log(green(`Fix prompts saved to: ${outputDir}`));

  console.log(green('\nAll done.'));
}

main().catch((err) => {
  console.error('\n' + red(err.message));
  process.exit(1);
});


