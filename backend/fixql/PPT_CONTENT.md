# PPT Content (CodeQL + FixQL)

## Background / Problem Statement
- Security findings take time to understand and fix
- CodeQL/SARIF reports are detailed but not “actionable” for everyone
- Fixing issues needs consistent guidance + test steps
- Teams need faster secure delivery without rework

In many projects, security scanning is available, but converting findings into clear fixes is slow. Developers spend time interpreting results, deciding changes, and validating fixes—especially under tight delivery timelines.

## Gaps Identified
- Findings lack clear “what to change” instructions
- No standard fix format across issues/teams
- Manual review consumes senior engineer time
- Limited traceability of fix guidance created

These gaps cause delays and inconsistency: similar issues get fixed differently, validation steps get missed, and teams depend on a few experts to interpret reports.

## Customer’s Domain / Industry
- Application security (AppSec)
- Software development (SDLC/DevSecOps)
- Secure code review & remediation
- Compliance-ready engineering practices

This solution supports teams that run security scans (like CodeQL) and want faster, clearer remediation. It helps reduce effort from report interpretation to implementing and validating fixes.

## Proposed Solution**
- Run CodeQL to generate SARIF security findings
- Use FixQL to convert SARIF into fix guides (Markdown)
- Use Groq (LLM) to create “explain + fix + test plan”
- Store outputs in `fixprompt/` for review and reuse

FixQL acts as a bridge between scanning and remediation. It takes real CodeQL results and produces developer-friendly fix guides so teams can fix faster and more consistently.

## User’s Impacted
- Developers fixing backend/security issues
- AppSec / security reviewers validating changes
- Tech leads tracking remediation progress
- QA verifying test steps from the guide

Users get a simpler workflow: instead of reading raw findings and starting from scratch, they get structured guidance that speeds up implementation and verification.

## Is this idea beneficial to HCL Team ?
- Faster turnaround on security remediation
- Standardized fix-guide format across projects
- Reduced dependency on a few security experts
- Stronger delivery story (DevSecOps + AI assist)

This improves productivity and consistency for delivery teams, and helps position HCL with a practical accelerator that supports secure engineering outcomes.

## Benefits to the Customer**
- Quicker resolution of security findings
- Better consistency in fixes and validation steps
- Improved audit readiness (documented guidance)
- Lower risk of repeat issues and regressions

Customers benefit from faster and more reliable remediation, with clearer evidence of what was fixed and how it was validated.

## Is this Idea Re-usable? **
- Reusable across any CodeQL + SARIF pipeline
- Works for multiple repos with minimal setup
- Output format (Markdown) is easy to share/review
- Can extend to other scanners that output SARIF

The approach is not limited to one application. Any team using CodeQL (or SARIF-producing tools) can reuse FixQL as a repeatable remediation accelerator.

## Words from the Customer / Approval Mail**
- “Approved to proceed with a pilot for FixQL”
- “This will reduce time to understand findings”
- “Please implement and share the fix guides”
- Approval mail attached / pending

Add a short quote from the sponsor or a sentence from the approval email. If approval is pending, keep the placeholder line and update after confirmation.

## Tools and Technology Used
- Git / GitHub
- CodeQL + SARIF
- Groq LLM API
- Node.js scripts (FixQL)

This solution leverages an industry-standard security scanner (CodeQL) and a portable format (SARIF), then adds an AI-assisted step to generate fix documentation in a consistent structure.

## Technology Environment:
- GitHub Actions (CodeQL workflow) or CodeQL CLI (local)
- SARIF report generation and processing
- Node.js runtime for FixQL automation
- Secure storage of API keys/secrets (env vars)

FixQL runs as an automation layer around CodeQL outputs, producing Markdown fix guides from SARIF findings for faster remediation and review.

## Tools Used:
- VS Code / Cursor
- CodeQL CLI / GitHub CodeQL
- GitHub Actions (CI)
- Groq SDK + dotenv (FixQL)

These tools enable scan automation, SARIF processing, and consistent fix-guide generation that is easy to review and share.

## Framework and Methodologies Used:
- DevSecOps / Shift-left security
- SAST scanning with CodeQL (CI + local)
- Standardized remediation workflow (guide + test plan)
- Peer review for security fixes

Security scanning is integrated into the delivery workflow so findings are identified early and remediated with consistent, repeatable guidance.
