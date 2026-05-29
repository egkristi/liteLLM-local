# Roadmap

## Now

- [x] Fix all open issues in `ISSUES.md`
- [x] Add `status.sh` script for quick health checks
- [x] Add `stop.sh` script to cleanly kill the proxy
- [x] Improve `start.sh` with prerequisite checks and port conflict handling
- [x] Add a `Makefile` with common commands (`make start`, `make status`, `make logs`)
- [x] Add a simple Python wrapper script (`litellm-local`) for cross-platform compatibility
- [x] Document how to add custom models without editing `config.yaml` directly
- [x] Add a VS Code `settings.json` snippet file for easy Copilot Chat setup

## Next

- [x] Add a `Makefile` with common commands (`make start`, `make status`, `make logs`)
- [x] Add a simple Python wrapper script (`litellm-local`) for cross-platform compatibility
- [x] Document how to add custom models without editing `config.yaml` directly
- [x] Add a VS Code `settings.json` snippet file for easy Copilot Chat setup
- [x] Add Docker Compose setup as an alternative to `uv`
- [x] Add automatic model fallback (e.g., DeepSeek → Claude if rate-limited)
- [x] Add Prometheus/Grafana metrics export for usage monitoring
- [ ] Add a web UI for viewing logs, usage, and managing models

## Later

- [ ] Add a web UI for viewing logs, usage, and managing models

## Done

*None yet.*
