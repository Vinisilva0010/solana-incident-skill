---
description: Triage a Solana transaction failure, dropped transaction, or non-landing transaction from a signature, error string, or raw logs.
---

Triage this Solana transaction incident using the solana-incident-skill.

Input:
$ARGUMENTS

Follow this workflow:

1. Determine whether the transaction:
   - landed and failed
   - never landed
   - shows simulation mismatch
   - has insufficient evidence

2. Ask for missing high-value information only if required:
   - cluster
   - signature
   - full error text
   - raw logs
   - failing instruction
   - blockhash / send / confirm RPC path
   - compute unit limit and price if landing is the issue

3. Use the smallest useful next-step plan.
4. Rank likely causes instead of jumping to one answer.
5. If the code is unclear, switch to program-error-classifier behavior.
6. If the issue looks like RPC inconsistency, switch to rpc-health behavior.
7. If the issue looks like fee / landing / blockhash handling, switch to compute-and-fees behavior.
8. If the issue began after a change, switch to release-regression behavior.

Output format:

## Current classification
...

## Most likely causes
1. ...
2. ...
3. ...

## What I need next
- ...

## Immediate actions
- ...

## Escalation
- ...