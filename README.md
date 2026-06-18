# Solana Incident Skill

The production copilot for Solana incidents.

`solana-incident-skill` is a production-focused skill for Claude Code / Codex-style agents that helps Solana teams triage broken transactions, debug runtime failures, assess release blast radius, standardize incident response, and generate postmortems.

It is designed for the moments that matter most in production:

- swaps stop landing
- mint success rate drops
- CPI integrations start failing
- RPC providers disagree
- a deploy silently breaks a previously stable flow
- bots degrade under fee pressure
- the team needs a fast, structured diagnosis instead of vague debugging

This skill is built for real Solana builders operating live systems, not toy demos.

## Why this exists

Solana teams already have tools for writing programs, decoding transactions, and exploring chain activity.

What is still missing is a strong **incident-response skill** for the operational layer between:
- protocol engineering
- app engineering
- bot operations
- release management
- observability
- user-impact mitigation

When something breaks in production, teams usually lose time in the same ways:
- mixing up landed failures with dropped transactions
- blaming the top-level instruction when the real failure is inside a CPI
- confusing RPC inconsistency with program bugs
- treating fee-market issues like code regressions
- failing to narrow the change surface after a deploy
- writing weak or incomplete postmortems after the fact

This skill exists to reduce that confusion and turn noisy incident context into a clear next move.

## What it does

`solana-incident-skill` helps an agent:

- classify Solana incidents quickly
- separate landed failures from non-landing / expiry / RPC issues
- inspect logs for the first meaningful failure
- debug CPI boundaries
- analyze regressions after deploys, SDK bumps, IDL drift, or config changes
- assess blast radius before or after changes
- turn repeated incident patterns into runbooks
- generate blameless incident postmortems with concrete action items

## Who this is for

This skill is built for:

- Solana founders running live products
- protocol engineers
- full-stack app teams shipping on Solana
- bot and automation builders
- DeFi integrators
- NFT / mint infrastructure teams
- ops-minded devrel or technical support teams
- hackathon teams trying to ship production-grade systems instead of demos

## Design goals

This skill is intentionally designed to be:

- **useful** in real production incidents
- **cross-domain**, covering engineering, ops, release risk, and incident documentation
- **progressive**, loading only the module needed for the problem at hand
- **practical**, biased toward the safest next step rather than abstract theory
- **kit-compatible**, following the structure expected by the Solana AI Kit

## Core modules

### Skill routing
- `skill/SKILL.md`  
  Main entry point and router.

### Incident analysis
- `skill/incident-intake.md`
- `skill/tx-failure-triage.md`
- `skill/program-error-classifier.md`
- `skill/rpc-health.md`
- `skill/compute-and-fees.md`
- `skill/cpi-debugging.md`
- `skill/release-regression.md`

### Operational maturity
- `skill/postmortem-generator.md`
- `skill/runbooks.md`

## Commands

This repo includes task-specific commands for frequent operational workflows:

- `commands/triage-tx.md`
- `commands/inspect-logs.md`
- `commands/blast-radius.md`
- `commands/write-postmortem.md`

These commands are designed to turn repeated operator tasks into fast, reusable flows.

## Agent

- `agents/incident-responder.md`

This subagent is specialized for:
- incident classification
- likely-cause ranking
- missing-evidence detection
- safe next-step recommendation
- handoff into the correct module

## Example use cases

### 1. Transactions stopped landing
A team shipping swaps or bots sees degraded landing rate on mainnet.  
The skill helps distinguish:
- fee-policy failure
- blockhash lifecycle issues
- RPC path split
- congestion-related landing issues
- actual program failures

### 2. A deploy broke a stable flow
A program upgrade or client release ships and users start failing.  
The skill helps isolate:
- changed surface
- likely blast radius
- IDL drift
- config drift
- dependency regressions
- safest rollback or mitigation path

### 3. CPI path started failing
A top-level instruction looks correct, but nested logs show downstream failure.  
The skill helps identify:
- the true failing callee
- signer-seed issues
- wrong account metas
- ownership assumptions
- token program mismatch
- integration boundary errors

### 4. The team needs a clean incident writeup
After mitigation, the skill turns rough incident notes into:
- a structured postmortem
- timeline
- root cause section
- contributing factors
- action items with owners
- a reusable runbook for future incidents

## Installation

### Option 1: local install script

From the repository root:

```bash
chmod +x install.sh
./install.sh
```

This installs the skill to:

```bash
~/.claude/skills/solana-incident-skill
```

### Option 2: manual install

Create the target directory:

```bash
mkdir -p ~/.claude/skills/solana-incident-skill
```

Copy the repo contents into that location so the final structure includes:

```text
~/.claude/skills/solana-incident-skill/
├── skill/
├── commands/
├── agents/
├── README.md
└── install.sh
```

Then restart Claude Code and start a new session.

## Usage examples

### Ask for incident triage
```text
Triage this Solana incident: swap transactions started failing on mainnet after a release. Some txs never land, others fail in simulation.
```

### Ask for log inspection
```text
Inspect these logs and tell me the first meaningful failure.
```

### Ask for release regression analysis
```text
This flow worked before today's deploy. Help me identify the most likely regression surface and safest rollback path.
```

### Ask for blast radius analysis
```text
Assess the blast radius of switching our priority fee policy and RPC provider for our mint flow.
```

### Ask for a postmortem
```text
Write a blameless postmortem from these notes.
```

## Command examples

Depending on your Claude Code setup, the included commands can support workflows like:

```text
/triage-tx <signature, logs, or incident summary>
/inspect-logs <raw logs>
/blast-radius <planned or recent change>
/write-postmortem <incident notes>
```

## What makes this different

This skill is not a generic Solana coding helper.

It is specifically optimized for:
- incidents in live environments
- operational diagnosis
- production change risk
- runtime failure classification
- cross-functional response workflows

That makes it useful not just to protocol engineers, but also to founders, operators, bot builders, and app teams who need fast and accurate production reasoning.

## Non-goals

This skill is not trying to replace:
- explorers
- low-level transaction decoders
- audit firms
- chain analytics platforms
- full observability stacks
- protocol-specific SDK docs

Instead, it sits above those tools and helps the agent reason about production failures faster.

## Repository structure

```text
solana-incident-skill/
├── agents/
│   └── incident-responder.md
├── commands/
│   ├── blast-radius.md
│   ├── inspect-logs.md
│   ├── triage-tx.md
│   └── write-postmortem.md
├── skill/
│   ├── SKILL.md
│   ├── compute-and-fees.md
│   ├── cpi-debugging.md
│   ├── incident-intake.md
│   ├── postmortem-generator.md
│   ├── program-error-classifier.md
│   ├── release-regression.md
│   ├── rpc-health.md
│   ├── runbooks.md
│   └── tx-failure-triage.md
├── install.sh
└── README.md
```

## Why it fits the Solana AI Kit

This repo is designed to slot cleanly into the Solana AI Kit because it follows the expected skill shape:

- clear `SKILL.md` entry point
- focused submodules for progressive loading
- optional commands
- optional agent
- simple install path
- no opaque binaries
- minimal surface area
- documentation-first structure

It is meant to be easy to review, easy to trust, and easy to merge.

## License

MIT

## Submission summary

`solana-incident-skill` fills a real gap in the Solana ecosystem: operational incident response for live systems.

Instead of helping builders only write code, it helps them survive production:
- triage broken transactions
- debug runtime failures
- isolate regressions after changes
- assess blast radius
- standardize response
- document incidents clearly

This is the kind of skill teams reach for when something important is actually on fire.