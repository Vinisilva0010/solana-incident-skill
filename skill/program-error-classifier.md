# Program Error Classifier

Use this module when the user provides:

- a custom program error
- an Anchor error
- an unclear execution error
- logs that end with a Solana instruction failure
- a hex error code without a decoded meaning
- a decimal error code without a mapped source
- a transaction where the failing program is known but the exact cause is not

The goal of this module is to decode the error correctly, identify which program emitted it, and translate it into the most likely real-world cause.

## Primary Rule

Never guess the meaning of a custom program error from the number alone.

A correct diagnosis depends on:
- which program emitted the error
- whether the error is Anchor framework, Anchor custom, native Solana, SPL, or protocol-specific
- whether the reported code is hex or decimal
- whether the reported code came from the top-level instruction or a CPI callee

The same visible transaction may contain multiple nested failures. Decode the error from the program that actually emitted it.

## Required Inputs

Collect the following when possible:

- cluster
- transaction signature
- full error text
- full logs
- failing instruction index
- failing program ID
- whether the program is Anchor-based
- source repository, IDL, or docs for the failing program
- whether the code shown is hex or decimal
- whether the issue is reproducible
- whether the failure appeared after a deploy or dependency change

If the program ID is unknown, do not pretend the error is decoded. Ask for the program ID or full logs first.

## Error Families

Classify the error into one of these families before interpreting it.

### 1. Anchor custom errors

Anchor documents that custom user-defined errors start at code 6000, with the offset defined by the framework, so errors in the 6xxx range often map to entries in the program's custom error enum rather than to generic runtime failures. Metaplex also notes that 6xxx errors are commonly Anchor custom errors and can often be resolved by locating the program's error definitions and matching the offset within the list.

Interpretation rule:
- if the decoded decimal code is 6000 or above
- and the failing program is Anchor-based
- first search for the program's custom error enum
- do not map it to a native Solana error prematurely

### 2. Anchor framework / account validation errors

Some errors come from Anchor's internal account validation layer rather than business logic. These often point to missing accounts, ownership mismatch, signer mismatch, PDA seed mismatch, deserialization issues, or constraint violations.

Interpretation rule:
- if the logs show account constraint language
- or the error appears before business logic logs
- suspect account validation first

### 3. Native Solana or SPL program errors

If the failing program is a native program or SPL program, the code must be interpreted relative to that program's own error definitions. Generic messages like insufficient funds, invalid account owner, or invalid instruction data may come from standard program logic rather than the application layer .

Interpretation rule:
- determine which program actually emitted the error
- then map against that program's documented errors

### 4. Protocol-specific custom errors

Many protocols define their own custom error enums. A code like `0x179d` is just a number until tied to the program's source, IDL, SDK, or docs; Stack Overflow guidance correctly notes that such codes often correspond to a program-specific enum variant in `error.rs` or equivalent definitions.

Interpretation rule:
- no source or docs means no confident decode
- at best, provide ranked hypotheses from surrounding logs

## Decoding Workflow

Follow this sequence.

### Step 1 — Identify the emitting program

Ask:
- which program returned the final meaningful error?
- was it the top-level instruction program or a CPI callee?
- do the logs show nested invoke depth?

Do not decode an error against the wrong program.

### Step 2 — Normalize the error code

Ask:
- is the code shown in hex, like `0x1770`?
- or decimal, like `6000`?
- or was only a human-readable phrase returned?

If hex:
- convert it to decimal before reasoning about Anchor ranges or enum offsets

Example:
- `0x1770` = `6000`
- that strongly suggests the first custom Anchor error for an Anchor-based program

### Step 3 — Determine the error family

Choose one:
- Anchor custom
- Anchor framework / constraint
- native Solana
- SPL program
- protocol-specific custom
- unknown family

### Step 4 — Find the source of truth

Preferred order:
1. program source code
2. `error.rs` or equivalent error enum
3. generated IDL
4. official docs
5. SDK helpers
6. reliable explorer decoding
7. community answers as last resort

If no source of truth exists, say so clearly.

### Step 5 — Translate the code into the actual likely bug class

After decoding the label, translate it into operational meaning.

Examples:
- ownership mismatch error → account passed belongs to the wrong program
- signer constraint error → missing authority or wrong wallet signs
- PDA mismatch → wrong seeds, bump, derivation order, or program ID
- slippage-related error → stale quote, stale route, or threshold too tight
- arithmetic / bounds error → invalid inputs, stale assumptions, or invariant breach

The decoded string is not the final answer. It must be converted into a concrete engineering hypothesis.

## Fast Heuristics

Use these heuristics carefully.

### If the code decodes to 6000 exactly

For an Anchor-based program, this is often the first custom error in the user-defined error enum because Anchor custom errors begin at 6000. Do not infer what that first error means until you inspect the actual program's custom error definitions.

### If the error mentions ownership

This often indicates the wrong account was passed, the account belongs to a different program than expected, or the client is targeting the wrong deployed program ID. A common example discussed publicly is an ownership error caused by mismatched `declare_id!` / deployed program configuration.

### If the error appears before any business-logic logs

This raises suspicion for:
- account constraint failure
- account deserialization failure
- signer mismatch
- PDA mismatch
- account ownership mismatch

### If the error appears after several nested invokes

This raises suspicion for:
- CPI callee failure
- external protocol assumption drift
- token-program mismatch
- downstream account state mismatch

## What to Ask Next

After initial classification, ask the smallest number of high-value questions:

- What is the failing program ID?
- Is the program Anchor-based?
- Do you have the source repo or IDL?
- What is the exact error string and code?
- What logs appear immediately before the failure?
- Did this start after a deploy or SDK bump?
- Are you sure the client targets the correct program ID?
- Is the failing account expected to be owned by this program?
- Are PDA seeds and bump derived from the same inputs on client and program?

## Output Format

Use this structure.

### Decoded error
State:
- original code
- normalized decimal form if needed
- emitting program
- decoded family
- decoded meaning, if confirmed

### Confidence
Choose one:
- confirmed by source
- strongly likely from logs + program family
- tentative hypothesis
- insufficient evidence

### Most likely engineering causes
Rank 2 to 4 likely bug classes, not just the label.

### What to verify next
Give the smallest checks that confirm or eliminate the top hypothesis.

### Escalation
Route if needed:
- `tx-failure-triage.md`
- `cpi-debugging.md`
- `release-regression.md`

## Examples

### Example 1 — `custom program error: 0x1770`

- convert hex to decimal → 6000
- if the emitting program is Anchor-based, this strongly suggests the first custom user-defined Anchor error 
- then inspect that program's custom error enum to identify the actual meaning

Do not say "0x1770 means X" unless the program's source confirms it.

### Example 2 — ownership-style error

If the decoded or surrounding context indicates "account is not owned by the executing program," suspect:
- wrong account passed
- wrong program ID targeted by client
- stale IDL / wrong environment config
- account expected to be program-owned but is not

### Example 3 — unknown protocol custom error

If a protocol emits a custom error and no source or docs are available:
- do not fake the decode
- use surrounding logs, failing instruction, and account context to generate ranked hypotheses only 

## Guardrails

- Never decode custom errors without identifying the emitting program.
- Never confuse hex and decimal.
- Never assume every 6xxx code means the same thing across programs.
- Never stop at the label; always translate to the concrete bug class.
- Never claim a protocol-specific decode without source, IDL, docs, or strong explorer evidence.