# AI Agent Instructions — liteLLM-local

## Project Overview

A local LiteLLM proxy providing a single OpenAI-compatible endpoint for multiple AI providers (DeepSeek, Anthropic, Groq, Mistral, Kimi, Ollama). Runs on `http://localhost:4000`.

## Tech Stack

- **Runtime**: Python 3.9 (system default on macOS — no union type syntax `X | Y`)
- **Package Manager**: `uv` (Astral)
- **Proxy**: LiteLLM with Uvicorn/FastAPI
- **Local Models**: Ollama
- **Monitoring**: Prometheus + Grafana (optional, Docker)
- **Web UI**: Zero-dependency Python `http.server`

## File Inventory

| File | Purpose |
|---|---|
| `config.yaml` | Model definitions, API key mappings, fallback chains |
| `.env` | API keys (gitignored) |
| `.env.example` | Template for `.env` |
| `start.sh` | Start proxy with prerequisite checks |
| `stop.sh` | Clean proxy shutdown |
| `status.sh` | Health check + model listing |
| `usage.sh` | Usage/cost from logs |
| `test.sh` | Smoke-test chat completion |
| `webui.py` | Web dashboard (port 8080) |
| `litellm-local` | Cross-platform Python wrapper CLI |
| `Makefile` | Common commands (`make start`, `make status`, ...) |
| `docker-compose.yml` | Docker deployment |
| `docker-compose.monitoring.yml` | Prometheus + Grafana stack |
| `monitoring/` | Prometheus/Grafana config |
| `.vscode/settings.json` | VS Code Copilot Chat snippet |
| `docs/ADDING_MODELS.md` | Guide for adding custom models |
| `ISSUES.md` | Known issues & fixes |
| `ROADMAP.md` | Planned features |
| `CHANGELOG.md` | Release history |
| `AGENTS.md` | This file |

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

## Subagent Usage — Work Faster, Better, Cheaper

Use subagents (`runSubagent` tool) aggressively to parallelize work, improve quality, reduce cost, and produce better solutions. Subagents are the **primary mechanism for efficiency** in this project.

### Core principle: right model for the job

Subagents can use **different models** than the primary agent. Choose the model that best fits each task:

| Task type | Recommended model | Why |
|-----------|-------------------|-----|
| **Research & exploration** — codebase search, file reading, tracing call chains | Fast/cheap model (e.g., GPT-4o mini, Claude Haiku) | Read-heavy, minimal reasoning needed |
| **Quality assurance** — reviewing architecture, design, edge cases | Strong reasoning model (e.g., Claude Sonnet, GPT-4o, DeepSeek) | Needs deep understanding of trade-offs |
| **Documentation updates** — CHANGELOG, README, ROADMAP, docs/ | Fast/cheap model | Simple text generation, no code execution |
| **Code generation** — writing implementation code | Strong coding model (e.g., Claude Sonnet, DeepSeek Coder) | Needs to produce correct, idiomatic code |
| **Shell script fixes** — bash quoting, POSIX compat | Fast/cheap model | Well-defined patterns, low complexity |
| **Architecture decisions** — design patterns, trade-off analysis | Strongest reasoning model | High-stakes, many constraints |
| **Simple grep/search** — finding strings, reading files | Fastest/cheapest model | Trivial pattern matching |

**Always specify the `model` parameter** when launching a subagent to ensure the right capabilities for the task. Don't waste a strong model on a simple search, and don't trust a weak model with architecture decisions.

### When to use subagents

| Scenario | Why | Cost Impact |
|----------|-----|-------------|
| **Research & exploration** — understanding codebase structure, finding relevant files, tracing call chains | Avoids cluttering main conversation with many sequential read/search calls | 🟢 Cheaper — subagents use smaller context windows |
| **Quality assurance** — reviewing architecture decisions, design choices, and solution approaches before writing code | Catches issues early, reduces rework cycles | 🟢 Cheaper — one fix vs. multiple iterations |
| **Parallel work** — multiple independent tasks (e.g., fix a shell script + update docs + add a feature) | Subagents run in parallel, cutting total time | 🟢 Cheaper — fewer total turns |
| **Documentation updates** — CHANGELOG, README, ROADMAP, docs/ after code changes | Keeps docs in sync without blocking main workflow | 🟢 Cheaper — subagent handles docs while you code |
| **Finding optimal solutions** — researching best practices, library alternatives, design patterns before implementing | Produces better code on first attempt | 🟢 Cheaper — less rework, fewer wasted tokens |
| **Validating assumptions** — checking if a proposed approach will work before writing code | Prevents dead-end implementations | 🟢 Cheaper — fail fast with minimal cost |

