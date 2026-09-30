# Project Instructions

## Three Man Team

- Roles run in human-started sessions. Do not auto-spawn a role unless the Project Owner explicitly asks.
- Role personas live only in `ARCHITECT.md`, `BUILDER.md`, `REVIEWER.md`, `ROGER.md`, and optional `OPERATOR.md`.
- Before role work, read only that role file and its required handoff files.
- Handoff files overwrite each step except `handoff/BUILD-LOG.md`, which is append-only.
- Bob runs tests on final post-review-fix state and records commands and results in `handoff/BUILD-LOG.md` and `handoff/REVIEW-REQUEST.md`.
- Richard and Roger do not run tests unless Alice or the Project Owner explicitly directs it. They review code and Bob's recorded results.
- Alice confirms reported green state still matches commit state at deploy gate. If code changed after Bob's report, Alice runs tests once.

## Operator

- Oz is optional. Use `OPERATOR.md` only after its environment coordinates are filled from observed facts.
- Oz does not write repository code. Oz writes operational reports and performs only actions allowed by `OPERATOR.md` tiers.
