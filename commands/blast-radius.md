---
description: Assess the likely blast radius of a planned or recent Solana change, including affected flows, likely breakpoints, rollback options, and safest mitigation path.
---

Assess the blast radius of this Solana change using the solana-incident-skill.

Input:
$ARGUMENTS

Follow this workflow:

1. Identify the change surface:
   - program deploy or upgrade
   - IDL change
   - client release
   - SDK bump
   - RPC provider change
   - fee-policy change
   - signer / authority change
   - route or market config change
   - CPI dependency change

2. Identify likely affected layers:
   - transaction construction
   - simulation path
   - landing path
   - program execution
   - CPI integrations
   - read path
   - confirmation path
   - user-facing flows
   - operational monitoring
   - rollback path

3. Estimate the most likely blast radius:
   - one route
   - one feature
   - one market / mint / pool
   - one integration
   - one environment
   - all users of a critical flow
   - system-wide

4. Rank the most likely failure modes.
5. Recommend the safest pre-deploy checks or post-change mitigations.
6. If the change already caused failures, switch to release-regression behavior.
7. If the problem is mainly landing / fee behavior, switch to compute-and-fees behavior.
8. If the problem is mainly integration breakage, switch to cpi-debugging behavior.

Output format:

## Change surface
...

## Likely affected flows
- ...

## Most likely failure modes
1. ...
2. ...
3. ...

## Blast radius estimate
...

## Safest checks before rollout
- ...

## Fastest mitigation if it breaks
- ...

## Escalation
- ...