### How to use subagents

```markdown
# Example: Research phase before implementing (use fast/cheap model)
RunSubagent(Explore, model="GPT-4o mini (copilot)"):
  "Research the best approach for adding rate limiting to LiteLLM.
   Check: config.yaml for existing rate_limit settings, docs/ for any notes,
   ISSUES.md for related items, and the LiteLLM docs for rate limiting support.
   Return: recommended approach, files to modify, and any gotchas."

# Example: QA review of a solution (use strong reasoning model)
RunSubagent(Explore, model="Claude Sonnet (copilot)"):
  "Review the proposed changes for [feature X].
   Check: Does the approach handle edge cases? Is it consistent with existing
   code style (Python 3.9 compat, shell quoting, YAML formatting)?
   Are there simpler alternatives? Return: review findings and suggestions."

# Example: Parallel documentation update (use fast/cheap model)
RunSubagent(Explore, model="GPT-4o mini (copilot)"):
  "Update CHANGELOG.md under [Unreleased] with the changes just made:
   [list changes]. Use Keep a Changelog format."
```

### Subagent patterns for common tasks

**Pattern 1: Research → Implement → QA → Document**
1. **Research** (subagent, fast model): Explore codebase, find relevant files, recommend approach
2. **Implement** (main agent): Write the code changes
3. **QA** (subagent, strong model): Review the implementation for bugs, edge cases, style issues
4. **Document** (subagent, fast model): Update CHANGELOG, docs, ROADMAP in parallel

**Pattern 2: Parallel exploration with right models**
```
# Launch multiple subagents simultaneously, each with appropriate model
RunSubagent(Explore, model="GPT-4o mini (copilot)"): "Find all shell scripts with 'local' keyword issues"
RunSubagent(Explore, model="GPT-4o mini (copilot)"): "Find all Python files with Union type hints vs | syntax"
RunSubagent(Explore, model="Claude Sonnet (copilot)"): "Review config.yaml architecture — are fallback chains optimal?"
```

**Pattern 3: Cost-aware batching**
- Group small, independent fixes into a single subagent task with a fast/cheap model
- Use subagents for read-only exploration (no token waste on tool calls)
- Reserve strong/expensive models for architecture review, security audit, and complex code generation
- Let subagents fail fast — if a subagent can't find what it needs, the main agent can redirect with minimal cost

### Subagent quality checklist

Before asking a subagent to review your work, ensure it checks:
- [ ] **Correctness** — does the solution handle edge cases and error states?
- [ ] **Consistency** — does it match the project's code style (Python 3.9, shell quoting, YAML 2-space)?
- [ ] **Simplicity** — is there a simpler approach that achieves the same result?
- [ ] **Performance** — will it work well on the target hardware (macOS, potentially low-RAM)?
- [ ] **Security** — does it avoid common pitfalls (command injection, secret exposure, unsafe eval)?
- [ ] **Maintainability** — is the code readable and well-structured for future contributors?

## Commit message style

- Use conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`
- Include a short summary and bullet points for multi-part changes.

## Code style

- Shell scripts: `set -euo pipefail`, use `#!/usr/bin/env bash`, quote variables.
- YAML: 2-space indentation, keep lists aligned.
- Python: PEP 8, type hints where practical. **Critical**: Use `Union[X, Y]` or `Optional[X]` instead of `X | Y` union syntax for Python 3.9 compatibility.

## Testing Notes

- The proxy requires valid API keys in `.env` for cloud providers to work.
- Local Ollama models work without API keys but require Ollama to be running.
- The `test.sh` script uses `deepseek-v4-pro` which requires a valid DeepSeek key; use `deepseek-local` for Ollama-only testing.
- Python 3.9 is the system default — always test syntax with `python3 -m py_compile` before committing Python files.
