# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **VS Code settings format** — switched from flat `openai`-vendor entries to a single `customendpoint` entry with a `models` array. Each model now includes `toolCalling`, `vision`, `maxInputTokens`, and `maxOutputTokens` capabilities. Aliases inherit their target model's capabilities.
- **Generator script** (`scripts/generate_vscode_settings.py`) — completely rewritten `generate_settings()` and `write_settings()` to produce the new `customendpoint` format. Added `_model_capabilities()` and `_friendly_name()` helper functions.

### Added
- VS Code settings generator (`scripts/generate_vscode_settings.py`) now parses `model_alias` from `config.yaml` and includes all 6 aliases as active entries in `.vscode/settings.json`, alongside the first model
- Request caching layer (`cache-proxy.py`) — SQLite-backed caching proxy that sits between clients and LiteLLM. Caches identical chat completion requests to avoid repeated API calls. Supports `--port`, `--backend`, `--ttl`, `--clear`, `--stats`. Enabled via `LITELLM_CACHE=true` env var or `--cache` flag on `litellm-local start`
- Makefile targets: `cache-stats`, `cache-clear`
- `cache-proxy.py` added to CI Python syntax check
- `litellm-local start` now supports `--cache` and `--cache-port` flags
- Model benchmarking script (`benchmark.sh`) — sends standard coding prompts to each model, reports latency and estimated cost. Supports `--models`, `--prompts`, `--local`, `--all`, `--output`, `--json`. Results saved to `logs/benchmark-*.csv`
- Makefile target: `benchmark` (with `MODELS`, `PROMPTS`, `LOCAL`, `ALL`, `OUTPUT` variables)
- `benchmark.sh` added to CI shellcheck
- `docs/PROVIDERS.md` — reference for all providers: where to get a key, LiteLLM model string, current pricing
- `docs/TROUBLESHOOTING.md` — document known issues: DeepSeek `reasoning_content` fix, Ollama cloud vs local, VS Code 402 errors, rate limit handling
- `docs/FAMILY_SETUP.md` — guide for adding a family member: virtual key with budget cap, VS Code setup, which models to use for what
- Shell completions (`completions/litellm-local`) — bash and zsh tab-completion for `litellm-local` commands and flags
- Uptime monitor (`uptime-monitor.sh`) — checks proxy every N minutes, sends macOS notification if down, logs to `logs/uptime.csv`. Supports `--daemon`, `--install`, `--uninstall`
- Cost alerts (`cost-alert.sh`) — checks estimated monthly spend from logs, sends macOS notification if over threshold. Supports `--threshold`, `--install`, `--uninstall`
- Spend CSV export (`export-spend.sh`) — exports daily spend breakdown by date or by model. Supports `--days`, `--model`, `--output`
- Makefile targets: `uptime`, `uptime-install`, `uptime-uninstall`, `cost-alert`, `cost-alert-install`, `cost-alert-uninstall`, `export-spend`
- `make audit` target (`audit.sh`) — checks `.env` against `.env.example` for missing keys, placeholder values, and extra keys
- `make rotate-key` target (`rotate-key.sh`) — prompts for a new API key, updates `.env`, and restarts the proxy
- Structured JSON logging — `--json` flag on `litellm-local start` / `LITELLM_JSON_LOGS=true` env var enables LiteLLM's JSON log output
- Log rotation in `start.sh` — compresses logs older than 7 days with gzip, deletes compressed logs older than 30 days
- Model aliases in `config.yaml` and `config.prod.yaml` — `best-coding`, `best-chat`, `fast`, `cheap`, `local`, `embedding` aliases so VS Code config never needs to change when switching preferred models
- `scripts/generate_vscode_settings.py` added to CI Python syntax check
- `audit.sh` and `rotate-key.sh` added to CI shellcheck
- 2 new unit tests for `--json` flag (20 total, all passing)
- GitHub Actions CI workflow (`.github/workflows/ci.yml`) — lints shell scripts with shellcheck, validates YAML with yamllint, checks Python syntax, verifies config env var consistency
- `.yamllint` config matching project 2-space YAML style
- Unit tests for `litellm-local` wrapper (`tests/test_litellm_local.py`) — 18 tests covering arg parsing, command dispatch, PORT env var, and subprocess calls
- Multi-config profile support — `LITELLM_CONFIG` env var and `--config` flag to select different config files (e.g., `config.prod.yaml`)
- Production config profile (`config.prod.yaml`) with master key and rate limiting settings
- Automatic config reload — `--watch` flag / `LITELLM_RELOAD=true` enables LiteLLM's built-in `--reload` for hot-reloading config changes
- `litellm-local config` command — validates config file structure, checks for duplicate models, missing fields, and env var references
- `make validate` target (`validate.sh`) — checks `.env` keys are set, config is valid, and proxy is reachable
- `make install-autostart` target (`install-autostart.sh`) — generates and loads a launchd plist for auto-starting the proxy on login
- `make vscode-config` target (`scripts/generate_vscode_settings.py`) — regenerates `.vscode/settings.json` from `config.yaml` so they never drift out of sync
- `LITELLM_MASTER_KEY` to `.env.example` for production config support
- 14 new Ollama cloud models exposed through LiteLLM proxy (deepseek-v4-pro-cloud, deepseek-v4-flash-cloud, gemma4-31b-cloud, gemini-3-flash-cloud, glm-5.1-cloud, kimi-k2.5-cloud, kimi-k2.6-cloud, minimax-m2.7-cloud, ministral-3-3b-cloud, ministral-3-8b-cloud, ministral-3-14b-cloud, mistral-large-3-675b-cloud, qwen3.5-397b-cloud, qwen3-vl-235b-cloud, qwen3-vl-235b-instruct-cloud)
- `nomic-embed-text` model for embeddings support
- Updated `.vscode/settings.json` with VS Code Copilot Chat snippets for all new Ollama cloud models

### Changed
- `litellm-local` wrapper refactored: `build_parser()` and `HANDLERS` dict exposed as module-level for testability
- `start.sh` now uses `$CONFIG` variable (from `LITELLM_CONFIG` env var) instead of hardcoded `config.yaml`
- `Makefile` now supports `CONFIG` variable for profile selection

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
- Fixed ISSUE-17: `start.sh` now exports `.env` variables to child processes using `set -a` / `set +a`
  - Root cause of ISSUE-15: cloud providers now authenticate correctly
  - Verified: DeepSeek responds "Hello! How can I help you today?"
- Fixed broken GitHub link in README: `.vscode/settings.json` was gitignored
  - Removed `.vscode/` from `.gitignore` so shared Copilot Chat snippets are tracked
  - File is now accessible at https://github.com/egkristi/liteLLM-local/blob/main/.vscode/settings.json

