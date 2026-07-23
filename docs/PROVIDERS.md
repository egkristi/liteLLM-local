# Provider Reference

This document lists all AI providers available through the LiteLLM proxy,
where to get API keys, the LiteLLM model string format, and current pricing.

## Cloud Providers

### OpenAI

| Field | Value |
|---|---|
| **Website** | https://platform.openai.com/ |
| **API Key** | `OPENAI_API_KEY` in `.env` (starts with `sk-proj-`) |
| **Sign up** | https://platform.openai.com/signup |
| **LiteLLM prefix** | `openai/` |
| **Pricing** | See https://platform.openai.com/pricing |

**Models in config.yaml:**
| model_name | LiteLLM model string | Purpose |
|---|---|---|
| `gpt-5-pro` | `openai/gpt-5-pro` | Most capable, Responses API only |
| `gpt-5` | `openai/gpt-5` | Flagship reasoning |
| `gpt-5-mini` | `openai/gpt-5-mini` | Lightweight reasoning |
| `gpt-5-nano` | `openai/gpt-5-nano` | Fastest/cheapest GPT-5 |
| `gpt-5.1` | `openai/gpt-5.1` | Improved reasoning |
| `gpt-5.2` | `openai/gpt-5.2` | Latest reasoning (xhigh) |
| `gpt-5.4` | `openai/gpt-5.4` | Advanced reasoning |
| `gpt-5.5` | `openai/gpt-5.5` | Full effort range |
| `o4-mini` | `openai/o4-mini` | Fast reasoning |
| `o3-mini` | `openai/o3-mini` | Cost-efficient reasoning |
| `o3` | `openai/o3` | Full reasoning |
| `gpt-4.1` | `openai/gpt-4.1` | Non-reasoning flagship |
| `gpt-4.1-mini` | `openai/gpt-4.1-mini` | Lightweight non-reasoning |
| `gpt-4.1-nano` | `openai/gpt-4.1-nano` | Cheapest non-reasoning |
| `gpt-4o-mini` | `openai/gpt-4o-mini` | Legacy cost-efficient vision |
| `gpt-4o` | `openai/gpt-4o` | Legacy vision flagship |

---

### Google Gemini

| Field | Value |
|---|---|
| **Website** | https://ai.google.dev/ |
| **API Key** | `GEMINI_API_KEY` in `.env` |
| **Sign up** | https://aistudio.google.com/ |
| **LiteLLM prefix** | `gemini/` |
| **Pricing** | Free tier available; see https://ai.google.dev/pricing |

**Models in config.yaml:**
| model_name | LiteLLM model string | Purpose |
|---|---|---|
| `gemini-3.1-flash-lite` | `gemini/gemini-3.1-flash-lite-preview` | Cheapest Gemini |
| `gemini-2.5-flash` | `gemini/gemini-2.5-flash-preview-09-2025` | Fast reasoning |
| `gemini-2.5-flash-lite` | `gemini/gemini-2.5-flash-lite-preview-09-2025` | Cheaper flash |
| `gemini-2.0-flash` | `gemini/gemini-2.0-flash` | Legacy fast model |
| `gemini-1.5-pro` | `gemini/gemini-1.5-pro-latest` | Legacy high-capability |

---

### xAI Grok

| Field | Value |
|---|---|
| **Website** | https://console.x.ai/ |
| **API Key** | `XAI_API_KEY` in `.env` |
| **Sign up** | https://console.x.ai/ |
| **LiteLLM prefix** | `xai/` |
| **Pricing** | See https://console.x.ai/ |

**Models in config.yaml:**
| model_name | LiteLLM model string | Purpose |
|---|---|---|
| `grok-4.1-fast-reasoning` | `xai/grok-4-1-fast-reasoning` | Latest reasoning (2M ctx) |
| `grok-4.1-fast-non-reasoning` | `xai/grok-4-1-fast-non-reasoning` | Fastest (2M ctx) |
| `grok-4` | `xai/grok-4` | Full reasoning (256K ctx) |
| `grok-3` | `xai/grok-3` | Previous-gen reasoning |
| `grok-code` | `xai/grok-code-fast` | Specialized coding |

---

### DeepSeek

| Field | Value |
|---|---|
| **Website** | https://platform.deepseek.com/ |
| **API Key** | `DEEPSEEK_API_KEY` in `.env` |
| **Sign up** | https://platform.deepseek.com/sign_up |
| **LiteLLM prefix** | `deepseek/` |
| **Pricing** | ~$0.14/M input, ~$0.28/M output (V4 Pro); ~$0.07/M input, ~$0.14/M output (V4 Flash) |

