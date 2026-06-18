# RPC Health and Consistency

Use this module when the issue may be caused or amplified by RPC behavior rather than purely by application logic.

Typical triggers:

- one RPC says the transaction exists and another does not
- one RPC simulates successfully and another fails
- account data looks stale or inconsistent
- commitment-level confusion
- "node is behind" or freshness concerns
- blockhash fetched from one provider but transaction sent through another
- confirmation behavior is inconsistent across providers
- heavy account reads are timing out or returning surprising results
- `getProgramAccounts` is slow or unstable
- users report intermittent failures that cannot be reproduced consistently

The goal is to determine whether the incident is:
- a real chain state problem
- an RPC freshness problem
- a commitment mismatch problem
- a provider-specific behavior problem
- an application read/write path design problem

## Primary Rule

Do not treat "RPC issue" as a vague fallback explanation.

Be precise:
- which provider
- which method
- which commitment level
- which returned slot / context slot
- which workflow was affected
- whether this was a read-path problem, send-path problem, simulate-path problem, or confirm-path problem

## Required Inputs

Collect as many of these as possible:

- cluster
- providers involved
- RPC methods involved
- commitment levels used for each method
- returned slot / context slot if available
- whether the problem affects reads, writes, simulation, confirmation, or all of them
- blockhash source RPC
- transaction submission RPC
- transaction confirmation RPC
- whether WebSocket subscriptions are involved
- whether failover or load balancing is in place
- whether the issue is intermittent or consistent
- exact time window
- sample signatures or accounts showing disagreement

If the user only says "RPC is broken," narrow it immediately.

## The Four RPC Paths

Separate the system into four paths:

1. **Read path**  
   Account fetches, balances, token data, `getProgramAccounts`, indexing-style reads

2. **Simulation path**  
   `simulateTransaction`, preflight checks, dry-runs

3. **Submission path**  
   `sendTransaction`, bundle submission, relay behavior

4. **Confirmation path**  
   `getSignatureStatuses`, WebSocket confirms, explorer consistency

Many teams incorrectly treat these as one thing. Diagnose them separately.

## Commitment Discipline

Solana commitment levels represent different levels of network confirmation, and different RPC queries may legitimately return different answers if they use different commitment levels [web:105][web:106]. A frequent production bug is not "bad RPC" but an application mixing `processed`, `confirmed`, and `finalized` across blockhash fetch, simulation, reads, and confirmation, creating false inconsistencies [web:81][web:105].

Always ask:
- what commitment level was used for the read?
- what commitment level was used for blockhash fetch?
- what commitment level was used for simulation?
- what `preflightCommitment` was used for send?
- what commitment level was used for confirmation?

If these are inconsistent, suspect application design first.

## Freshness and Lag

Solana's confirmation guidance recommends using healthy RPC nodes, comparing freshness across endpoints, and preferring fresher context when fetching blockhashes because lagging nodes can cause expiry, confusing missing-state behavior, and false negatives around recent activity [web:78]. Helius likewise warns that using different RPCs for blockhash fetch and send/validation can create blockhash validity errors when one node lags behind the other [web:81].

Suspicion is high when:
- one RPC is behind the cluster tip
- returned context slots differ materially
- one provider sees the signature while another does not
- new accounts appear missing on one node but present on another
- a send path uses one provider while confirmation polls a lagging provider

When possible, compare:
- endpoint name
- method
- commitment level
- returned slot / context slot
- latency
- whether the affected workflow is read, simulate, send, or confirm

## Blockhash Path Mismatch

A common production failure is:
- fetch blockhash from provider A
- simulate through provider B
- send through provider C
- confirm through provider D

This architecture can work, but only if freshness and commitment are tightly controlled. Helius specifically recommends aligning blockhash commitment and `preflightCommitment`, and being careful when different providers are involved in the same transaction lifecycle [web:81]. Solana documentation also recommends getting fresh blockhashes from healthy nodes and, when comparing endpoints, using the one with the freshest context [web:78].

Ask:
- which RPC returned the blockhash?
- what slot did it report?
- which RPC simulated?
- which RPC sent?
- which RPC checked confirmation?
- did all use aligned commitment assumptions?

