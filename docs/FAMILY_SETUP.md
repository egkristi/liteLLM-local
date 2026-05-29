# Family Setup Guide

This guide explains how to share the LiteLLM proxy with family members so
everyone can use AI models through a single proxy instance.

## Architecture

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────┐
│  Family Mac  │────▶│  LiteLLM Proxy   │────▶│  DeepSeek     │
│  (host)      │     │  localhost:4000   │     │  Anthropic    │
│              │     │                   │     │  Groq         │
│              │     │                   │     │  Mistral      │
│              │     │                   │     │  Kimi         │
└──────────────┘     └──────────────────┘     └──────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │  Ollama       │
                     │  localhost    │
                     │  :11434       │
                     └──────────────┘
```

## Option 1: Same Mac, Different User Accounts

If family members use different macOS user accounts on the same Mac:

1. **Install the proxy system-wide** so it's available to all users:
   ```bash
   make install-autostart
   ```
   This installs a launchd plist that starts the proxy at boot, before any user
   logs in.

2. **Place `.env` in the project directory** (not in a user's home). The
   launchd plist already references the project directory.

3. **Each user configures their client** to point to `http://localhost:4000`.

4. **Optional: Virtual keys** — set `LITELLM_MASTER_KEY` in `.env` and
   configure each user with a unique virtual key for spend tracking.

## Option 2: Different Macs on the Same Network

If family members have their own Macs on the same home network:

### On the host Mac (running the proxy):

1. **Find your local IP address:**
   ```bash
   ipconfig getifaddr en0
   ```
   (Usually something like `192.168.1.42`)

2. **Bind the proxy to all interfaces** (not just localhost):
   ```bash
   # Edit start.sh or set:
   export LITELLM_HOST="0.0.0.0"
   ```
   Or pass `--host 0.0.0.0` to the litellm command.

3. **Set a master key** for security:
   ```bash
   # In .env:
   LITELLM_MASTER_KEY=sk-litellm-family-secret
   ```

4. **Open the firewall** for port 4000:
   ```bash
   # Allow incoming connections on port 4000
   sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/uv
   ```

### On each family member's Mac (client):

1. **Configure VS Code** to use the proxy:
   - Open VS Code settings (JSON)
   - Add:
   ```json
   {
     "github.copilot.advanced": {
       "debug.overrideProxyUrl": "http://192.168.1.42:4000",
       "debug.chat.overrideProxyUrl": "http://192.168.1.42:4000"
     }
   }
   ```
   (Replace `192.168.1.42` with the host Mac's actual IP)

2. **Test the connection:**
   ```bash
   curl http://192.168.1.42:4000/v1/models
   ```

## Option 3: Tailscale (Recommended for Remote Access)

[Tailscale](https://tailscale.com/) creates a secure mesh network between
devices, even when they're on different networks.

1. **Install Tailscale** on all Macs:
   ```bash
   brew install --cask tailscale
   ```

2. **Sign in** to the same Tailscale account on all devices.

3. **On the host Mac**, bind the proxy to `0.0.0.0` (or the Tailscale IP).

4. **On each client Mac**, use the Tailscale IP of the host:
   ```bash
   tailscale status  # Shows the host's Tailscale IP (100.x.x.x)
   ```

5. **Configure VS Code** with the Tailscale IP.

## Security Considerations

| Risk | Mitigation |
|---|---|
| Unauthorized access | Set `LITELLM_MASTER_KEY` in `.env` |
| API key theft | Use virtual keys per user |
| Network snooping | Use Tailscale (encrypted) |
| Bill shock | Set spend limits per user |

## Monitoring Usage

Check who's using what:
```bash
make usage
```

For per-user breakdown (requires virtual keys):
```bash
# Check spend logs
cat logs/litellm-*.log | grep "user_id" | sort | uniq -c | sort -rn
```
