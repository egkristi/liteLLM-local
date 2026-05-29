# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project scaffold: `config.yaml`, `start.sh`, `.env.example`, `.gitignore`
- Added Moonshot / Kimi model (`kimi-latest`) to `config.yaml` and `KIMI_API_KEY` to `.env.example`
- Added `status.sh` for health checks and model listing
- Added `stop.sh` for clean proxy shutdown
- Added `usage.sh` for quick usage/cost inspection from logs
- Enhanced `start.sh` with prerequisite checks (`uv`, `litellm`), port conflict detection, and `PORT` override support
- Enabled LiteLLM spend tracking and persistent log file output in `config.yaml`
- Created `ISSUES.md`, `ROADMAP.md`, and `CHANGELOG.md`
- Added `Makefile` with `start`, `stop`, `status`, `usage`, `logs`, and `install` targets
- Added cross-platform Python wrapper `litellm-local`
- Added `.vscode/settings.json` snippet for VS Code Copilot Chat setup
- Added `docs/ADDING_MODELS.md` guide for extending model configuration

