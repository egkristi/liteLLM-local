# AI Agent Instructions — liteLLM-local

## Workflow

1. **Solve issues first**
   - Read `ISSUES.md` and fix all open issues before starting new work.
   - When an issue is fixed, move it to the **Closed** section and describe the resolution.

2. **Work the roadmap**
   - After issues are cleared, continue with items in `ROADMAP.md` (priority: **Now**, then **Next**, then **Later**).
   - Mark items as completed (`[x]`) when done.

3. **Capture new work**
   - If a new feature idea or improvement is identified during work, add it to `ROADMAP.md` in the appropriate section.
   - If a bug, inconsistency, or problem is discovered, add it to `ISSUES.md` under **Open**.

4. **Document changes**
   - For every new feature or meaningful change, update `CHANGELOG.md` under `[Unreleased]`.
   - Use the Keep a Changelog format (`Added`, `Changed`, `Fixed`, `Deprecated`, `Removed`, `Security`).

5. **Commit and push**
   - After completing a batch of work (issues fixed, roadmap items done, docs updated), commit with a descriptive message.
   - Push to `origin/main` immediately after committing.

## Commit message style

- Use conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`
- Include a short summary and bullet points for multi-part changes.

## Code style

- Shell scripts: `set -euo pipefail`, use `#!/usr/bin/env bash`, quote variables.
- YAML: 2-space indentation, keep lists aligned.
- Python: PEP 8, type hints where practical.
