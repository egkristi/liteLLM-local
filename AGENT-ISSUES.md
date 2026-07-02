# Agent Issues — liteLLM-local

This document tracks issues discovered by AI coding agents working on this project.
Items are ordered by severity/impact.

---

## Resolved

### C-1: `cache-proxy.py` `do_GET()` reads body on GET requests — always hangs or crashes ✅

**Status:** Fixed — `do_GET()` now passes `None` as body instead of reading from `self.rfile`. Also fixed a pre-existing `global BACKEND_PORT` declaration ordering bug that caused a `SyntaxError`.

### C-2: `cache-proxy.py` `do_GET()` forwards empty body to backend — breaks `/health` and `/models` ✅

**Status:** Fixed — `_proxy_request()` accepts `Optional[bytes]` and passes `None` for GET/HEAD/DELETE requests (no body sent).

### H-1: `benchmark.sh` — `local` keyword used outside function body in `get_models()` ✅

**Status:** Fixed — moved `local name` declaration outside the `while read` loop in `get_models()`.

### H-2: `export-spend.sh` — `local` keyword used outside functions, `declare -A` in pipeline subshell ✅

**Status:** Fixed — moved `local` declarations outside `while read` loops in both the per-model and daily summary sections.

### H-3: `stop.sh` — missing `set -e`, silent failure on `kill` ✅

**Status:** Fixed — added `set -e` to the shebang line.

### H-4: `validate.sh` health check uses `/models` instead of `/v1/models` ✅

**Status:** Fixed — changed endpoint from `/models` to `/v1/models`.

### H-5: `usage.sh` — no `jq`-based JSON log parsing, inaccurate cost/token extraction ✅

**Status:** Fixed — added `jq`-based JSON log parsing with graceful fallback to grep for non-JSON logs.

### M-1: `config.yaml` missing `model_info` blocks — no cost tracking data ✅

**Status:** Fixed — added `model_info` blocks (with `mode`, `max_tokens`, `input_cost_per_token`, `output_cost_per_token`) to every model entry in `config.yaml`, including aliases and Ollama models (zero cost).

### M-2: `config.prod.yaml` has no model aliases — `best-coding`, `best-chat`, `fast` missing ✅

**Status:** Fixed — added all five alias entries (`best-coding`, `best-chat`, `fast`, `cheap`, `local`) with `model_info` blocks to `config.prod.yaml`.

---

## Unfixable (external limitations)

### H-6: VS Code Copilot "Response too long" error — agent output exceeds ~60KB limit

**Status:** Cannot be fixed in this project. This is a VS Code Copilot Chat extension limitation. Mitigation through agent workflow discipline (see workarounds below).

**Workarounds:**
1. Split large work across multiple turns
2. Use `grep_search` and targeted `read_file` ranges
3. Send a response after reading/planning before starting implementation
4. Use the `runSubagent` tool for complex multi-step tasks
5. Avoid `create_file` calls with >300 lines

---

### M-3: `config.prod.yaml` missing Ollama cloud models — no `*-cloud` entries

**File:** `config.prod.yaml`

**Problem:** The dev `config.yaml` has 20+ Ollama cloud models (`deepseek-v4-pro-cloud`, `gemma4-31b-cloud`, `kimi-k2.5-cloud`, etc.). The production `config.prod.yaml` only has 2 local Ollama models (`deepseek-local`, `qwen2.5-coder`). Users who deploy to production lose access to all free cloud models.

**Impact:** Production deployment has significantly fewer model options than development.

**Fix:** Add the Ollama cloud model entries to `config.prod.yaml`, or document that `config.yaml` should be used for production if cloud models are needed.

---

### M-4: `Makefile` missing `webui` target

**File:** `Makefile`

**Problem:** There's a `webui.py` dashboard, but no `make webui` target to start it. Users must remember the path and command manually.

**Impact:** Poor discoverability of the web dashboard.

