# CPI Debugging

Use this module when the failure likely occurs inside a cross-program invocation (CPI), especially when:

- the top-level instruction looks correct but a downstream call fails
- logs show nested invokes
- a dependency protocol integration recently changed
- a PDA is expected to sign during a CPI
- a token, NFT, or DeFi flow fails after entering another program
- the same top-level instruction works until an external program is involved
- the issue appears only for a specific route, pool, market, mint, or external account layout
- the failure started after an SDK, IDL, or dependency update

The goal is to identify:
- which callee actually failed
- whether the CPI was constructed correctly
- whether signer seeds, account metas, and target program expectations match reality
- whether the bug lives in the caller, the callee, or the integration boundary between them

## Primary Rule

Do not blame the top-level instruction until you identify the actual failing callee.

A CPI failure is often misdiagnosed because the outer program is visible to the application team while the real defect sits in:
- the callee program
- the account list passed into the callee
- PDA signer seed derivation
- dependency version drift
- token-program mismatch
- integration assumptions that changed

## Required Inputs

Collect these when possible:

- transaction signature
- full logs with nested invoke lines
- top-level instruction name
- callee program ID
- caller program ID
- exact CPI target instruction if known
- whether Anchor helper CPI or raw `invoke` / `invoke_signed` is used
- PDA seeds used for signer PDAs
- account metas passed into the CPI
- dependency version or SDK version
- whether this began after a protocol upgrade, SDK bump, or config change
- whether the failure is route-specific or universal

If the user cannot identify the callee, ask for full logs first.

## What CPI Means Operationally

Solana defines CPI as one program invoking another during execution, with the caller halted until the callee returns, which means the visible failure may be downstream of the top-level instruction. Solana and Anchor guidance both emphasize that a CPI requires the target program ID, the correct accounts for the target instruction, and the correct instruction data, while PDA-authorized CPI paths require signer seeds via `invoke_signed` or `new_with_signer` patterns rather than ordinary invocation.

This means CPI bugs usually cluster into a few categories:
- wrong callee program
- wrong accounts or account order
- wrong signer model
- wrong PDA seeds or bump
- wrong token program / Token-2022 assumption
- dependency instruction expectations changed
- caller/callee account-state assumptions diverged

## First Split: Which Side Is Broken?

Classify the failure into one of these buckets:

### 1. Caller construction bug
The caller assembled the CPI incorrectly.

Typical signs:
- wrong account metas
- missing writable or signer flags
- wrong account order
- wrong instruction data
- wrong program ID passed as callee
- wrong token program chosen

### 2. PDA signer bug
The CPI requires PDA authorization and the signer path is wrong.

Typical signs:
- `invoke` used where `invoke_signed` was needed
- wrong seeds
- wrong bump
- seeds derived from stale or mismatched inputs
- wrong program ID used in PDA derivation
- Anchor `new` used where `new_with_signer` was needed

### 3. Callee expectation drift
The integration was once valid, but the target program's expectations changed.

Typical signs:
- started after dependency or SDK update
- route-specific failures
- external protocol upgrade
- account layout expectations changed
- instruction parameters no longer accepted
- extra accounts now required

### 4. Boundary-state mismatch
The caller and callee disagree about the current state.

Typical signs:
- account exists but wrong owner / authority / mint / vault state
- stale quote or stale route
- pool or market state changed between build and execution
- state-dependent paths fail intermittently

## Signer and PDA Checks

Solana's `invoke_signed` exists specifically so a program can authorize a CPI on behalf of one or more PDAs it controls; this is a runtime PDA-signing construct, not cryptographic signing by the program itself. Practical CPI guidance also makes clear that plain `invoke` is for cases where the original signer path is enough, while PDA-based authorization requires the exact signer seeds and, in Anchor, typically `new_with_signer` rather than `new`.

Ask:
- does this CPI require a PDA to act as signer?
- if yes, were the seeds exactly the same as the PDA derivation path?
- was the bump correct?
- was the program ID in the derivation the caller's program ID?
- was `invoke_signed` or `new_with_signer` used?
- are the signer expectations on the callee side documented and still current?

A very common mistake is thinking "the program signs." The program does not sign directly; the runtime authorizes PDAs when the seeds are correct [web:134][web:141].

## Account Meta Checks

Anchor and Solana CPI docs both emphasize that the callee must receive the exact accounts it expects, with correct mutability, signer semantics, and program references. Many CPI failures are simple integration hygiene problems disguised as complex protocol issues.

Check:
- correct callee program ID
- correct account order
- all required accounts present
- writable flags correct
- signer flags correct
- system / token / associated token / token-2022 program IDs correct
- account owners match callee expectations
- mint / vault / authority accounts correspond to the same asset universe

If the failure happens after switching to Token-2022 or mixed token stacks, explicitly verify program IDs and account assumptions.

## Dependency Drift Checks

When a CPI path worked before and then broke, do not immediately blame runtime conditions. Anchor guidance notes that CPI usage often depends on imported CPI modules, program interfaces, IDLs, or source-level instruction builders, so SDK or program updates can change assumptions at the integration boundary. This is especially likely when:
- an SDK bump regenerated interfaces
- a protocol changed required accounts
- a helper crate changed account structs
- an external protocol added validation

Ask:
- what changed immediately before failures began?
- was the protocol upgraded?
- was the SDK bumped?
- was the IDL regenerated?
- did any account struct or helper type change?
- are you calling the same instruction with the same accounts as before?

## Log Reading Discipline

For CPI debugging:
- inspect invoke depth
- identify the first callee that emits a meaningful failure
- note whether the failure happened before or after entering the callee
- distinguish "caller assembled wrong CPI" from "callee rejected valid request"

Pay attention to:
- nested `invoke [x]` progression
- the first error emitted inside the callee
- whether compute was mostly consumed before the error
- whether the callee emitted constraint-like errors, ownership errors, or domain errors

If the logs only show the outer instruction failure, request full raw logs.

## Output Format

Use this structure:

### Failing callee
State:
- caller program
- callee program
- whether failure is confirmed inside the CPI path

### Current classification
Choose one:
- caller construction bug
- PDA signer bug
- callee expectation drift
- boundary-state mismatch
- insufficient evidence

### Most likely causes
Rank 2 to 4 likely causes.

### What to verify next
Give the smallest checks that discriminate fastest.

### Immediate mitigation
If user-facing, suggest route gating, feature gating, protocol-specific fallback, or rollback if appropriate.

### Escalation
If needed, route to:
- `program-error-classifier.md`
- `release-regression.md`
- `tx-failure-triage.md`

## Example Response Pattern

Example:

- **Failing callee:** token program CPI from swap executor
- **Current classification:** PDA signer bug
- **Why:** CPI requires PDA authority, but signer derivation path likely changed after refactor
- **Next checks:** compare PDA derivation seeds and bump on client/program side and verify `new_with_signer` or `invoke_signed` usage
- **Mitigation:** disable the affected route until signer path is validated

## Guardrails

- Do not stop at the outer instruction failure.
- Do not assume the external protocol is wrong.
- Do not assume the caller is wrong either.
- Do not confuse missing signer with wrong authority account.
- Do not treat PDA signing as ordinary wallet signing.
- Do not claim a dependency regression without checking what changed.