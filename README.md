# solana-incident-skill

**The production copilot Solana teams reach for when something breaks.**

A Claude Code / Codex skill for incident response and runtime triage on Solana — diagnosing transaction failures, program errors, RPC inconsistencies, compute budget issues, CPI bugs, and release regressions in real production environments.

---

## Why this exists

When something breaks in Solana production, engineers lose hours navigating logs, explorers, RPC responses, simulations, and recent commits trying to answer one question: *why did this fail right now?*

Solana's execution model makes this harder than most chains. Errors emerge from interactions between priority fees, compute units, account ownership, PDA derivation, CPI chains, external program versions, and environment differences across local / devnet / mainnet.

This skill gives Claude a structured, expert workflow to work through that complexity fast — from first alert to root cause to postmortem.

---

## What it solves

| Scenario | Skill module used |
|---|---|
| Transaction failed on mainnet, unclear why | `tx-failure-triage` |
| Anchor error code with no context | `program-error-classifier` |
| Inconsistent results across RPC providers | `rpc-health` |
| Bot transactions landing too slow or timing out | `compute-and-fees` |
| CPI call reverting after a dependency update | `cpi-debugging` |
| Works locally, breaks on mainnet after deploy | `release-regression` |
| Need a structured postmortem for the team | `postmortem-generator` |
| Repeatable runbook for known incident types | `runbooks` |

---

## Install

### Option A — Installer script (recommended)

```bash
curl -sSL https://raw.githubusercontent.com//Vinisilva0010/solana-incident-skill/main/install.sh | bash
```

This clones the skill into `~/.claude/skills/solana-incident/`.

### Option B — Manual

```bash
git clone https://github.com/Vinisilva0010/solana-incident-skill.git ~/.claude/skills/solana-incident
```

### Option C — Git submodule (for teams sharing a project config)

```bash
git submodule add https://github.com/Vinisilva0010/solana-incident-skill.git .claude/skills/solana-incident
```

---

## Usage

Once installed, Claude Code picks up the skill automatically at startup. Just describe what's happening:


triage this transaction: 3xK9... it failed with "custom program error: 0x1770"

text
/triage-tx 3xK9mFq... --cluster mainnet-beta

text
/blast-radius upgrading our swap program from v2.1 to v2.3

text
/write-postmortem -- users unable to mint for 47 minutes, root cause was priority fee policy

text

---

## Skill modules

| Module | Loads when |
|---|---|
| `tx-failure-triage` | Diagnosing a failed or dropped transaction |
| `program-error-classifier` | Decoding an Anchor / native program error code |
| `rpc-health` | RPC inconsistency, missing data, or connectivity issues |
| `compute-and-fees` | Compute budget exceeded, slow landing, fee strategy |
| `cpi-debugging` | CPI revert, external program version mismatch |
| `release-regression` | Regression introduced by a deploy or config change |
| `postmortem-generator` | Writing a structured incident postmortem |
| `runbooks` | Building or running a repeatable incident runbook |

---

## Commands

| Command | Description |
|---|---|
| `/triage-tx` | Triage a transaction by signature or raw logs |
| `/inspect-logs` | Deep-analyze program logs from a transaction |
| `/blast-radius` | Predict what surfaces a planned change could break |
| `/write-postmortem` | Generate a structured postmortem from incident notes |

---

## Stack compatibility

Tested against the **2026 Solana stack**:

- Solana CLI 2.x / Agave validator
- Anchor 0.31+
- `@solana/web3.js` v2 / kit
- Helius RPC, Triton, Alchemy, QuickNode
- Jito bundles and tip accounts
- Token-2022 and Token Extensions
- Metaplex Core / Bubblegum v2

---

## License

MIT — free to use, fork, and merge into the Solana AI Kit.

---

## Contributing

PRs welcome. Keep modules focused, token-efficient, and tested against real mainnet failures. See `skill/SKILL.md` for the routing contract.
