.PHONY: start stop status usage logs install help

PORT ?= 4000

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

install: ## Install uv and litellm (if missing)
	@echo "Checking uv..."
	@command -v uv >/dev/null 2>&1 || (echo "Installing uv..."; curl -LsSf https://astral.sh/uv/install.sh | sh)
	@echo "Checking litellm..."
	@uv tool list 2>/dev/null | grep -q litellm || uv tool install 'litellm[proxy]'
	@echo "Done."

start: ## Start the LiteLLM proxy (PORT=4001 make start)
	@PORT=$(PORT) ./start.sh

stop: ## Stop the LiteLLM proxy
	@PORT=$(PORT) ./stop.sh

status: ## Check proxy health and list models
	@PORT=$(PORT) ./status.sh

usage: ## Show recent usage/cost from logs
	@./usage.sh

logs: ## Tail the latest log file
	@tail -f logs/*.log 2>/dev/null || echo "No logs yet. Start the proxy first."
