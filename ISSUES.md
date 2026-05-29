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
