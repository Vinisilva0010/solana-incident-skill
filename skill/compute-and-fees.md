# Compute Budget and Priority Fees

Use this module when the issue involves:

- slow landing
- dropped transactions
- blockhash expiry under load
- "works sometimes" transaction inclusion
- compute budget exceeded
- transactions that need urgent inclusion
- Jito / bundle inclusion problems
- time-sensitive bot behavior
- swaps, liquidations, mints, deposits, or arbitrage flows under contention
- unclear fee strategy
- retry loops that do not adapt to network conditions

The goal is to decide whether the real problem is:
- compute headroom
- priority fee pricing
- local fee market mismatch
- blockhash lifecycle handling
- send-path design
- Jito / bundle path assumptions
- or some combination of the above

## Primary Rule

Do not treat priority fee tuning as guesswork.

Use evidence:
- compute requirement
- urgency of the flow
- contention on touched accounts
- recent fee conditions
- whether the issue is landing failure or execution failure

Also remember:
- raising the compute unit limit increases the fee base for prioritization
- raising the compute unit price changes the bid for priority
- a bad combination of both can overpay and still fail

## Required Inputs

Collect the following when possible:

- cluster
- transaction signature if any
- whether the transaction landed, failed, or was dropped
- full logs or simulation logs
- compute unit limit set
- compute unit price set
- estimated compute usage from simulation
- touched accounts
- whether recent prioritization fee data was queried
- whether Jito bundles or relays were used
- whether the issue affects one flow or many flows
- target latency / urgency of the transaction
- retry policy
- blockhash fetch / send / confirm RPC path
- whether compute budget instructions were added first

If the user does not know their CU limit or CU price, say that fee diagnosis is incomplete.

## Core Fee Model

Solana documentation states that each transaction pays a base fee of 5,000 lamports per signature plus an optional prioritization fee derived from compute budget instructions [web:128][web:129]. The prioritization fee is calculated from compute unit price and compute unit limit, and it is charged based on the requested limit rather than the actual compute consumed, so oversizing the limit can overpay without improving correctness [web:128][web:123][web:129].

Important consequences:
- you can pay extra and still not land
- you can pay extra and still fail execution
- increasing CU limit is not the same as increasing priority
- poor sizing can waste money and lower operational efficiency

## Formula Awareness

Use this conceptual formula:

- base fee = per-signature fixed fee
- priority fee = compute unit price × compute unit limit

Solana docs express the prioritization fee as:
`ceil(compute_unit_price * compute_unit_limit / 1,000,000)` lamports [web:128][web:129].

Operational meaning:
- **CU price** buys scheduling priority
- **CU limit** buys execution headroom
- set the limit to what the transaction realistically needs plus safety margin
- set the price according to urgency and contention

## Compute Budget Discipline

Metaplex documentation recommends adding compute budget instructions first in the transaction, before the main instructions, and notes that priority fees are most useful during congestion or for time-sensitive operations rather than as a constant default everywhere [web:125]. Compute budget diagnosis is incomplete unless you know:
- how many CUs the transaction actually needs
- how much safety margin is included
- whether budget instructions are ordered correctly
- whether the fee is being paid for a bloated limit instead of a justified one [web:123][web:125]

Ask:
- what CU usage did simulation report?
- what CU limit was set?
- were compute budget instructions first?
- how much margin above simulated usage was allowed?
- does the transaction size or CPI depth vary significantly across attempts?

Do not recommend blindly maxing the CU limit.

## Local Fee Market Awareness

Solana fee behavior is heavily shaped by local fee markets rather than one simple global congestion number. Helius explains that priority fees are influenced by recent fees on the accounts a transaction locks, and account-aware estimation is more useful than naive global guessing [web:121][web:120]. Helius also provides `getPriorityFeeEstimate` specifically to estimate recommended fees from recent network conditions and account locks [web:119][web:131].

Ask:
- which accounts does the transaction lock?
- were recent prioritization fees for those accounts queried?
- did the route or touched accounts change between attempts?
- is the team using global fee assumptions for a local-account problem?

Do not say "network is congested" if the real issue is contention on a specific account set.

## Landing vs Execution

Separate these two cases.

### Case A — Did not land

