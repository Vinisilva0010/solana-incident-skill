# Release Regression Analysis

Use this module when the issue started after a change, especially:

- after a program deploy or upgrade
- after an SDK bump
- after an Anchor version change
- after an IDL regeneration
- after a config or environment change
- after switching RPC providers
- after changing fee strategy
- after changing account layouts, seeds, or authority assumptions
- after a dependency protocol update
- when local/devnet still works but mainnet-beta broke
- when a previously stable flow now fails

The goal is to identify:
- what changed
- which change is most plausibly causal
- whether the regression is in program logic, client logic, config, environment, or integration boundaries
- how to mitigate quickly without creating a second incident

## Primary Rule

Do not ask only "what is broken?"

Ask:
- what changed immediately before it broke
- which exact flows regressed
- which flows still work
- whether the failure is universal, route-specific, wallet-specific, or environment-specific

Regression analysis is about narrowing the blast radius of change.

## Required Inputs

Collect as many of these as possible:

- change window
- exact deploy time or release time
- transaction signatures before and after the change
- commit range
- changed files or release notes
- whether the on-chain program changed
- whether the client app changed
- whether the IDL changed
- whether the environment changed
- whether the RPC stack changed
- whether dependencies changed
- whether fee settings changed
- whether wallet, signer, or authority configuration changed
- whether only mainnet-beta is affected
- whether rollback is possible

If the user cannot name the most recent relevant changes, ask for the narrowest time window in which the system last worked.

## First Principle: Stable Until Change

If a flow was stable and then failed after a deploy, upgrade, config change, or SDK bump, the changed surface is the first place to look. Solana programs are upgradeable at the same program address, so logic can change without the program ID changing, which makes "same address" a weak guarantee of behavior continuity [web:151][web:157]. This means regression analysis should focus on changed behavior, not just changed addresses.

## Common Regression Buckets

Classify the incident into one of these buckets first:

### 1. Program logic regression
The deployed on-chain behavior changed.

Signals:
- transaction reaches the same instruction but fails after upgrade
- same client against old version worked
- errors appear inside program logic or constraints
- CPI path changed

### 2. IDL / client drift
The client and program no longer agree on the interface.

IDLs are the bridge between on-chain programs and off-chain clients, describing instructions, accounts, and errors for client generation and decoding [web:158][web:160]. If the program changed but the client still uses stale generated types, stale account assumptions, or stale error mappings, failures can appear as serialization problems, wrong accounts, wrong instruction data, or misleading decode behavior [web:158].

Signals:
- regenerated client not deployed everywhere
- stale frontend / bot package
- wrong instruction encoding
- wrong account layout assumptions
- errors decode strangely after release

### 3. Environment or configuration regression
The code may be fine, but runtime assumptions changed.

Signals:
- wrong cluster
- wrong program ID in environment
- wrong signer or authority key
- RPC switch introduced lag / commitment mismatch
- fee-policy change reduced landing
- feature flags changed behavior
- secrets or config drift

Solana deployment docs stress checking current cluster configuration and program metadata with CLI commands like `solana config get` and `solana program show`, because environment targeting and upgrade authority assumptions are operationally important [web:151].

### 4. Dependency regression
An external protocol, SDK, or helper crate changed assumptions.

Signals:
- CPI routes break after dependency update
- account expectations changed
- instruction builders changed
- helper code generates different transactions
- only one integration path is affected

### 5. Version alignment regression
Tooling or generated artifacts no longer match.

Anchor release guidance recommends matching framework versions carefully, and public troubleshooting references repeatedly point to CLI / crate version mismatches and stale generated artifacts as a recurring source of confusing failures in Anchor workflows [web:148][web:152][web:155].

Signals:
- new build artifacts but old runtime assumptions
- regenerated IDL not propagated
- CLI and crate versions drifted
- only some developers or services reproduce the issue

## Regression Workflow

Follow this order.

