# Conventions

This project follows the [CPM naming standard](https://github.com/rkristelijn/cpm) for consistency and quality.

## 1. Plugin Naming

Plugins follow the 3-element formula: `layer-component`

| Layer | Description | Examples |
|:------|:------------|:---------|
| **core** | Hardware drivers, kernel, essential T2 support | `core/t2-kernel`, `core/wifi`, `core/audio` |
| **desktop** | UX layer, gestures, key mapping, tiling | `desktop/touchegg`, `desktop/kinto`, `desktop/fancytiles` |
| **tools** | Optional developer/power-user tooling | `tools/tmux`, `tools/neovim`, `tools/docker` |
| **network** | VPN, firewall, connectivity | `network/nordvpn`, `network/firewall` |
| **skins** | Cosmetic themes and customizations | `skins/winxp` |

## 2. Quality Gate Naming (CPM 4-Element Formula)

`domain`-`flavor`-`intent`-`method`

| Check | Standardized Name | Tier | Tool |
|:------|:-----------------|:-----|:-----|
| Shell format | `scripts-shell-syntax-format` | 1 | shfmt |
| Shell lint | `scripts-shell-syntax-lint` | 2 | shellcheck |
| Secret scan | `meta-secrets-vulnerability-scan` | 2 | gitleaks |
| Inclusive language | `docs-generic-inclusive-lint` | 2 | woke (fallback: grep) |
| SAST vulnerabilities | `code-generic-vulnerability-scan` | 3 | semgrep |
| PII detection | `meta-pii-sensitive-scan` | 3 | grep |
| Dry-run test | `test-install-functionality-validate` | 3 | bash |

## 3. Plugin Contract

Every plugin script MUST implement these functions:

```bash
#!/bin/bash
# plugin: <layer>/<name>
# description: One-line description
# requires: internet | bluetooth | gui
# provides: what this enables

source "${LIB_DIR}/common.sh"

plugin_check()   { ... }  # Already installed? return 0=yes, 1=no
plugin_install() { ... }  # Perform installation
plugin_verify()  { ... }  # Verify it works after install
```

## 4. File Naming

- Scripts: `kebab-case.sh`
- Configs: match upstream naming (e.g., `touchegg.conf`)
- Docs: `kebab-case.md`

## 5. Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(core): add wifi firmware plugin
fix(desktop): touchegg gesture config for Mint 22
docs: add thunderbolt dock guide
chore: update shellcheck to 0.10
```

## 6. Tiered Quality Gates

```bash
make check-fast    # Tier 1: shfmt (fast feedback)
make check         # Tier 2: + shellcheck + gitleaks + woke (default)
make check-full    # Tier 3: + semgrep + PII scan + dry-run test
make fix           # Auto-fix formatting
make pii           # Standalone PII scan
make inclusive     # Standalone inclusive language check
```

### What each tier catches

| Tier | Focus | Blocks commit? |
|:-----|:------|:---------------|
| 1 (fast) | Code style (shfmt) | Yes (pre-commit) |
| 2 (default) | Style + correctness + secrets + inclusive | Yes (CI) |
| 3 (full) | + SAST + PII + integration test | Yes (PR merge) |

### Inclusive language replacements

| Avoid | Use instead |
|:------|:------------|
| blacklist | denylist, blocklist |
| whitelist | allowlist, safelist |
| master (branch/device) | main, primary, leader |
| slave | replica, follower, worker |
| dummy | sample, placeholder, stub |
| sanity check | quick check, validation |

### PII patterns detected

- Email addresses (real, not `@DEFAULT_SINK@` or `user@example.com`)
- Hardcoded home directories (`/home/username/` instead of `$HOME`)
- Private IP addresses (`192.168.x.x`, `10.x.x.x`)
- SSH keys, AWS keys, GitHub tokens
