---
description: Draft a blameless incident postmortem for a Solana outage, degraded flow, or production regression from rough notes, timeline details, or incident facts.
---

Write a Solana incident postmortem using the solana-incident-skill.

Input:
$ARGUMENTS

Follow this workflow:

1. Determine whether the incident is:
   - resolved
   - mitigated but not fully resolved
   - still under investigation

2. If key facts are missing, ask only for the highest-value details:
   - severity
   - start time
   - recovery / resolution time
   - affected flow
   - affected users
   - impact
   - root cause or leading hypothesis
   - contributing factors
   - actions taken
   - follow-up items and owners

3. Keep the postmortem:
   - factual
   - blameless
   - operationally useful
   - specific about impact, timeline, root cause, and action items

4. Distinguish clearly between:
   - confirmed root cause
   - contributing factors
   - mitigation
   - permanent fix
   - open questions

5. If the user only wants a shorter version, provide an executive summary instead of a full document.

Output format:

# [SEV-X] Incident title

## Summary
...

## Impact
...

## Timeline
- ...
- ...

## Root Cause
...

## Contributing Factors
...

## Detection and Response
...

## Resolution
...

## What Went Well
- ...

## What Needs Improvement
- ...

## Action Items
| Action | Owner | Priority | Due Date |
|---|---|---|---|
| ... | ... | ... | ... |