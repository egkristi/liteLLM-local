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
