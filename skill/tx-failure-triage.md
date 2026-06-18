# Transaction Failure Triage

Use this module when the main symptom is:

- a failed transaction
- a dropped transaction
- a transaction that never landed
- a transaction that simulated differently than it executed
- a user report that "the transaction did not go through"

This module focuses on rapid classification, evidence gathering, and the shortest path to isolation.

## Primary Goal

Determine which of these broad classes best explains the incident:

1. **Executed but failed**  
   The transaction landed on-chain but returned an execution error.

2. **Never landed / dropped**  
   The transaction was signed or submitted but was never included in a block.

3. **Simulation mismatch**  
   Simulation succeeded but real execution failed, or simulation failed in a way that does not match production behavior.

Do not mix these classes together too early. First identify which one happened.

## Required Inputs

Request the following when available:

- cluster
- transaction signature
- full error text
- full simulation logs
- execution logs from explorer or RPC
- exact instruction being called
- client code used to build and send the transaction
- whether retries were attempted
- RPC provider used for:
  - blockhash fetch
  - simulation
  - submission
  - confirmation
- timestamp or incident window
- whether this issue affects one user, one wallet, or many users
- whether the issue began after a deploy or config change

If no signature exists, ask whether the transaction was ever actually broadcast.

## First Split: Landed vs Not Landed

Start here.

### Case A — Transaction landed but failed

Signs:
- a transaction signature exists on explorer
- fee was charged
- logs show execution started
- result contains a concrete program error

Then focus on:
- which instruction failed
- which program returned the error
- whether the error came from:
  - account validation
  - authority / signer mismatch
  - PDA mismatch
  - ownership mismatch
  - insufficient funds
  - slippage / quote invalidation
  - compute exhaustion
  - CPI downstream failure
  - token-program mismatch
  - stale state assumptions

If the error code is unclear, route to `program-error-classifier.md`.

### Case B — Transaction never landed

Signs:
- user signed but no confirmed signature exists
- client reports timeout or expiry
- explorer never shows the tx
- retry loop eventually gives up
- bot says sent, but chain has no inclusion record

Then focus on:
- stale or invalid blockhash
- RPC lag
- transaction expiry
- low priority fee for the touched accounts
- unrealistic compute unit limit
- poor submission path
- congestion / leader reachability issues
- confirmation logic bugs

If symptoms mention slow landing, expired blockhash, Jito, or fee tuning, route to `compute-and-fees.md`.

### Case C — Simulation mismatch

Signs:
- simulation passes but chain execution fails
- simulation fails but production sometimes succeeds
- different RPCs report different results
- localnet/devnet behavior differs from mainnet-beta

Then focus on:
- state changed between simulation and execution
- commitment mismatch
- RPC inconsistency
- account contention
- stale quote / stale route / stale oracle state
- replaceRecentBlockhash behavior in simulation
- environment drift
- dependency program differences

If the mismatch appears RPC-related, route to `rpc-health.md`.
If the mismatch began after a deploy or dependency update, route to `release-regression.md`.

## Triage Sequence

Follow this order.

### 1. Confirm the transaction class

Ask:

- Did the transaction land on-chain?
- Was a fee charged?
- Is there a signature visible in explorer?
- Did simulation fail, execution fail, or did the transaction never get included?

Do not analyze root cause before this is clear.

### 2. Identify the failing instruction and failing program

If the transaction landed:
- identify which instruction index failed
- identify which program emitted the final meaningful error
- distinguish the top-level caller from a downstream CPI callee

Many misdiagnoses happen because engineers blame the outer instruction while the true failure comes from a callee.

### 3. Check the highest-value common causes

For landed failures, check in this order:

1. account metas wrong
2. signer / authority mismatch
3. account ownership mismatch
4. PDA seeds / bump mismatch
5. Token / Token-2022 mismatch
6. missing ATA assumptions
7. stale quote or slippage protection
8. compute budget exhaustion
9. CPI dependency failure
10. release regression

For non-landed transactions, check in this order:

1. stale blockhash or expiry
2. RPC lag or commitment mismatch
3. compute unit limit badly sized
4. low priority fee for touched accounts
5. bad submission / retry logic
6. leader-path / bundle / networking issues

This ordering matters. Do not default to "fees too low" before checking blockhash freshness and RPC health.

## Blockhash and Expiry Checks

