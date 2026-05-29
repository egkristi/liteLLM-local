# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project scaffold: `config.yaml`, `start.sh`, `.env.example`, `.gitignore`
- Added Moonshot / Kimi model (`kimi-latest`) to `config.yaml` and `KIMI_API_KEY` to `.env.example`
- Added `status.sh` for health checks and model listing
- Added `stop.sh` for clean proxy shutdown
- Added `usage.sh` for quick usage/cost inspection from logs
- Enhanced `start.sh` with prerequisite checks (`uv`, `litellm`), port conflict detection, and `PORT` override support
- Enabled LiteLLM spend tracking and persistent log file output in `config.yaml`
- Created `ISSUES.md`, `ROADMAP.md`, and `CHANGELOG.md`
- Added `Makefile` with `start`, `stop`, `status`, `usage`, `logs`, and `install` targets
- Added cross-platform Python wrapper `litellm-local`
- Added `.vscode/settings.json` snippet for VS Code Copilot Chat setup
- Added `docs/ADDING_MODELS.md` guide for extending model configuration
- Added `docker-compose.yml` and `.dockerignore` for Docker-based deployment
- Added automatic model fallback chain (`fallback-deepseek` → `claude-sonnet` → `groq-llama`)
- Fixed ISSUE-7: added `logs/` volume mount to `docker-compose.yml` for persistent container logs
- Fixed ISSUE-8: clarified Docker `PORT` behavior (host-only mapping)
- Fixed ISSUE-9: `Makefile` `logs` target now tails only the most recent log file
- Fixed ISSUE-10: `.vscode/settings.json` includes commented snippets for all configured models
- Added Prometheus/Grafana monitoring stack (`docker-compose.monitoring.yml`, `monitoring/`)
  - Prometheus scrapes LiteLLM metrics at `/metrics`
  - Grafana pre-loaded with LiteLLM Overview dashboard (request rate, spend, latency, model breakdown)
- Added zero-dependency web UI (`webui.py`) served on port 8080
  - Displays proxy health, available models, usage summary, and recent logs
  - No external dependencies — uses only Python standard library
- Fixed ISSUE-11: rewrote README with quick-start, commands table, monitoring, Docker, and updated file tree
- Fixed ISSUE-12: replaced `curl` subprocess in `webui.py` with `urllib.request`
- Fixed ISSUE-13: added `webui` subcommand to `litellm-local` wrapper
- Fixed ISSUE-14: added `test.sh` smoke-test script for quick proxy validation

