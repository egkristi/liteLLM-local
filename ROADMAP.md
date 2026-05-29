# Roadmap

## Now

- [ ] Add CI workflow (GitHub Actions) to lint shell scripts and validate YAML
- [ ] Add unit tests for `litellm-local` wrapper
- [ ] Add support for multiple config profiles (e.g., `config.dev.yaml`, `config.prod.yaml`)
- [ ] Add automatic config reload without restarting the proxy
- [ ] Add a `litellm-local config` command to validate `config.yaml`

## Next

- [ ] Add a TUI (terminal UI) alternative to the web dashboard
- [ ] Add request caching layer for repeated prompts
- [ ] Add rate-limiting per model / per provider
- [ ] Add support for AWS Bedrock and Google Vertex AI providers

## Later

- [ ] Add a web UI for managing models (add/remove via UI)
- [ ] Add OpenTelemetry tracing integration
- [ ] Add support for embedding models (text-embedding-3, etc.)

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
