.PHONY: start stop status usage logs install help

PORT ?= 4000
CONFIG ?= config.yaml

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

install: ## Install uv and litellm (if missing)
	@echo "Checking uv..."
	@command -v uv >/dev/null 2>&1 || (echo "Installing uv..."; curl -LsSf https://astral.sh/uv/install.sh | sh)
	@echo "Checking litellm..."
	@uv tool list 2>/dev/null | grep -q litellm || uv tool install 'litellm[proxy]'
	@echo "Done."

start: ## Start the LiteLLM proxy (CONFIG=config.prod.yaml make start)
	@LITELLM_CONFIG=$(CONFIG) PORT=$(PORT) ./start.sh

stop: ## Stop the LiteLLM proxy
	@PORT=$(PORT) ./stop.sh

status: ## Check proxy health and list models
	@PORT=$(PORT) ./status.sh

usage: ## Show recent usage/cost from logs
	@./usage.sh

logs: ## Tail the latest log file
	@LATEST=$$(ls -t logs/*.log 2>/dev/null | head -n 1); \
	if [ -n "$$LATEST" ]; then tail -f "$$LATEST"; else echo "No logs yet. Start the proxy first."; fi

validate: ## Validate .env, config, and proxy health
	@CONFIG=$(CONFIG) PORT=$(PORT) ./validate.sh

install-autostart: ## Install launchd plist to auto-start proxy on login
	@./install-autostart.sh

vscode-config: ## Regenerate .vscode/settings.json from config.yaml
	@python3 scripts/generate_vscode_settings.py

audit: ## Check .env against .env.example for missing/placeholder keys
	@./audit.sh

rotate-key: ## Rotate an API key (PROVIDER=deepseek make rotate-key)
	@./rotate-key.sh $(PROVIDER)