Blockhash handling is one of the most common causes of transaction expiry and confusing non-landing behavior on Solana. Solana documentation explains that confirmation and expiration depend on the relationship between the transaction blockhash, the block height used for expiry, and the RPC used to evaluate validity [web:78]. Helius also notes that "blockhash not found" and expiry issues often come from commitment mismatch, lagging RPCs, or using a blockhash that is too old or newer than what the checking RPC recognizes, and recommends matching `preflightCommitment`, retrying while the blockhash remains valid, and tracking `lastValidBlockHeight` [web:81].

Ask:
- which RPC fetched the blockhash?
- at what commitment was it fetched?
- which RPC submitted the tx?
- which RPC confirmed it?
- was `lastValidBlockHeight` tracked?
- were retries attempted only while the blockhash was still valid?

Suspicion is high when:
- blockhash was fetched too early
- blockhash came from one RPC and submission/checking used a lagging one
- `finalized` was used where fresher confirmation data was needed
- retries continued after expiry
- the team cannot say what `lastValidBlockHeight` was

## Priority Fee and Landing Checks

Dropped transactions are frequently misdiagnosed as "network congestion" when the real issue is a mix of stale blockhashes, incorrect compute sizing, weak submission path, or fees that are not tuned to the local fee market of the accounts touched by the transaction [web:85]. Priority fees on Solana are account-local rather than purely global, so the right question is not "was the network busy?" but "did this transaction bid enough for the contested accounts it touched?" [web:85].

Ask:
- what accounts does the transaction touch?
- was recent prioritization fee data for those accounts queried?
- what CU limit and CU price were set?
- was the CU limit derived from simulation or guessed?
- was a Jito bundle used?
- was the transaction submitted through one path or multiple paths?

Do not recommend blindly raising fees without checking compute sizing and blockhash freshness first [web:85].

## Simulation Mismatch Checks

Simulation can diverge from production when state changes between simulation and landing, when the simulated blockhash is replaced, when RPCs disagree about current state, or when account contention changes execution conditions before inclusion [web:81]. A simulation success does not prove execution success under live state movement, especially for swaps, mints, bots, and highly contested accounts [web:82].

Ask:
- how much time passed between simulation and send?
- did any quoted state change in that window?
- was `replaceRecentBlockhash` used in simulation?
- did the same RPC handle both simulation and send?
- is the affected account hot / frequently updated?
- are slippage, route, oracle, or inventory assumptions time-sensitive?

## Explorer and Log Discipline

When a signature exists:
- inspect the full logs, not just the final error line
- identify the first meaningful failure, not only the last emitted message
- note whether the failing program is the caller or a CPI callee
- capture instruction index, error text, consumed compute units if available, and involved accounts

When logs are missing or incomplete:
- say that confidence is limited
- ask for raw logs from RPC or explorer
- avoid pretending the final answer is known

Metaplex documentation notes that custom Anchor program errors often need to be decoded from the program's error definitions, with Anchor custom error numbering starting at 6000 in common cases, so unclear custom errors should be escalated into explicit decoding rather than guessed [web:91].

## Output Format

Use this structure when delivering transaction triage:

### Current classification
One of:
- executed but failed
- dropped / never landed
- simulation mismatch
- insufficient evidence

### Most likely causes
Rank 2 to 5 hypotheses with one sentence each.

### Evidence for each
List the strongest supporting signal and the strongest missing signal.

### Immediate next checks
Give the smallest possible next actions that reduce uncertainty fastest.

### Mitigation
If user-facing, say how to reduce impact now.

### Escalation path
If needed, explicitly say:
- read `program-error-classifier.md`
- read `compute-and-fees.md`
- read `rpc-health.md`
- read `release-regression.md`

## Example Response Pattern

Example:

- **Current classification:** dropped / never landed
- **Top hypothesis:** stale blockhash caused retries to continue past validity
- **Why:** no explorer inclusion, timeout behavior, and no tracked `lastValidBlockHeight`
- **Next check:** inspect the blockhash fetch RPC, commitment, and whether confirmation used a lagging provider
- **Mitigation:** fetch and submit through fresher RPCs, retry only while valid, and re-estimate CU + priority fee for touched accounts

## Guardrails

- Do not assume "custom program error" means application logic first; it may be account setup or ownership mismatch.
- Do not assume "network congestion" without evidence.
- Do not recommend maxing compute units blindly.
- Do not recommend blindly increasing priority fees.
- Do not treat simulation success as proof.
- Do not claim root cause without distinguishing landed vs dropped vs simulation mismatch.