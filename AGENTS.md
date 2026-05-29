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
