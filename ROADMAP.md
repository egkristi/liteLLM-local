# Roadmap

## Now

- [x] Add CI workflow (GitHub Actions) to lint shell scripts and validate YAML
- [x] Add unit tests for `litellm-local` wrapper
- [x] Add support for multiple config profiles (e.g., `config.dev.yaml`, `config.prod.yaml`)
- [x] Add automatic config reload without restarting the proxy
- [x] Add a `litellm-local config` command to validate `config.yaml`
- [ ] Add `make validate` — checks all `.env` keys are set and all models in `config.yaml` are reachable before starting
- [ ] Add `make install-autostart` — generates and loads the correct launchd plist with the actual repo path (replaces manual plist editing)
- [ ] Add `make vscode-config` — regenerates `.vscode/settings.json` from `config.yaml` so the two never drift out of sync

## Next

- [ ] Add a TUI (terminal UI) alternative to the web dashboard
- [ ] Add request caching layer for repeated prompts
- [ ] Add rate-limiting per model / per provider
- [ ] Add support for AWS Bedrock and Google Vertex AI providers
- [ ] Per-user virtual keys with monthly spend caps — so family members each get a key with a budget limit (e.g. $5/month), preventing one heavy session from eating the shared budget
- [ ] Cost alerts via macOS notification (`osascript`) when monthly spend crosses a configurable threshold
- [ ] Export daily spend to `spend.csv` (model, tokens, cost) for analysis in Excel/Numbers
- [ ] Model aliases (`best-coding`, `best-chat`, `fast`) in `config.yaml` — VS Code config never needs to change when switching preferred models
- [ ] Model benchmarking script (`benchmark.sh`) — sends a standard set of coding prompts to each model and reports latency + cost
- [ ] `make rotate-key PROVIDER=deepseek` — prompts for new key, updates `.env`, restarts proxy
- [ ] `make audit` — checks `.env` against `.env.example`, warns about missing or placeholder keys
- [ ] Structured JSON logging (`json_logs: true`) to enable `jq`-based filtering and log tool ingestion
- [ ] Log rotation — keep last 7 days, compress older files

## Later

- [ ] Add a web UI for managing models (add/remove via UI)
- [ ] Add OpenTelemetry tracing integration
- [ ] Add support for embedding models (text-embedding-3, etc.)
- [ ] Grafana dashboard improvements: per-model cost panel, p95 latency per provider, error rate panel, daily budget burn gauge
- [ ] Shell completions (bash/zsh) for `./litellm-local` — model names and flags tab-complete
- [ ] `docs/PROVIDERS.md` — reference for all providers: where to get a key, LiteLLM model string, current pricing
- [ ] `docs/TROUBLESHOOTING.md` — document known issues: DeepSeek `reasoning_content` fix, Ollama cloud vs local, VS Code 402 errors, rate limit handling
- [ ] `docs/FAMILY_SETUP.md` — guide for adding a family member: virtual key with budget cap, VS Code setup, which models to use for what
- [ ] Uptime monitor — cron ping every 5 minutes, macOS notification if proxy is unexpectedly down

## Done

- [x] Fix all open issues in `ISSUES.md`
- [x] Add `status.sh` script for quick health checks
- [x] Add `stop.sh` script to cleanly kill the proxy
- [x] Improve `start.sh` with prerequisite checks and port conflict handling
- [x] Add a `Makefile` with common commands
- [x] Add `litellm-local` Python wrapper script
- [x] Document how to add custom models
- [x] Add VS Code `settings.json` snippet
- [x] Add Docker Compose setup
- [x] Add automatic model fallback
- [x] Add Prometheus/Grafana monitoring stack
- [x] Add web UI (`webui.py`)
- [x] Add `test.sh` smoke-test script
- [x] Rewrite README with quick-start and commands table