**Fix:** Add `make webui` target that runs `python3 webui.py`. The ROADMAP.md already lists this as a "Now" item.

---

### M-5: `README.md` file tree is outdated — missing scripts and docs

**File:** `README.md`

**Problem:** The README's file tree section doesn't list many of the scripts and docs that have been added: `audit.sh`, `benchmark.sh`, `cache-proxy.py`, `cost-alert.sh`, `export-spend.sh`, `rotate-key.sh`, `uptime-monitor.sh`, `validate.sh`, `docs/PROVIDERS.md`, `docs/TROUBLESHOOTING.md`, `docs/FAMILY_SETUP.md`, `docs/ADDING_MODELS.md`, `AGENTS.md`, `AGENT-ISSUES.md`.

**Impact:** Users don't know what tools are available.

**Fix:** Update the README file tree to include all files. The ROADMAP.md already lists this as a "Now" item.

---

### M-6: `README.md` autostart section doesn't reference `make install-autostart`

**File:** `README.md`

**Problem:** The README has an autostart/launchd section but doesn't mention the `make install-autostart` convenience target. Users may manually create plist files instead of using the automated tool.

**Impact:** Users do extra manual work and may make mistakes.

**Fix:** Update the autostart section to reference `make install-autostart`. The ROADMAP.md already lists this as a "Now" item.

---

### M-7: `.env.example` missing `OLLAMA_API_KEY` and `NVIDIA_API_KEY`

**File:** `.env.example`

**Problem:** The config references Ollama models (both local and cloud) and potentially NVIDIA models, but `.env.example` doesn't include `OLLAMA_API_KEY` or `NVIDIA_API_KEY` entries. Users who need Ollama cloud or NVIDIA models won't know what env vars to set.

**Impact:** Poor discoverability of required configuration for Ollama cloud and NVIDIA models.

**Fix:** Add `OLLAMA_API_KEY=...` and `NVIDIA_API_KEY=...` to `.env.example`. The ROADMAP.md already lists this as a "Now" item.

---

### M-8: `config.yaml` missing `general_settings` section for discoverability

**File:** `config.yaml`

**Problem:** The dev `config.yaml` has no `general_settings` section (commented or otherwise). Users who want to configure master keys, rate limiting, or proxy settings don't know what options are available without reading LiteLLM docs.

**Impact:** Poor discoverability of LiteLLM configuration options.

**Fix:** Add a commented `general_settings` section to `config.yaml` with common options. The ROADMAP.md already lists this as a "Now" item.

---

### M-9: `docker-compose.yml` missing `LITELLM_MASTER_KEY` and `--reload` support

**File:** `docker-compose.yml`

**Problem:** The Docker Compose setup doesn't pass `LITELLM_MASTER_KEY` environment variable to the container, and doesn't support `--reload` for config file watching. Production deployments need both.

**Impact:** Docker deployment lacks master key auth and hot-reload capability.

**Fix:** Add `LITELLM_MASTER_KEY` env var passthrough and `--reload` flag support to `docker-compose.yml`. The ROADMAP.md already lists this as a "Now" item.

---

### M-10: `webui.py` dashboard has no auto-refresh

**File:** `webui.py`

**Problem:** The web dashboard is static HTML — users must manually click "Refresh" to see updated data. For a monitoring dashboard, auto-refresh is expected.

**Impact:** Poor UX for monitoring use cases.

**Fix:** Add `<meta http-equiv="refresh" content="30">` or JavaScript-based auto-refresh. The ROADMAP.md already lists this as a "Now" item.

---

### M-11: `cache-proxy.py` has no cache eviction background thread

**File:** `cache-proxy.py`

**Problem:** Expired cache entries are only deleted when they are accessed (lazy eviction). If many entries expire without being accessed, they accumulate in the SQLite database indefinitely, wasting disk space.

**Impact:** Cache database grows unbounded over time.

