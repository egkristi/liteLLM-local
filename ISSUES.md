# Issues

## Open

*None currently.*

## Log Audit Findings

A comprehensive audit of all 26 log files (`logs/`) was conducted on 2026-07-28. Here are the findings:

| Error Pattern | Frequency | Severity | Status |
|---|---|---|---|
| **Lone leading surrogate in JSON hex escape** (DeepSeek API rejects `\uDxxx` without matching `\uDcxx-Dfxx`) | ~40+ across 4+ log files | 🔴 High — blocks real user requests to best-coding→DeepSeek | **FIXED** — see `sanitize-proxy.py` (ISSUE-21) |
| **DeepSeek requires `reasoning_content` to be passed back** in thinking mode | 4 occurrences across 3 log files | 🟡 Medium — affects thinking mode queries | Mitigated by `drop_params: true` in `config.yaml` (strips unsupported params) |
| **Anthropic "credit balance is too low"** | ~12 in 20260531 log | 🟡 Medium — old, likely resolved | Needs Anthropic billing top-up if recurring |
| **Ollama model 'qwen2.5-coder' not found** | 4 in 20260531 log | 🟢 Low — local model not pulled | Run `ollama pull qwen2.5-coder` |
| **Guardrail registry `|` syntax errors** (Python 3.12 incomp.) | 58 in 20260531 log | 🟢 Low — no guardrails configured | Ignore |
| **No connected db / No api key passed in** | 4 in 20260706 log | 🟢 Low — transient startup/unauth requests | Ignore |
| **ModuleNotFoundError** | 2 in 20260706 log | 🟢 Low — transient startup issue | Ignore |
| **Cost map warnings** (model not in built-in cost map) | Frequent | 🟢 Cosmetic | Harmless |

Key conclusions:
1. **The lone surrogate error is the only actively blocking issue.** It affects every request from VS Code Copilot that includes certain emoji or special characters — DeepSeek enforces strict RFC 8259 JSON parsing while VS Code sends surrogates from the ISF text buffer.
2. **All other errors are either old, cosmetic, or resolved.** No other actively blocking issues found.
3. **Logs are clean since the proxy restart after recent config changes.**

## Closed

### ISSUE-20: `model_alias_map` in `config.yaml` is not a valid LiteLLM config key — aliases like `best-coding` are rejected by the proxy ✅
`model_alias_map` is not a recognized LiteLLM configuration key. The proxy ignores it entirely, so any client sending `model=best-coding` gets a 400 error. Fixed by registering aliases as proper `model_list` entries that point to the same underlying models.

### ISSUE-19: `install-autostart.sh` plist doesn't source `.env` — proxy started by launchd has no API keys ✅
Fixed by reading `.env` file and injecting each variable into the launchd plist's `EnvironmentVariables` dict.

### ISSUE-18: `config.prod.yaml` references `LITELLM_MASTER_KEY` but `.env.example` doesn't have it ✅
Added `LITELLM_MASTER_KEY` to `.env.example`. Updated CI workflow to check all config files (not just `config.yaml`) for env var consistency.

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
**Note:** `spend_logs: true` logs spend to the JSON log file — no PostgreSQL database needed. The earlier comment "requires PostgreSQL" was misleading; only the virtual keys API (`/key/generate`, `/key/info`) requires PostgreSQL + `DATABASE_URL` + `LITELLM_MASTER_KEY`. File-based spend tracking works standalone.

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

### ISSUE-21: DeepSeek rejects lone leading surrogates in JSON hex escapes from VS Code Copilot ✅
**Problem:** VS Code Copilot sends chat messages containing lone leading surrogate hex escapes (e.g., `\uD800` without a matching `\uDC00-\uDFFF` trailing surrogate). DeepSeek's API enforces strict RFC 8259 compliance — lone surrogates are not valid JSON — and returns a 400 error: `"messages[N].content: lone leading surrogate in hex escape"`. This blocks every request from VS Code Copilot using the `best-coding` model group when messages contain certain emoji, special characters, or ISF text-buffer artifacts.

**Solution:** Created `sanitize-proxy.py` — a lightweight Python proxy middleware that sits between clients and LiteLLM. It intercepts request bodies and uses regex on raw bytes to detect and replace lone leading surrogates (`\uD800-\uDBFF` not followed by `\uDC00-\uDFFF`) with U+FFFD (replacement character) before forwarding to LiteLLM. Valid surrogate pairs (e.g., emoji) pass through unmodified.

**Usage:** Set `LITELLM_SANITIZE=true` before running `start.sh`. The sanitize proxy starts on port 4002 (configurable via `LITELLM_SANITIZE_PORT`). Point clients (e.g., VS Code `litellm-local.baseUrl`) to `http://localhost:4002` instead of `:4000`.

**Verified:** All 10 self-tests pass — including lone surrogates at start/end, valid surrogate pairs (unchanged), emoji pairs, multiple surrogates, trailing surrogates, and clean passthrough. Run `python3 sanitize-proxy.py --test` to verify.
