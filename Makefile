# t2-opencare Makefile — CPM-style quality gates

SHELL := /bin/bash
SCRIPTS := $(shell find . -name '*.sh' -not -path './.git/*')
DOCS := $(shell find . -name '*.md' -not -path './.git/*')
ALL_FILES := $(shell find . -not -path './.git/*' -type f)

.PHONY: check check-fast check-full lint format secrets semgrep pii inclusive test clean fix tools help

## Default: Tier 2 (format + lint + secrets + inclusive)
check: format lint secrets inclusive
	@echo ""
	@echo "✓ All Tier 2 checks passed"

## Tier 1: fast feedback
check-fast: format
	@echo "✓ Tier 1 (format) passed"

## Tier 3: exhaustive
check-full: check semgrep pii test
	@echo "✓ Tier 3 (full) passed"

## ─── Format ────────────────────────────────────────────────────

## Format all shell scripts (shfmt)
format:
	@echo ":: scripts-shell-syntax-format"
	@if command -v shfmt &>/dev/null; then \
		shfmt -i 2 -ci -d $(SCRIPTS) && echo "  ✓ shfmt" || { echo "  ✗ shfmt — run 'make fix' to auto-fix"; exit 1; }; \
	else \
		echo "  ⊘ shfmt not installed — skipping"; \
	fi

## Auto-fix formatting
fix:
	@echo ":: auto-fixing format"
	@if command -v shfmt &>/dev/null; then \
		shfmt -i 2 -ci -w $(SCRIPTS); \
		echo "  ✓ shfmt fixed"; \
	fi

## ─── Lint ──────────────────────────────────────────────────────

## Lint shell scripts (shellcheck)
lint:
	@echo ":: scripts-shell-syntax-lint"
	@if command -v shellcheck &>/dev/null; then \
		shellcheck -x -S warning $(SCRIPTS) && echo "  ✓ shellcheck" || { echo "  ✗ shellcheck"; exit 1; }; \
	else \
		echo "  ⊘ shellcheck not installed — skipping"; \
	fi

## ─── Security ──────────────────────────────────────────────────

## Scan for hardcoded secrets (gitleaks)
secrets:
	@echo ":: meta-secrets-vulnerability-scan"
	@if command -v gitleaks &>/dev/null; then \
		gitleaks detect --source . --no-git --no-banner 2>/dev/null && echo "  ✓ gitleaks" || { echo "  ✗ secrets detected!"; exit 1; }; \
	else \
		echo "  ⊘ gitleaks not installed — skipping"; \
	fi

## SAST vulnerability scan (semgrep)
semgrep:
	@echo ":: code-generic-vulnerability-scan"
	@if command -v semgrep &>/dev/null; then \
		semgrep scan --config auto --error --quiet 2>&1 && echo "  ✓ semgrep" || { echo "  ✗ semgrep found issues"; exit 1; }; \
	else \
		echo "  ⊘ semgrep not installed — skipping"; \
	fi

## ─── PII Detection ────────────────────────────────────────────

## Scan for personally identifiable information
pii:
	@echo ":: meta-pii-sensitive-scan"
	@echo "  Scanning for email addresses..."
	@found=0; \
	emails=$$(grep -rn --include='*.sh' --include='*.md' --include='*.conf' --include='*.toml' \
		-E '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' . \
		--exclude-dir=.git \
		| grep -v '@DEFAULT_SINK@' \
		| grep -v '@cinnamon.org' \
		| grep -v 'user@host' \
		| grep -v 'user@example' \
		| grep -v '@basgeertsema' \
		|| true); \
	if [ -n "$$emails" ]; then echo "$$emails"; found=1; fi; \
	echo "  Scanning for hardcoded usernames..."; \
	users=$$(grep -rn --include='*.sh' --include='*.md' --include='*.conf' --include='*.toml' \
		-E '/home/[a-z][a-z0-9]+/' . --exclude-dir=.git \
		| grep -v '/home/\$$' \
		| grep -v '/home/<user>' \
		| grep -v 'HOME' \
		|| true); \
	if [ -n "$$users" ]; then echo "$$users"; found=1; fi; \
	echo "  Scanning for private IPs (non-example)..."; \
	ips=$$(grep -rn --include='*.sh' --include='*.md' --include='*.conf' --include='*.toml' \
		-E '(192\.168\.[0-9]+\.[0-9]+|10\.[0-9]+\.[0-9]+\.[0-9]+)' . --exclude-dir=.git \
		| grep -v 'example' \
		| grep -v '#.*placeholder' \
		|| true); \
	if [ -n "$$ips" ]; then echo "$$ips"; found=1; fi; \
	echo "  Scanning for SSH keys / tokens..."; \
	keys=$$(grep -rn --include='*.sh' --include='*.md' --include='*.conf' --include='*.toml' \
		-E '(ssh-ed25519|ssh-rsa|AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]+)' . --exclude-dir=.git \
		|| true); \
	if [ -n "$$keys" ]; then echo "$$keys"; found=1; fi; \
	if [ $$found -eq 1 ]; then echo "  ✗ PII/sensitive data detected!"; exit 1; \
	else echo "  ✓ no PII found"; fi