**Fix:** Add a background thread that periodically purges expired entries. The ROADMAP.md already lists this as a "Now" item.

---

## Low

### L-1: `webui.py` has duplicate import

**File:** `webui.py`, line 18

```python
from typing import Optional, Union
```

**Problem:** This import is at module level after the `SCRIPT_DIR` and port definitions, separated from the other imports at the top. It's also unused — `Optional` and `Union` are never referenced in the code.

**Impact:** Dead code, minor style issue.

**Fix:** Remove the unused import.

---

### L-2: `cache-proxy.py` `do_GET()` reads `Content-Length` for no reason

**File:** `cache-proxy.py`, line 141

```python
body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
```

**Problem:** GET requests should not have a body. Reading `Content-Length` on a GET is semantically incorrect. While it works with `Content-Length: 0`, it's technically wrong per HTTP spec.

**Impact:** Minor — works in practice but is incorrect HTTP semantics.

**Fix:** `do_GET()` should not read a body at all. Set `body = b""` unconditionally.

---

### L-3: `export-spend.sh` uses `exec > "$OUTPUT"` inside a function-like block

**File:** `export-spend.sh`, lines ~60 and ~100

```bash
if [ -n "$OUTPUT" ]; then
    exec > "$OUTPUT"
fi
```

**Problem:** `exec > "$OUTPUT"` redirects all subsequent stdout to the file for the **entire script**, not just the current block. If both `--model` and `--output` are used, the "✅ Spend data exported to:" message at the end is also redirected to the file instead of printed to the terminal.

**Impact:** The success message is silently written to the CSV file instead of shown to the user.

**Fix:** Use `>` redirect on individual `echo` commands instead of `exec >`.

---

### L-4: `start.sh` cache proxy mode doesn't clean up child process on exit

**File:** `start.sh`, lines ~80-85

```bash
python3 "$SCRIPT_DIR/cache-proxy.py" --port "$CACHE_PORT" --backend "$LITELLM_PORT" &
CACHE_PID=$!
```

**Problem:** When the LiteLLM proxy is stopped (e.g., Ctrl+C), the cache proxy child process is orphaned. It continues running on the cache port, blocking future restarts.

**Impact:** After stopping and restarting, the cache proxy may fail to bind because the old process is still running.

**Fix:** Add a `trap` to kill `$CACHE_PID` on exit, or use `exec` to replace the shell with the cache proxy.

---

### L-5: `benchmark.sh` has duplicate pricing entries

**File:** `benchmark.sh`, lines ~50-70

**Problem:** The `MODEL_PRICING` associative array has entries for models that don't exist in `config.yaml` (e.g., `ministral-3-3b-cloud`, `mistral-large-3-675b-cloud`), while missing entries for models that do exist (e.g., `best-coding`, `best-chat`, `fast`, `cheap`, `local`, `embedding`, `fallback-deepseek`).

**Impact:** Benchmarking with `--all` may produce incomplete or incorrect cost estimates.

**Fix:** Sync the pricing table with the actual model list in `config.yaml`.

---

## VS Code Copilot "Response too long" Error

This error is **not a bug in liteLLM-local** — it's a VS Code Copilot client-side limit:

```
Client Request Id: 2c8f43eb-a2e4-4b37-a9a6-5ad3fdec0845
Reason: Response too long.
```

**Root cause:** The VS Code Copilot extension enforces a maximum response size (~60KB). When an AI agent accumulates too much context (reading many files, planning + implementing in one turn), the response exceeds this limit.

**Where it manifests:** When AI agents working on this project read too many files at once or try to plan and implement in a single turn.

**Mitigations (for AI agents):**
- Read files in targeted ranges, not entire files
- Split planning and implementation across separate turns
- Create files in sections under 300 lines each
- Use subagents for research/exploration to keep main context clean

**Nothing to fix in liteLLM-local code.** This is a VS Code/Copilot configuration issue.
