# FixQL Toolkit

Automation scripts for running CodeQL analyses and generating AI-assisted fix guides.

## Contents

- `run-codeql.js`: Orchestrates database creation, analysis, and SARIF processing.
- `process-sarif.js`: Reads SARIF output and produces markdown fix guides using Groq.
- `test-groq-connection.js`: Quick connectivity check for Groq API credentials.
- `requirements.txt`: Runtime and dependency list for this subproject.

## Requirements

See `requirements.txt` for the authoritative list. At a glance:

- Node.js 18+
- CodeQL CLI on your PATH
- `groq-sdk` and `dotenv` (install with `npm install` in this directory)
- `GROQ_API_KEY` defined in `backend/.env` or your shell environment

## Setup

```bash
cd backend/fixql
npm install groq-sdk dotenv
```

Add your Groq key to `backend/.env`:

```
GROQ_API_KEY=sk_your_key
```

## Usage

1. Run the full pipeline interactively (prompts for a name):

   ```bash
   node backend/fixql/run-codeql.js
   ```

2. Run with a predefined name:

   ```bash
   node backend/fixql/run-codeql.js --name demo
   ```

   Outputs:
   - Database: `demo-db`
   - SARIF: `demo.sarif`
   - Fix guides: `fixprompt/demo-prompts`

3. Process an existing SARIF file:

   ```bash
   node backend/fixql/process-sarif.js demo.sarif -o fixprompt/demo-prompts
   ```

## Troubleshooting

- If CodeQL isn’t found, install it from the GitHub CodeQL CLI release and add it to PATH.
- If Groq requests fail, re-run `node backend/fixql/test-groq-connection.js` to validate credentials.






