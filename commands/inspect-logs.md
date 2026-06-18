---
description: Inspect Solana transaction or simulation logs to identify the first meaningful failure, failing program, and likely root-cause class.
---

Inspect these Solana logs using the solana-incident-skill.

Input:
$ARGUMENTS

Follow this workflow:

1. Read the logs carefully from top to bottom.
2. Identify:
   - the top-level instruction
   - nested invoke depth if present
   - the first meaningful failure
   - the final reported failure
   - the likely failing program
   - whether the failure is top-level or CPI
3. Distinguish between:
   - account validation failure
   - signer / authority failure
   - ownership mismatch
   - PDA mismatch
   - compute exhaustion
   - slippage / stale-state failure
   - token-program mismatch
   - CPI callee failure
   - RPC / simulation mismatch clues
4. If a custom error code appears, normalize it and switch to program-error-classifier behavior.
5. If the transaction never landed and these are only simulation logs, say that clearly.
6. If logs are incomplete, say what cannot be concluded confidently.

Output format:

## First meaningful failure
...

## Failing program
...

## Failure class
...

## Why
...

## What to verify next
- ...

## Escalation
- ...