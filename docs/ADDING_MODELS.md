# Adding Custom Models

You can extend `config.yaml` with additional models without breaking existing ones.

## Quick steps

1. Open `config.yaml`.
2. Add a new entry under `model_list`:

```yaml
  - model_name: my-custom-model
    litellm_params:
      model: openai/gpt-4o
      api_key: os.environ/OPENAI_API_KEY
```

3. Add the corresponding API key to your `.env` file:

```env
OPENAI_API_KEY=sk-...
```

4. Restart the proxy:

```bash
./stop.sh && ./start.sh
```

## Finding the correct `model` string

LiteLLM uses the format `provider/model-name`. See the [LiteLLM provider docs](https://docs.litellm.ai/docs/providers) for the exact string for each provider.

Common examples:

| Provider | Example model string |
|---|---|
| OpenAI | `openai/gpt-4o` |
| Azure OpenAI | `azure/gpt-4o` |
| Cohere | `cohere/command-r-plus` |
| AI21 | `ai21/jamba-1.5-large` |
| Together AI | `together_ai/meta-llama/Llama-3.3-70B-Instruct-Turbo` |
| Local (Ollama) | `ollama/llama3.2` |

## Tips

- Use `drop_params: true` in `litellm_settings` to avoid errors when a provider doesn't support a parameter sent by the client.
- Use `api_base` for self-hosted or local endpoints (e.g., Ollama, vLLM).
- You can define multiple aliases pointing to the same underlying model with different parameters (e.g., temperature presets).