## ─── Inclusive Language ────────────────────────────────────────

## Check for non-inclusive terminology (woke)
inclusive:
	@echo ":: docs-generic-inclusive-lint"
	@if command -v woke &>/dev/null; then \
		woke $(SCRIPTS) $(DOCS) && echo "  ✓ woke (inclusive language)" || { echo "  ✗ non-inclusive language found"; exit 1; }; \
	else \
		echo "  ⊘ woke not installed — running basic check"; \
		found=0; \
		hits=$$(grep -rni --include='*.sh' --include='*.md' --include='*.conf' --include='*.toml' \
			-E '\b(blacklist|whitelist|master[^y]|slave|dummy|sanity.check|man.hours?)\b' . \
			--exclude-dir=.git \
			| grep -v 'CONVENTIONS.md' \
			| grep -v 'Makefile' \
			| grep -v '.woke.yml' \
			| grep -v 'modprobe.d/blacklist' \
			| grep -v 'blacklist-applespi' \
			| grep -v 'scripts/doctor.sh' \
			|| true); \
		if [ -n "$$hits" ]; then \
			echo "$$hits"; \
			echo ""; \
			echo "  Suggestions:"; \
			echo "    blacklist → denylist/blocklist"; \
			echo "    whitelist → allowlist/safelist"; \
			echo "    master    → main/primary/leader"; \
			echo "    slave     → replica/follower/worker"; \
			echo "    dummy     → sample/placeholder"; \
			echo "    sanity check → quick check/validation"; \
			echo "    man hours → person hours"; \
			found=1; \
		fi; \
		if [ $$found -eq 1 ]; then echo "  ✗ non-inclusive terms found"; exit 1; \
		else echo "  ✓ inclusive language check passed"; fi; \
	fi

## ─── Test ──────────────────────────────────────────────────────

## Dry-run install test
test:
	@echo ":: testing install.sh --dry-run"
	@bash install.sh --dry-run --all

## Hardware & config diagnostics
doctor:
	@bash scripts/doctor.sh

## Hardware diagnostics + auto-repair
doctor-fix:
	@sudo bash scripts/doctor.sh --fix

## ─── Setup ─────────────────────────────────────────────────────

## Install quality tools
tools:
	@echo ":: Installing quality tools..."
	sudo apt-get install -y shellcheck
	@command -v shfmt &>/dev/null || echo "  Install shfmt: go install mvdan.cc/sh/v3/cmd/shfmt@latest"
	@command -v gitleaks &>/dev/null || echo "  Install gitleaks: https://github.com/gitleaks/gitleaks#installation"
	@command -v semgrep &>/dev/null || echo "  Install semgrep: pip install semgrep"
	@command -v woke &>/dev/null || echo "  Install woke: brew install get-woke/tap/woke (or go install github.com/get-woke/woke@latest)"
	@echo "Done. Re-run 'make check' to verify."

## Clean
clean:
	@echo "Nothing to clean."

## Help
help:
	@echo "t2-opencare quality gates (CPM-style):"
	@echo ""
	@echo "  make check-fast   Tier 1: format only (shfmt)"
	@echo "  make check        Tier 2: format + lint + secrets + inclusive (default)"
	@echo "  make check-full   Tier 3: + semgrep + PII scan + dry-run test"
	@echo ""
	@echo "  make doctor       Hardware & config diagnostics"
	@echo "  make doctor-fix   Diagnostics + auto-repair"
	@echo ""
	@echo "  make fix          Auto-fix formatting"
	@echo "  make pii          Scan for personal data (emails, IPs, paths)"
	@echo "  make inclusive    Check inclusive language"
	@echo "  make semgrep      SAST vulnerability scan"
	@echo "  make secrets      Scan for hardcoded secrets"
	@echo "  make tools        Install quality gate tools"
	@echo "  make help         This message"
	@echo ""
	@echo "  Tier layout:"
	@echo "    1 (fast)  → shfmt"
	@echo "    2 (default) → + shellcheck + gitleaks + woke"
	@echo "    3 (full)  → + semgrep + PII + dry-run"
