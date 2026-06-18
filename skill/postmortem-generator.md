# Postmortem Generator

Use this module when the user wants to:

- write a postmortem
- draft a post-incident review
- summarize an outage for internal teams
- prepare a root-cause writeup
- document impact, timeline, mitigation, and follow-up actions
- create a reusable incident report after stabilizing a production problem

This module is for post-incident learning and documentation, not live incident command.

## Primary Rule

A good postmortem is:
- factual
- blameless
- specific
- concise
- useful for future operators

Google's SRE guidance defines a postmortem as a written record of an incident, its impact, the actions taken to mitigate or resolve it, the root cause(s), and the follow-up actions to prevent recurrence, and emphasizes that the process should be blameless and focused on contributing causes rather than individual blame. Other incident management references consistently reinforce the same structure: timeline, impact, root cause, remediation, and action items with owners and follow-up.

## Before Writing

Before drafting, confirm the incident is stable enough for documentation.

If the incident is still active:
- do not switch into narrative mode too early
- first prioritize restoration and evidence preservation
- only then write the postmortem

This aligns with SRE incident guidance to stop the bleeding, restore service, and preserve evidence before deeper analysis.

## Required Inputs

Collect as much of the following as possible:

- incident title
- severity
- status: resolved, mitigated, or still under investigation
- start time
- detection time
- mitigation start time
- recovery time
- full resolution time
- affected services or flows
- affected users or internal teams
- customer impact
- business impact if known
- summary of what happened
- root cause if known
- contributing factors
- timeline of key events
- actions taken
- what worked
- what did not work
- follow-up actions
- owners for each action item
- expected deadlines if available

If key facts are missing, ask for them before pretending the postmortem is complete.

## Postmortem Writing Standard

The document should do five things well:

1. explain what happened
2. explain impact
3. explain why it happened
4. explain how it was mitigated and resolved
5. explain what will change to reduce recurrence

Datadog, Atlassian, PagerDuty, and other incident references all recommend keeping postmortems easy to search, readable by non-responders, and specific enough to support later learning and action tracking.

## Tone Rules

Write in a calm, engineering-professional tone.

Always:
- use neutral language
- focus on systems and conditions
- separate fact from inference
- distinguish confirmed root cause from still-open hypotheses
- note uncertainty explicitly
- avoid shame, blame, and hero storytelling

Never:
- blame a person or team
- use vague filler like "human error" as a root cause
- call the issue resolved if recovery is partial
- claim certainty without evidence

Blameless practice is a core recommendation across SRE and incident management sources.

## Preferred Structure

Use this exact structure unless the user asks for another format.

### 1. Title
Short, specific, searchable.

Format:
`[SEV-X] Short description of impact`

Example:
`[SEV-1] Mint transactions failing due to stale priority fee policy`

### 2. Summary
One short paragraph covering:
- what happened
- who was affected
- duration
- current status

### 3. Impact
Include:
- affected product areas
- affected users / traffic / flows
- operational or financial consequences if known
- whether impact was total or partial

### 4. Timeline
Use a concise timestamped list.
Prefer 5 to 12 meaningful events:
- first detection
- first human acknowledgment
- first mitigation attempt
- major diagnostic findings
- status updates
- recovery point
- resolution point

Atlassian specifically recommends including alert times, comms updates, remediation attempts, and resolution times.

### 5. Root Cause
State:
- confirmed root cause, if known
- contributing factors
- what conditions allowed the issue to reach users

If root cause is not confirmed, say:
`Root cause remains under investigation. The current leading hypothesis is ...`

### 6. Detection and Response
Describe:
- how the issue was detected
- what signals worked
- what signals were missing
- how the team responded
- what slowed diagnosis or mitigation

### 7. Resolution
Describe:
- what changed to restore service
- whether this was rollback, failover, hotfix, route disable, fee-policy revert, config fix, or another intervention
- whether the fix is permanent or temporary

### 8. What Went Well
Keep it short and factual.

### 9. What Needs Improvement
Focus on systems, tooling, process, observability, rollout, testing, and communication.

### 10. Action Items
Each action item should have:
- clear deliverable
- owner
- priority or severity
- due date if known

Several incident-management guides recommend concrete action items with owners and deadlines rather than vague aspirations.

## Action Item Rules

Action items must be:
- concrete
- measurable
- scoped
- owned

Bad:
- "Improve monitoring"
- "Be more careful"
- "Test more"

Good:
- "Add alert when tx landing rate for mint instruction drops below 92% for 5 minutes"
- "Pin generated client version to deployed IDL hash in CI"
- "Block production release if fee estimator health check fails"

Prefer 1 to 5 high-quality actions over a long weak list.

## Timeline Rules

The timeline should be:
- factual
- ordered
- timestamped
- free from interpretation where possible

Good timeline line:
- `12:03 UTC — First alert triggered for elevated mint failure rate`
- `12:07 UTC — Team confirmed failures were isolated to mainnet-beta`
- `12:18 UTC — Priority fee policy rollback started`

Bad timeline line:
- `The system was acting weird and the team tried some things`

## Solana-Specific Guidance

When the incident involves Solana, the postmortem should explicitly note which technical layer failed.

Examples:
- transaction landing path
- blockhash lifecycle
- priority fee policy
- compute budget sizing
- RPC consistency
- program logic
- CPI integration
- signer / authority model
- IDL / client drift
- dependency protocol change

This makes the writeup much more useful to future builders than generic blockchain language.

## Output Modes

Choose one of these output modes:

### A. Full postmortem
Use when the user wants a complete document.

### B. Executive summary
Use when the user needs a short internal or stakeholder-facing summary.

### C. Action-item extraction
Use when the user already has notes and wants clean follow-up tasks.

### D. Timeline reconstruction
Use when the user has scattered facts and wants them organized first.

If the user asks for "write the postmortem," default to Full postmortem.

## Default Output Template

Use this template:

```markdown
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
```

## Example Response Pattern

Example:

- **Title:** `[SEV-1] Swap transactions degraded due to stale account-local fee assumptions`
- **Summary:** 43-minute partial outage affecting mainnet swap execution
- **Root cause:** static priority fee policy failed under changed local contention
- **Contributing factors:** no landing-rate alert, retry policy ignored validity window
- **Resolution:** moved to account-aware fee estimate and reverted failing path
- **Action items:** alerting, release gate, retry logic fix

## Guardrails

- Do not write a fake root cause.
- Do not assign blame to individuals.
- Do not skip the timeline.
- Do not omit impact.
- Do not produce action items without owners unless the user truly has no ownership data.
- Do not confuse mitigation with permanent resolution.