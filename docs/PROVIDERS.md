# Provider Reference

This document lists all AI providers available through the LiteLLM proxy,
where to get API keys, the LiteLLM model string format, and current pricing.

## Cloud Providers

### DeepSeek

| Field | Value |
|---|---|
| **Website** | https://platform.deepseek.com/ |
| **API Key** | `DEEPSEEK_API_KEY` in `.env` |
| **Sign up** | https://platform.deepseek.com/sign_up |
| **Pricing** | ~$0.14/M input tokens, ~$0.28/M output tokens (DeepSeek V4) |
| **Models** | `deepseek/deepseek-chat` |

**Usage in config.yaml:**
```yaml
- model_name: deepseek-v4-pro
  litellm_params:
    model: deepseek/deepseek-chat
    api_key: os.environ/DEEPSEEK_API_KEY
```

---

### Anthropic (Claude)

| Field | Value |
|---|---|
| **Website** | https://console.anthropic.com/ |
| **API Key** | `ANTHROPIC_API_KEY` in `.env` (starts with `sk-ant-`) |
| **Sign up** | https://console.anthropic.com/login |
| **Pricing** | ~$3/M input tokens, ~$15/M output tokens (Claude Sonnet 4) |
| **Models** | `anthropic/claude-sonnet-4-6`, `anthropic/claude-opus-4-6` |

**Usage in config.yaml:**
```yaml
- model_name: claude-sonnet
  litellm_params:
    model: anthropic/claude-sonnet-4-6
    api_key: os.environ/ANTHROPIC_API_KEY
```

---

### Groq

| Field | Value |
|---|---|
| **Website** | https://console.groq.com/ |
| **API Key** | `GROQ_API_KEY` in `.env` (starts with `gsk_`) |
| **Sign up** | https://console.groq.com/login |
| **Pricing** | Free tier available (rate-limited) |
| **Models** | `groq/llama-3.3-70b-versatile` |

**Usage in config.yaml:**
```yaml
- model_name: groq-llama
  litellm_params:
    model: groq/llama-3.3-70b-versatile
    api_key: os.environ/GROQ_API_KEY
```

---

### Mistral AI

| Field | Value |
|---|---|
| **Website** | https://console.mistral.ai/ |
| **API Key** | `MISTRAL_API_KEY` in `.env` |
| **Sign up** | https://console.mistral.ai/signup |
| **Pricing** | ~$2/M input tokens, ~$6/M output tokens (Mistral Large) |
| **Models** | `mistral/mistral-large-latest`, `mistral/codestral-latest` |

**Usage in config.yaml:**
```yaml
- model_name: mistral-large
  litellm_params:
    model: mistral/mistral-large-latest
    api_key: os.environ/MISTRAL_API_KEY
```

---

### Moonshot / Kimi

| Field | Value |
|---|---|
| **Website** | https://platform.moonshot.cn/ |
| **API Key** | `KIMI_API_KEY` in `.env` (starts with `sk-`) |
| **Sign up** | https://platform.moonshot.cn/console |
| **Pricing** | ~¥0.6/M input tokens, ~¥2/M output tokens |
| **Models** | `moonshot/moonshot-v1-128k` |

**Usage in config.yaml:**
```yaml
- model_name: kimi-latest
  litellm_params:
    model: moonshot/moonshot-v1-128k
    api_key: os.environ/KIMI_API_KEY
```

---

## Local Models (Ollama)

### Ollama — Local

| Field | Value |
|---|---|
| **Website** | https://ollama.com/ |
| **Install** | `brew install ollama` |
| **API Key** | None (runs locally) |
| **Pricing** | Free (uses your own hardware) |
| **Requirements** | Ollama must be running (`ollama serve`) |

**Usage in config.yaml:**
```yaml
- model_name: deepseek-local
  litellm_params:
    model: ollama/deepseek-v4-pro:cloud
    api_base: http://localhost:11434
```

### Ollama — Cloud

| Field | Value |
|---|---|
| **Website** | https://ollama.com/cloud |
| **API Key** | None (free tier available) |
| **Pricing** | Free tier (rate-limited), paid tiers available |
| **Requirements** | Ollama must be running (`ollama serve`) |

**Available cloud models:**
- `deepseek-v4-pro:cloud`
- `deepseek-v4-flash:cloud`
- `gemma4:31b-cloud`
- `gemini-3-flash-preview:cloud`
- `glm-5.1:cloud`
- `kimi-k2.5:cloud`
- `kimi-k2.6:cloud`
- `minimax-m2.7:cloud`
- `ministral-3:3b-cloud`, `:8b-cloud`, `:14b-cloud`
- `mistral-large-3:675b-cloud`
- `qwen3.5:397b-cloud`
- `qwen3-vl:235b-cloud`, `:235b-instruct-cloud`

---

## Adding a New Provider

See [ADDING_MODELS.md](ADDING_MODELS.md) for step-by-step instructions on adding
new models and providers to the configuration.