Suspect:
- blockhash expiry
- CU price too low for urgency and touched accounts
- weak submission path
- stale fee estimate
- Jito path assumptions
- retry logic too slow
- lagging RPC in lifecycle

### Case B — Landed but failed

Suspect:
- compute budget exceeded
- instruction logic error
- CPI failure
- stale quote or slippage
- account mismatch
- token-program mismatch

If the transaction landed and failed with a specific program error, do not over-focus on fees. Route to `tx-failure-triage.md` or `program-error-classifier.md` as needed.

## Blockhash Lifecycle

Slow landing and retries are often misread as fee problems when the real issue is blockhash lifecycle handling. Solana confirmation guidance emphasizes tracking validity windows and using healthy, fresh RPCs when fetching blockhashes [web:78]. Helius similarly notes that blockhash errors often come from mismatched RPCs, lagging nodes, or bad commitment alignment in the fetch/send/confirm lifecycle [web:81].

Ask:
- when was the blockhash fetched?
- was `lastValidBlockHeight` tracked?
- were retries attempted only while valid?
- was the same provider used for send and confirm?
- did fee increases happen after the blockhash was already stale?

Do not recommend fee changes until blockhash handling is sane.

## Jito and Alternate Send Paths

Jito documents that its low-latency transaction send infrastructure is designed for fast landing and performance-sensitive execution, especially for single transactions and bundles in competitive environments [web:130]. But using Jito or a relay path does not eliminate the need for correct compute sizing, valid blockhash handling, or coherent retry strategy.

Ask:
- was the transaction sent via standard RPC, Jito, or both?
- was a bundle used?
- what was the failure mode: not included, late included, reverted, or bundle not accepted?
- was the fallback path clear when the preferred send path did not land?
- did the team assume bundle path alone would solve poor fee or poor blockhash hygiene?

Treat alternate send paths as part of the architecture, not magic.

## A Good Diagnosis Order

Use this order:

1. determine whether the transaction landed
2. determine whether blockhash lifecycle was handled correctly
3. inspect simulated CU usage
4. compare simulated usage against configured CU limit
5. inspect CU price relative to urgency and touched accounts
6. inspect whether fee estimates were account-aware
7. inspect send path and retry design
8. inspect Jito / bundle assumptions if relevant

This order prevents "just raise fees" from becoming the default answer.

## Output Format

Use this response shape:

### Current classification
Choose one:
- underpriced for landing
- compute headroom issue
- blockhash lifecycle issue
- send-path / retry-path issue
- Jito / bundle path issue
- mixed causes
- insufficient evidence

### Evidence
State:
- landed or not
- configured CU limit
- configured CU price
- estimated CU usage
- fee-estimation method used
- blockhash handling status
- send path used

### Most likely causes
Rank 2 to 4 causes.

### Immediate changes
Give the smallest practical changes first.

### Safer long-term fix
Recommend durable engineering improvements.

### Escalation
If needed, route to:
- `tx-failure-triage.md`
- `rpc-health.md`
- `release-regression.md`

## Example Response Pattern

Example:

- **Current classification:** underpriced for landing
- **Why:** transaction never landed, CU limit appears reasonable, but fee pricing was static and not based on touched accounts
- **Next checks:** query recent prioritization fee data for the locked account set and compare against current CU price
- **Immediate change:** keep CU limit close to simulated need with modest margin, then raise CU price rather than bloating the limit
- **Long-term fix:** dynamic fee estimation plus blockhash-aware retry logic

## Practical Rules of Thumb

Use these as guidance, not laws:

- first make blockhash handling correct
- then size CU limit from simulation
- then price urgency with CU price
- re-estimate when the touched accounts or route change
- keep retry policy aware of validity window
- use alternate send paths intentionally, not randomly
- do not pay for giant CU limits unless execution truly needs them
- do not keep a single static fee config for all transaction types

## Guardrails

- Do not recommend blindly increasing fees.
- Do not recommend max CU limit by default.
- Do not confuse landing failure with execution failure.
- Do not use global congestion as a substitute for local fee market analysis.
- Do not assume Jito solves bad transaction construction.
- Do not ignore blockhash lifecycle when debugging inclusion problems.