### 1. Establish the last known good state

Ask:
- when did this last work?
- which exact flow worked?
- on which cluster?
- under which client version, program version, config, and RPC stack?

Without a last known good reference, regression analysis becomes guesswork.

### 2. Establish the first known bad state

Ask:
- when did the first failure happen?
- which user or bot saw it first?
- which commit / deploy / config change happened between good and bad?
- did anything else change in the same window?

The tighter the good→bad window, the faster the diagnosis.

### 3. Build a change surface map

List all changed surfaces:

- program binary
- IDL
- generated clients
- frontend or bot code
- environment variables
- RPC provider
- fee policy
- signer authority / wallet
- dependency versions
- route lists / market configs
- feature flags

Then rank which changed surfaces actually touch the failing flow.

### 4. Compare successful and failing examples

Ask for:
- one known-good signature
- one known-bad signature
- one unchanged flow that still works, if available

The best regression investigations compare:
- same instruction before vs after
- same wallet before vs after
- same route before vs after
- same cluster before vs after

### 5. Decide whether rollback, feature gating, or isolation is safest

If production impact is active:
- prefer the smallest mitigation with lowest secondary risk
- route-disable before full system shutdown if possible
- rollback only if rollback path is well understood
- explicitly state blast radius of rollback

## High-Value Regression Checks

Always consider these:

### Program upgrade without client alignment
A program upgrade can keep the same address while changing behavior, and if the client keeps stale assumptions, transactions may still compile and send but fail at runtime [web:151][web:157][web:158].

### Wrong program ID or environment config
Environment mistakes are common after releases. Solana docs explicitly recommend verifying cluster config and deployed program metadata because a mismatch between intended target and actual configured target can create very confusing symptoms [web:151].

### IDL drift
If error decoding, instruction encoding, or account layout assumptions changed, stale IDLs can create invisible client/program disagreement [web:158][web:153].

### RPC / fee-policy change mistaken for code regression
Sometimes "the release broke things" actually means:
- new RPC path introduced lag
- new commitment defaults changed behavior
- new fee strategy reduced landing
- retry logic changed

### Dependency CPI drift
If only routes involving one external protocol fail, suspect dependency regression before blaming core application logic.

## Output Format

Use this structure:

### Current regression classification
Choose one:
- program logic regression
- IDL / client drift
- environment / config regression
- dependency regression
- version alignment regression
- mixed causes
- insufficient evidence

### Why this is likely a regression
State the evidence that ties the failure to the change window.

### Most likely changed surfaces
Rank 2 to 5 changed surfaces by likelihood.

### Fastest discriminating checks
Give the minimum checks that separate the top hypotheses.

### Immediate mitigation
Examples:
- rollback
- route-disable
- feature gate
- revert fee policy
- pin dependency version
- re-publish generated client
- restore previous RPC path

### Safer long-term fix
Recommend process improvements:
- release checklist
- generated artifact verification
- canary deploys
- config diff checks
- post-release monitoring gates

### Escalation
If needed, route to:
- `cpi-debugging.md`
- `rpc-health.md`
- `tx-failure-triage.md`
- `postmortem-generator.md`

## Example Response Pattern

Example:

- **Current regression classification:** IDL / client drift
- **Why:** failures began right after the program upgrade, the address stayed the same, and only clients using older generated types are failing
- **Most likely changed surface:** stale generated client / stale IDL assumptions
- **Next checks:** compare deployed program interface assumptions against the currently shipped client package and decode one known-good vs known-bad tx
- **Mitigation:** freeze the affected client release path and republish the generated client before redeploying the program again

## Guardrails

- Do not blame "the deploy" without naming the changed surface.
- Do not assume same program ID means same behavior.
- Do not assume localnet or devnet success disproves mainnet regression.
- Do not recommend rollback casually if the rollback path is unverified.
- Do not ignore config, IDL, or dependency changes while focusing only on Rust code.