**Models in config.yaml:**
| model_name | LiteLLM model string | Purpose |
|---|---|---|
| `deepseek-v4-pro` | `deepseek/deepseek-v4-pro` | Best for coding |
| `deepseek-v4-flash` | `deepseek/deepseek-v4-flash` | Fast/cheap coding |
| `deepseek-r1` | `deepseek/deepseek-reasoner` | Reasoning |

> **Note:** `deepseek-chat` and `deepseek-reasoner` are deprecated (July 24, 2026).
> Use `deepseek-v4-pro` and `deepseek-v4-flash` instead.

---

### Anthropic (Claude)

| Field | Value |
|---|---|
| **Website** | https://console.anthropic.com/ |
| **API Key** | `ANTHROPIC_API_KEY` in `.env` (starts with `sk-ant-`) |
| **Sign up** | https://console.anthropic.com/login |
| **LiteLLM prefix** | `anthropic/` |
| **Pricing** | ~$3/M input, ~$15/M output (Sonnet 5); ~$15/M input, ~$75/M output (Opus 4-8) |

**Models in config.yaml:**
| model_name | LiteLLM model string | Purpose |
|---|---|---|
| `claude-sonnet` | `anthropic/claude-sonnet-5` | Best chat |
| `claude-opus` | `anthropic/claude-opus-4-8` | Most capable |

> **Note:** `claude-sonnet-4-6` and `claude-opus-4-6` are deprecated.
> Use `claude-sonnet-5` and `claude-opus-4-8` instead.

---

### Groq

| Field | Value |
|---|---|
| **Website** | https://console.groq.com/ |
| **API Key** | `GROQ_API_KEY` in `.env` (starts with `gsk_`) |
| **Sign up** | https://console.groq.com/login |
| **LiteLLM prefix** | `groq/` |
| **Pricing** | Free tier available (rate-limited) |

**Models in config.yaml:**
| model_name | LiteLLM model string | Purpose |
|---|---|---|
| `groq-llama` | `groq/llama-3.3-70b-versatile` | Fast inference |

---

### Mistral AI

| Field | Value |
|---|---|
| **Website** | https://console.mistral.ai/ |
| **API Key** | `MISTRAL_API_KEY` in `.env` |
| **Sign up** | https://console.mistral.ai/signup |
| **LiteLLM prefix** | `mistral/` |
| **Pricing** | ~$2/M input, ~$6/M output (Mistral Large 3) |

**Models in config.yaml:**
| model_name | LiteLLM model string | Purpose |
|---|---|---|
| `mistral-large` | `mistral/mistral-large-3` | Strong European model |
| `codestral` | `mistral/codestral-3` | Code generation |

> **Note:** `mistral-large-latest` and `codestral-latest` are deprecated.
> Use `mistral-large-3` and `codestral-3` instead.

---

### Cohere

| Field | Value |
|---|---|
| **Website** | https://dashboard.cohere.com/ |
| **API Key** | `COHERE_API_KEY` in `.env` |
| **Sign up** | https://dashboard.cohere.com/ |
| **LiteLLM prefix** | `cohere_chat/` |
| **Pricing** | See https://cohere.com/pricing |

**Models in config.yaml:**
| model_name | LiteLLM model string | Purpose |
|---|---|---|
| `command-a` | `cohere_chat/command-a-03-2025` | Latest flagship |
| `command-r-plus` | `cohere_chat/command-r-plus-08-2024` | Legacy high-capability |
| `command-r` | `cohere_chat/command-r-08-2024` | Legacy balanced |

---

### Perplexity

| Field | Value |
|---|---|
| **Website** | https://www.perplexity.ai/ |
| **API Key** | `PERPLEXITYAI_API_KEY` in `.env` |
| **Sign up** | https://www.perplexity.ai/settings/api |
| **LiteLLM prefix** | `perplexity/` |
| **Pricing** | See https://docs.perplexity.ai/docs/pricing |

**Models in config.yaml:**
| model_name | LiteLLM model string | Purpose |
|---|---|---|
| `sonar-deep-research` | `perplexity/sonar-deep-research` | Most thorough research |
| `sonar-reasoning-pro` | `perplexity/sonar-reasoning-pro` | Reasoning with search |
| `sonar-pro` | `perplexity/sonar-pro` | Balanced search-grounded |
| `sonar` | `perplexity/sonar` | Lightweight search |