If not, call this out explicitly as a likely architecture issue.

## Read-Path Pitfalls

For read-heavy applications, especially dashboards, bots, and indexer-lite backends, not every inconsistency is a provider failure. Some methods are inherently expensive and more sensitive to response-time variability. Solana's `getProgramAccounts` returns all accounts owned by a program, optionally filtered, and Tatum notes that it can be slow on large programs, especially with `jsonParsed`, weak filtering, or overly broad scans [web:115][web:110].

Ask:
- is the app overusing `getProgramAccounts` in latency-sensitive paths?
- is `jsonParsed` being used where `base64` plus local decoding would be cheaper?
- are filters narrow enough?
- is the app expecting real-time behavior from a heavy scan method?
- is caching missing where workload would benefit from it?

Do not label expected slowness from a heavy method as mysterious RPC instability.

## Confirmation Path Pitfalls

The confirmation path should treat the transaction signature as the durable source of truth once the transaction is actually submitted. Solana guidance emphasizes checking status and validity explicitly rather than guessing from client timeouts, and blockhash-expiry handling should be tied to `lastValidBlockHeight` and observed status checks rather than blind resends [web:78][web:81].

Ask:
- do you have a signature?
- was `getSignatureStatuses` checked?
- was the transaction resent before checking if the original landed?
- was the same signature tracked across retries?
- did timeouts cause duplicate submissions or duplicate user actions?

A common anti-pattern is resending without first determining what happened to the first attempt.

## Simulation Path Pitfalls

Simulation can disagree across providers when:
- providers are at different slots
- commitments differ
- different account states are visible
- `replaceRecentBlockhash` behavior differs or is omitted
- the transaction depends on rapidly moving state [web:81]

Ask:
- which provider ran simulation?
- at what commitment?
- was `replaceRecentBlockhash` used?
- was the same provider used for send?
- did the affected accounts change between simulation and execution?

Do not assume simulation disagreement means one provider is wrong; often they are observing different valid snapshots.

## A Simple Classification Framework

Classify the incident into one of these buckets:

### 1. Commitment mismatch
Different paths used inconsistent commitment settings.

### 2. Freshness gap
One or more providers were behind enough to affect the workflow.

### 3. Path split architecture issue
Blockhash / simulate / send / confirm used incompatible providers or assumptions.

### 4. Heavy-read misuse
The app relied on expensive read methods in latency-sensitive flows.

### 5. Provider-specific degradation
One provider behaved materially worse than others for the same method and commitment.

### 6. Not an RPC issue
The evidence points back to application logic, fees, compute, or account state.

## Output Format

Use this response shape:

### Current classification
Pick one of the six buckets above.

### Evidence
State:
- which providers differ
- which methods differ
- which commitments differ
- which slots differ
- which workflow is impacted

### Likely root-cause candidates
Rank 2 to 4 causes.

### Fastest next checks
Give the minimum next actions that remove uncertainty.

### Mitigation
Examples:
- unify commitment settings
- use fewer providers in the same tx lifecycle
- fail over reads but keep write path stable
- move heavy scans off hot user flows
- confirm by signature before resending

### Escalation
If needed, route to:
- `compute-and-fees.md`
- `tx-failure-triage.md`
- `release-regression.md`

## Example Response Pattern

Example:

- **Current classification:** commitment mismatch
- **Why:** blockhash fetched at `confirmed`, preflight checked at another effective view, and confirmation polled through a lagging provider
- **Most likely impact:** false blockhash validity failures and inconsistent transaction visibility
- **Next checks:** capture commitment and context slot for each RPC path in the lifecycle
- **Mitigation:** align blockhash fetch, preflight, and confirmation assumptions before changing providers or fees

## Guardrails

- Do not say "RPC issue" without naming the method and path.
- Do not compare provider responses taken at different commitments as if they should match.
- Do not recommend multi-provider sprawl without clear path ownership.
- Do not treat `getProgramAccounts` slowness as surprising on large programs.
- Do not resend unknown transactions before checking by signature.
- Do not blame the provider before checking commitment mismatch and architecture split.