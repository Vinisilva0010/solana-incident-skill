# Runbooks

Use this module when the user wants a repeatable operational procedure for a known incident pattern.

Typical requests:

- create a runbook for failed deposits
- define a runbook for dropped transactions
- create a response checklist for mint degradation
- make a triage SOP for RPC inconsistency
- standardize incident handling for bot landing failures
- write an operational checklist for swap-route failures
- convert incident lessons into a reusable procedure

The goal is to produce a runbook that is:
- fast to execute
- easy to follow under stress
- scoped to a concrete incident pattern
- explicit about inputs, checks, decisions, mitigations, and escalation

## Primary Rule

A runbook is not a long explanation.

A runbook is an action procedure for operators.

Write it so that:
- an engineer under time pressure can follow it
- each step has a purpose
- decisions are clear
- escalation conditions are explicit
- the operator knows when to stop, escalate, or switch modules

## When to Use a Runbook

Use a runbook when:
- the incident pattern is recurring
- a response can be standardized
- the team needs faster first response
- knowledge currently lives only in people's heads
- incidents are handled inconsistently
- postmortem findings should become operational procedure

Do not use a runbook as a substitute for deep debugging when the incident class is still unknown.

## Runbook Design Standard

Every runbook should include:

1. purpose
2. trigger conditions
3. severity guidance
4. required inputs
5. immediate containment steps
6. diagnostic sequence
7. decision points
8. mitigation actions
9. escalation criteria
10. exit criteria
11. follow-up actions after stabilization

Keep it concrete and operational.

## Preferred Output Structure

Use this structure unless the user asks for another one.

### 1. Runbook Title
Format:
`Runbook: <specific incident pattern>`

Example:
`Runbook: Mainnet mint transaction landing degradation`

### 2. Purpose
One short paragraph explaining:
- what this runbook is for
- what it is not for
- what success looks like

### 3. Trigger Conditions
List the signals that should cause the runbook to start.

Examples:
- tx landing rate drops below threshold
- failure rate rises above normal baseline
- RPC disagreement appears across providers
- a known route begins reverting
- support reports a repeated user-facing symptom

### 4. Severity Guide
Define when the incident is:
- SEV-1
- SEV-2
- SEV-3

Keep this short and practical.

### 5. Required Inputs
List the minimum facts the responder must collect before deep action.

Examples:
- cluster
- affected flow
- sample signatures
- RPC providers involved
- recent deploys
- fee policy version
- known affected wallets or markets
- timeline start

### 6. Immediate Containment
Give the first actions that reduce impact.

Examples:
- disable affected route
- pause affected feature
- switch to fallback RPC
- revert recent fee policy
- stop retries that create duplicate damage
- freeze automated bot path

### 7. Diagnostic Steps
Give the shortest reliable check sequence.

Number the steps.
Each step should answer one question.

Good:
1. Confirm whether transactions are landing, failing, or expiring
2. Compare blockhash source and confirmation RPC path
3. Compare current CU price against recent account-local fee estimates
4. Check whether issue began after latest release

Bad:
1. Investigate everything related to infrastructure

### 8. Decision Points
Use explicit if/then branching.

Examples:
- If the tx never lands, switch to compute-and-fees analysis
- If the tx lands and fails with custom error, switch to program-error-classifier
- If providers disagree on state, switch to rpc-health
- If failures started after deploy, switch to release-regression

### 9. Mitigation Options
List the allowed mitigations in order of safety.

Examples:
- route-disable
- feature gate
- revert config
- rollback release
- fail over RPC
- revert fee strategy
- pause specific markets

### 10. Escalation Criteria
State exactly when to escalate.

Examples:
- funds at risk
- impact exceeds defined threshold
- no root-cause confidence after 15 minutes
- no containment path available
- multiple flows affected
- suspected signer / authority compromise
- suspected security issue

### 11. Exit Criteria
Define when the runbook can stop.

Examples:
- service restored to normal threshold
- mitigation active and stable
- blast radius contained
- ownership handed off
- postmortem data captured

### 12. Follow-up
After stabilization, state what to do next.

Examples:
- capture timeline
- open incident report
- create postmortem draft
- assign permanent fix owner
- add monitoring gap to backlog
- convert ad hoc steps into improved runbook version

## Writing Style

Runbooks must be:
- brief
- imperative
- stress-friendly
- unambiguous

Prefer:
- "Check whether the signature exists on-chain"
- "Compare blockhash fetch RPC and confirmation RPC"
- "Disable the affected route"

Avoid:
- long theory
- vague advice
- narrative paragraphs
- motivation language
- speculative root-cause claims in the procedure itself

## Solana-Specific Runbook Patterns

When writing Solana runbooks, make the technical layer explicit.

Common patterns:
- dropped transaction response
- failed transaction with custom error
- landing degradation under fee pressure
- blockhash expiry incident
- RPC inconsistency incident
- CPI route failure
- IDL drift after release
- signer / authority mismatch
- Token vs Token-2022 integration failure
- degraded swap routing
- degraded mint success rate
- failed deposit / withdrawal flow

The runbook title should name the actual operational pattern, not generic "Solana incident."

## Output Modes

Choose one:

### A. Full operational runbook
Use when the user wants a complete reusable SOP.

### B. Incident checklist
Use when the user wants a fast checklist for responders.

### C. Decision tree
Use when the incident has several branching outcomes.

### D. Runbook upgrade
Use when the user already has a rough SOP and wants it improved.

Default to Full operational runbook.

## Default Template

Use this template:

```markdown
# Runbook: <incident pattern>

## Purpose
...

## Trigger Conditions
- ...

## Severity Guide
- SEV-1: ...
- SEV-2: ...
- SEV-3: ...

## Required Inputs
- ...

## Immediate Containment
1. ...
2. ...

## Diagnostic Steps
1. ...
2. ...
3. ...

## Decision Points
- If ..., then ...
- If ..., then ...

## Mitigation Options
1. ...
2. ...
3. ...

## Escalation Criteria
- ...

## Exit Criteria
- ...

## Follow-up
- ...
```

## Good Runbook Behavior

A strong runbook should:
- reduce response time
- reduce improvisation
- reduce repeated mistakes
- clarify when to escalate
- convert lessons from past incidents into future speed

## Guardrails

- Do not write a runbook for an undefined incident class.
- Do not make the runbook too long to use during an incident.
- Do not bury critical mitigations deep in the document.
- Do not mix postmortem analysis into live operator steps.
- Do not leave escalation conditions vague.
- Do not confuse diagnosis steps with permanent fixes.