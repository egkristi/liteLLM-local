# Issues

## Open

*None currently.*

## Closed

### ISSUE-1: Missing Moonshot/Kimi provider configuration ✅
Added `kimi-latest` model to `config.yaml` and `KIMI_API_KEY` to `.env.example`.

### ISSUE-2: `start.sh` does not validate prerequisites ✅
Added checks for `uv` and `litellm` installation with helpful error messages.

### ISSUE-3: `start.sh` does not handle port conflicts ✅
Added port availability check and `PORT` environment variable override.

### ISSUE-4: No health-check / status script ✅
Created `status.sh` that pings the proxy and lists available models.

### ISSUE-5: No log rotation or structured logging ✅
Configured `litellm_settings.log_file` and `logs/` directory creation in `start.sh`.

### ISSUE-6: No usage / cost tracking ✅
Enabled `spend_logs: true` in `config.yaml` and created `usage.sh` for quick log-based usage inspection.

### ISSUE-7: `docker-compose.yml` does not persist logs ✅
Added `./logs:/app/logs` volume mount to `docker-compose.yml`.

### ISSUE-8: `docker-compose.yml` port mapping inconsistency ✅
Documented that `PORT` only affects host mapping; container port remains 4000. Verified `healthcheck` uses correct internal port.

### ISSUE-9: `Makefile` `logs` target fails with multiple log files ✅
Changed `tail -f logs/*.log` to `ls -t logs/*.log | head -n 1` so only the most recent file is tailed.

### ISSUE-10: `.vscode/settings.json` only includes a single model ✅
Added commented snippets for all configured models so users can quickly switch by uncommenting.

### ISSUE-11: README is outdated and incomplete ✅
Rewrote README with quick-start, commands table, monitoring, Docker, and updated file tree.

### ISSUE-12: `webui.py` relies on `curl` subprocess ✅
Replaced `subprocess` + `curl` with Python's built-in `urllib.request` for cross-platform compatibility.

### ISSUE-13: `litellm-local` wrapper missing `webui` command ✅
Added `webui` subcommand to `litellm-local`.

### ISSUE-14: No quick validation / smoke-test script ✅
Added `test.sh` that sends a small chat-completion request and reports success/failure.

### ISSUE-15: Cloud provider API keys return 401 Unauthorized ✅
**Root cause was ISSUE-17** — `start.sh` was not exporting `.env` variables. Once fixed, all cloud providers authenticate correctly.

### ISSUE-16: `start.sh` env var loading may fail with special characters in `.env` ✅
Replaced Unicode em-dash with ASCII `--` in `.env` and `.env.example` comments.

### ISSUE-17: `start.sh` does not export `.env` variables to child process ✅
Added `set -a` before `source .env` and `set +a` after to auto-export all variables to child processes.

### ISSUE-1: Missing Moonshot/Kimi provider configuration ✅
Added `kimi-latest` model to `config.yaml` and `KIMI_API_KEY` to `.env.example`.

### ISSUE-2: `start.sh` does not validate prerequisites ✅
Added checks for `uv` and `litellm` installation with helpful error messages.

### ISSUE-3: `start.sh` does not handle port conflicts ✅
Added port availability check and `PORT` environment variable override.

### ISSUE-4: No health-check / status script ✅
Created `status.sh` that pings the proxy and lists available models.

### ISSUE-5: No log rotation or structured logging ✅
Configured `litellm_settings.log_file` and `logs/` directory creation in `start.sh`.

### ISSUE-6: No usage / cost tracking ✅
Enabled `spend_logs: true` in `config.yaml` and created `usage.sh` for quick log-based usage inspection.

### ISSUE-7: `docker-compose.yml` does not persist logs ✅
Added `./logs:/app/logs` volume mount to `docker-compose.yml`.

### ISSUE-8: `docker-compose.yml` port mapping inconsistency ✅
Documented that `PORT` only affects host mapping; container port remains 4000. Verified `healthcheck` uses correct internal port.

### ISSUE-9: `Makefile` `logs` target fails with multiple log files ✅
Changed `tail -f logs/*.log` to `ls -t logs/*.log | head -n 1` so only the most recent file is tailed.

### ISSUE-10: `.vscode/settings.json` only includes a single model ✅
Added commented snippets for all configured models so users can quickly switch by uncommenting.

### ISSUE-11: README is outdated and incomplete ✅
Rewrote README with quick-start, daily commands table, monitoring section, Docker section, and updated file tree.

### ISSUE-12: `webui.py` relies on `curl` subprocess ✅
Replaced `subprocess` + `curl` with Python's built-in `urllib.request` for cross-platform compatibility.

### ISSUE-13: `litellm-local` wrapper missing `webui` command ✅
Added `webui` subcommand to `litellm-local`.

### ISSUE-14: No quick validation / smoke-test script ✅
Added `test.sh` that sends a small chat-completion request and reports success/failure.

### ISSUE-1: Missing Moonshot/Kimi provider configuration ✅
Added `kimi-latest` model to `config.yaml` and `KIMI_API_KEY` to `.env.example`.

### ISSUE-2: `start.sh` does not validate prerequisites ✅
Added checks for `uv` and `litellm` installation with helpful error messages.

### ISSUE-3: `start.sh` does not handle port conflicts ✅
Added port availability check and `PORT` environment variable override.

### ISSUE-4: No health-check / status script ✅
Created `status.sh` that pings the proxy and lists available models.

### ISSUE-5: No log rotation or structured logging ✅
Configured `litellm_settings.log_file` and `logs/` directory creation in `start.sh`.

### ISSUE-6: No usage / cost tracking ✅
Enabled `spend_logs: true` in `config.yaml` and created `usage.sh` for quick log-based usage inspection.

### ISSUE-7: `docker-compose.yml` does not persist logs ✅
Added `./logs:/app/logs` volume mount to `docker-compose.yml`.

### ISSUE-8: `docker-compose.yml` port mapping inconsistency ✅
Documented that `PORT` only affects host mapping; container port remains 4000. Verified `healthcheck` uses correct internal port.

### ISSUE-9: `Makefile` `logs` target fails with multiple log files ✅
Changed `tail -f logs/*.log` to `ls -t logs/*.log | head -n 1` so only the most recent file is tailed.

### ISSUE-10: `.vscode/settings.json` only includes a single model ✅
Added commented snippets for all configured models so users can quickly switch by uncommenting.
