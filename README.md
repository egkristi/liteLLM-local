# liteLLM-local

A local LiteLLM proxy that gives you a **single OpenAI-compatible endpoint** for all your AI providers — no markup, no middleman, direct provider pricing.

## Why

Running models through OpenRouter is convenient but expensive. With LiteLLM running locally, VS Code Copilot Chat (and any other tool) points to `http://localhost:4000` and your API keys go **direct to each provider** at their published rates.

Tested providers in this setup:
- [DeepSeek](https://platform.deepseek.com) — best for coding ($0.44/$0.87 per 1M tokens)
- [Anthropic](https://console.anthropic.com) — Claude models
- [Groq](https://console.groq.com) — fast inference
- [Mistral](https://console.mistral.ai) — strong European models, good price/quality
- [Moonshot / Kimi](https://platform.moonshot.cn)
- [Ollama](http://localhost:11434) — local models, free

---

## Prerequisites

- [uv](https://docs.astral.sh/uv/) (recommended Python package manager)
- [Ollama](https://ollama.com) installed and running (for local models)
- API keys for the providers you want to use

---

## Quick start

```bash
# 1. Install uv and LiteLLM
make install

# 2. Copy the env template and add your keys
cp .env.example .env
# edit .env with your API keys

# 3. Start the proxy
make start
```

The proxy will be available at `http://localhost:4000`.

---

## Configuration

Models, API keys, and settings are defined in [`config.yaml`](config.yaml).  
API keys live in `.env` (gitignored — never commit it).  
See [`.env.example`](.env.example) for the required variables.

To add custom models, follow [`docs/ADDING_MODELS.md`](docs/ADDING_MODELS.md).

---

## Daily commands

| Command | What it does |
|---|---|
| `make start` | Start the proxy (with prerequisite checks) |
| `make stop` | Stop the proxy |
| `make status` | Health check + list available models |
| `make usage` | Show recent usage / cost from logs |
| `make logs` | Tail the latest log file |
| `make install` | Install `uv` and `litellm` if missing |
| `./test.sh` | Send a smoke-test chat completion |
| `./webui.py` | Open the web dashboard (port 8080) |
| `./litellm-local webui` | Same, via the Python wrapper |

You can also run any script directly, e.g.:

```bash
PORT=4001 ./start.sh   # start on a custom port
WEBUI_PORT=8081 ./webui.py  # dashboard on a custom port
```

---

## VS Code Copilot Chat Setup

Copy the snippet from [`.vscode/settings.json`](.vscode/settings.json) into your user `settings.json`.  
It includes commented entries for every configured model — uncomment the one you want to use.

---

## Monitoring (optional)

A Prometheus + Grafana stack is included for metrics and dashboards.

```bash
docker compose -f docker-compose.monitoring.yml up -d
```

- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin / `admin` or set `GRAFANA_PASSWORD`)
- Pre-loaded dashboard: **LiteLLM Overview** (request rate, spend, latency, model breakdown)

---

## Docker (alternative to uv)

```bash
docker compose up -d
```

The container reads `./config.yaml` and `./.env` from the host.  
Logs are persisted to `./logs` via a volume mount.

---

## Auto-start on Mac (optional)

To have LiteLLM start automatically on login, create a launchd plist:

```bash
cat > ~/Library/LaunchAgents/com.litellm.local.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.litellm.local</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-c</string>
    <string>cd /path/to/liteLLM-local && source .env && uv tool run litellm --config config.yaml --port 4000</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.litellm.local.plist
```

---

## Cost Comparison

| Provider | Model | Input /1M | Output /1M |
|---|---|---|---|
| DeepSeek (direct) | deepseek-chat (V4 Pro) | $0.44 | $0.87 |
| Anthropic (direct) | claude-sonnet-4-6 | $3.00 | $15.00 |
| Groq (direct) | llama-3.3-70b | ~$0.59 | ~$0.79 |
| Mistral (direct) | mistral-large-latest | $2.00 | $6.00 |
| Mistral (direct) | codestral-latest | $0.30 | $0.90 |
| Ollama local | qwen2.5-coder:14b | free | free |
| OpenRouter | (same models) | +10–15% markup | +10–15% markup |

---

## Files

```
liteLLM-local/
├── AGENTS.md            # AI agent workflow instructions
├── CHANGELOG.md         # release history
├── ISSUES.md            # known issues & fixes
├── ROADMAP.md           # planned features
├── config.yaml          # model definitions
├── .env                 # API keys (gitignored)
├── .env.example         # template for .env
├── .gitignore
├── start.sh             # start the proxy (with checks)
├── stop.sh              # stop the proxy
├── status.sh            # health check & model list
├── usage.sh             # quick usage/cost from logs
├── test.sh              # smoke-test chat completion
├── webui.py             # zero-dependency web dashboard
├── Makefile             # common commands (make start, make status, ...)
├── litellm-local        # cross-platform Python wrapper
├── docker-compose.yml   # Docker alternative to uv
├── docker-compose.monitoring.yml  # Prometheus + Grafana stack
├── monitoring/
│   ├── prometheus.yml
│   └── grafana/
│       ├── dashboards/
│       └── datasources/
├── .vscode/
│   └── settings.json    # VS Code Copilot Chat snippet
├── docs/
│   └── ADDING_MODELS.md # how to add custom models
└── README.md
```