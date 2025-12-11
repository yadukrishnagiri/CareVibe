# FixQL Adoption Guide

How to bring the `backend/fixql` toolkit into your own project and get it running end-to-end.

## 1. Prepare the environment in your project workspace

1. Install Git (https://git-scm.com/) or copy this repository into your project workspace before proceeding.
2. Install Node.js 18 or later from <https://nodejs.org/> (`node -v` should confirm the version).
3. Install the CodeQL CLI (no VS Code extension is required):
   - Download the latest release from <https://github.com/github/codeql-cli-binaries/releases>.
   - Extract the ZIP somewhere permanent (e.g., `C:\tools\codeql` or `/opt/codeql`).
   - Add the extracted `codeql` directory to your PATH (e.g., `C:\tools\codeql` on Windows via System Properties → Environment Variables → Path, or add `export PATH="/opt/codeql:$PATH"` to your shell profile on macOS/Linux).
   - Verify with:
     ```
     codeql version
     codeql resolve qlpacks
     codeql resolve languages
     ```
4. Create or log in to your Groq account at <https://console.groq.com/> and generate an API key.

## 2. Place the FixQL toolkit

1. Copy the entire `backend/fixql` folder into the new project’s `backend` directory.
2. From the repo root:
   ```bash
   cd backend/fixql
   npm install groq-sdk dotenv
   ```

## 3. Configure environment variables

1. Edit or create `backend/.env`:
   ```
   GROQ_API_KEY=sk_your_groq_key
   ```
2. Optionally mirror the same value in your shell environment if you prefer, but keeping it in `backend/.env` is sufficient for the scripts.
3. Test the key:
   ```bash
   node backend/fixql/test-groq-connection.js
   ```

## 4. Prepare output folders

- Ensure a `fixprompt/` directory exists at the repo root. The automation will create `<base>-prompts` subfolders automatically.

## 5. Run the end-to-end workflow

Interactive (prompts for a base name):

```bash
node backend/fixql/run-codeql.js
```

Non-interactive:

```bash
node backend/fixql/run-codeql.js --name demo
```

Outcome:
- Database: `demo-db`
- SARIF: `demo.sarif`
- Fix guides: `fixprompt/demo-prompts`

If you already have a SARIF file:

```bash
node backend/fixql/process-sarif.js demo.sarif -o fixprompt/demo-prompts
```

## 6. Troubleshooting

- **CodeQL not found**: Re-check PATH and reopen your terminal after editing environment variables.
- **Groq errors**: Re-run `test-groq-connection.js`; confirm `GROQ_API_KEY` is set and network access is available.
- **No `fixprompt` folder**: Create it manually at the repo root.
- **Permission issues on Windows**: Run terminal as Administrator when installing CodeQL or writing to protected directories.

## 7. Review results

- SARIF reports land in the repo root (e.g., `demo.sarif`).
- Generated fix guides are inside `fixprompt/<base>-prompts/*.md`. Open them to review and apply fixes.


