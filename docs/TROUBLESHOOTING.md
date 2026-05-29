# Troubleshooting Guide

Common issues and their solutions when using the LiteLLM local proxy.

---

## DeepSeek: `reasoning_content` Error

**Symptom:** VS Code Copilot Chat shows an error like:
```
"reasoning_content"
```

**Cause:** DeepSeek returns a `reasoning_content` field in its response that some
clients (including VS Code) don't expect, causing a parse error.

**Fix:** This is already handled in `config.yaml`:
```yaml
litellm_settings:
  drop_params: true
```
The `drop_params: true` setting tells LiteLLM to strip unsupported parameters
before sending them to the provider. If you still see the error, make sure
you're using a recent version of LiteLLM:
```bash
uv tool upgrade litellm
```

---

## Ollama Cloud vs Local Models

**Symptom:** Models named `*-cloud` (e.g., `deepseek-v4-pro-cloud`) don't work,
or local models are slow.

**Cause:** Both local and cloud Ollama models use the same `api_base`
(`http://localhost:11434`). The difference is the model name suffix:
- `:cloud` suffix → Ollama routes to their hosted cloud endpoint
- No suffix → runs locally on your machine

**Requirements:**
- Ollama must be running: `ollama serve`
- Cloud models require an internet connection
- Local models require the model to be pulled first: `ollama pull <model>`

**Check if Ollama is running:**
```bash
curl http://localhost:11434/api/tags
```

---

## VS Code 402 / Payment Required Errors

**Symptom:** VS Code Copilot Chat shows "402 Payment Required" when using
certain models.

**Causes and fixes:**

1. **DeepSeek API key expired or out of credits:**
   - Check your DeepSeek account at https://platform.deepseek.com/
   - Rotate your key: `make rotate-key PROVIDER=deepseek`

2. **Mistral API key out of credits:**
   - Check your Mistral account at https://console.mistral.ai/
   - Rotate your key: `make rotate-key PROVIDER=mistral`

3. **Try a different model:**
   - Switch to a free model like Groq: uncomment the Groq entry in
     `.vscode/settings.json`
   - Or use a local Ollama model

---

## Rate Limit Handling

**Symptom:** Requests fail with "429 Too Many Requests" or similar rate limit
errors.

**Solutions:**

1. **Use the fallback model:** Set `model: fallback-deepseek` in your client.
   If DeepSeek is rate-limited, it automatically falls back to Claude Sonnet,
   then Groq.

2. **Add a local model:** Local Ollama models have no rate limits.

3. **Reduce request frequency:** Some free tiers (Groq, Ollama Cloud) have
   strict rate limits.

---

## Proxy Won't Start

**Symptom:** `./start.sh` or `make start` fails.

**Checklist:**

1. **Is `uv` installed?**
   ```bash
   command -v uv
   ```
   If not: `curl -LsSf https://astral.sh/uv/install.sh | sh`

2. **Is `litellm` installed as a uv tool?**
   ```bash
   uv tool list | grep litellm
   ```
   If not: `uv tool install 'litellm[proxy]'`

3. **Does `.env` exist?**
   ```bash
   ls -la .env
   ```
   If not: `cp .env.example .env` and fill in your keys.

4. **Is the port already in use?**
   ```bash
   lsof -Pi :4000
   ```
   If so: `PORT=4001 ./start.sh` or stop the other process.

5. **Run validation:**
   ```bash
   make validate
   ```

---

## API Keys Not Working (401 Unauthorized)

**Symptom:** Requests return "401 Unauthorized" even though keys are set in
`.env`.

**Causes and fixes:**

1. **`.env` not being sourced:** Make sure `start.sh` is used to start the proxy
   (it sources `.env` with `set -a`). Don't run `uv tool run litellm` directly.

2. **Special characters in `.env` values:** If your key contains `$`, `!`, or
   other special characters, wrap the value in single quotes in `.env`:
   ```
   DEEPSEEK_API_KEY='sk-...$pecial!'
   ```

3. **Trailing whitespace:** Make sure there's no trailing whitespace after the
   key value in `.env`.

4. **Run audit:**
   ```bash
   make audit
   ```

---

## Logs Are Too Verbose

**Symptom:** The proxy logs are very noisy with debug information.

**Fix:** In `config.yaml`, set:
```yaml
litellm_settings:
  set_verbose: false
```

---

## JSON Logging

To enable structured JSON logging (useful for `jq`-based filtering):
```bash
litellm-local --json start
# or
LITELLM_JSON_LOGS=true ./start.sh
```

Example: filter for errors only:
```bash
tail -f logs/litellm-*.log | grep '"level":"error"'
```

---

## Getting Help

If you've tried everything above and still have issues:

1. Check the logs: `make logs`
2. Run validation: `make validate`
3. Check proxy status: `make status`
4. Open an issue on GitHub with the relevant log output