---

### Moonshot / Kimi

| Field | Value |
|---|---|
| **Website** | https://platform.moonshot.cn/ |
| **API Key** | `KIMI_API_KEY` in `.env` (starts with `sk-`) |
| **Sign up** | https://platform.moonshot.cn/console |
| **LiteLLM prefix** | `moonshot/` |
| **Pricing** | ~¥3/M input, ~¥15/M output (K3); ~¥0.95/M input, ~¥4/M output (K2.7) |

**Models in config.yaml:**
| model_name | LiteLLM model string | Purpose |
|---|---|---|
| `kimi-k3` | `moonshot/kimi-k3` | Latest flagship (1M ctx) |
| `kimi-k2.7-code` | `moonshot/kimi-k2.7-code` | Code generation |
| `kimi-k2.7-code-highspeed` | `moonshot/kimi-k2.7-code-highspeed` | Fast code gen |
| `kimi-k2.6` | `moonshot/kimi-k2.6` | Previous-gen balanced |

> **Note:** `kimi-latest` and `moonshot-v1` series are deprecated (sunset Aug 31, 2026).

---

### OpenRouter

| Field | Value |
|---|---|
| **Website** | https://openrouter.ai/ |
| **API Key** | `OPENROUTER_API_KEY` in `.env` (starts with `sk-or-`) |
| **Sign up** | https://openrouter.ai/keys |
| **LiteLLM prefix** | `openrouter/` |
| **Pricing** | Pass-through (varies by model); see https://openrouter.ai/models |

OpenRouter provides unified access to 300+ models. Use `openrouter/<provider>/<model>`.
Also supports embeddings and image generation.

**Models in config.yaml:**
| model_name | LiteLLM model string | Purpose |
|---|---|---|
| `openrouter-best` | `openrouter/openai/gpt-5.2` | Best model via OpenRouter |
| `openrouter-cheap` | `openrouter/openai/gpt-4.1-nano` | Cheapest via OpenRouter |

---

### NVIDIA NIM

| Field | Value |
|---|---|
| **Website** | https://build.nvidia.com/ |
| **API Key** | `NVIDIA_NIM_API_KEY` in `.env` |
| **Sign up** | https://build.nvidia.com/ |
| **LiteLLM prefix** | `nvidia_nim/` |
| **Pricing** | Free tier available; see https://build.nvidia.com/ |

NVIDIA NIM provides hosted open-source models. Use `nvidia_nim/<org>/<model>`.
Default API base: `https://integrate.api.nvidia.com/v1/`. Also supports embeddings and rerank.

**Models in config.yaml:**
| model_name | LiteLLM model string | Purpose |
|---|---|---|
| `nvidia-llama` | `nvidia_nim/meta/llama3-70b-instruct` | Llama 3 70B |
| `nvidia-nemotron` | `nvidia_nim/nvidia/nemotron-4-340b-instruct` | Nemotron 340B |

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
- `glm-5.1:cloud`, `glm-5.2:cloud`
- `kimi-k2.5:cloud`, `kimi-k2.6:cloud`, `kimi-k2.7-code:cloud`
- `minimax-m2.7:cloud`, `minimax-m3:cloud`
- `ministral-3:3b-cloud`, `:8b-cloud`, `:14b-cloud`
- `mistral-large-3:675b-cloud`
- `qwen3.5:397b-cloud`
- `qwen3-vl:235b-cloud`, `:235b-instruct-cloud`

---

## Model Aliases

Convenience names that route to the best model for each task.
Usage: set `model="best-coding"` in your client.

| Alias | Routes to | Purpose |
|---|---|---|
| `best-coding` | `deepseek/deepseek-v4-flash` | Best for coding tasks |
| `best-chat` | `anthropic/claude-sonnet-5` | Best general chat |
| `best-reasoning` | `openai/gpt-5.2` | Best reasoning model |
| `best-research` | `perplexity/sonar-deep-research` | Best research with search |
| `fast` | `groq/llama-3.3-70b-versatile` | Fastest inference (free) |
| `cheap` | `openai/gpt-4.1-nano` | Cheapest cloud model |
| `local` | `ollama/deepseek-v4-pro:cloud` | Local/cloud free model |
| `embedding` | `ollama/nomic-embed-text:latest` | Text embeddings |

---

## Adding a New Provider

See [ADDING_MODELS.md](ADDING_MODELS.md) for step-by-step instructions on adding
new models and providers to the configuration.
