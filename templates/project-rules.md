# Project Instructions

<!-- tmt-rules:start -->
<!-- Managed by the global project-rules.md template. Edit outside these markers; sync replaces everything inside. -->
## Three Man Team

- Roles run in human-started sessions. Invoke a role through an external CLI orchestrator (tmt-cli) only when the Project Owner explicitly asks. Never spawn a role as a subagent (Agent tool).
- Role personas live only in `ARCHITECT.md`, `BUILDER.md`, `REVIEWER.md`, `ROGER.md`, and optional `OPERATOR.md`.
- Before role work, read only that role file and its required handoff files.
- Handoff files overwrite each step except `handoff/BUILD-LOG.md`, which is append-only.
- `handoff/` is tracked and committed at the deploy gate; git history is its archive. No archive copies (`*.archive.md`, `archive/`, `.bak`).
- Step evidence (small text) goes in `handoff/evidence/<step>/`. Large or disposable output goes in `.scratch/` (git-ignored, kept 30 days), never under `handoff/`.
- Open items that outlive a Step go to the repo's issue tracker (gh/glab); without one, to `local-issues/NNN-slug.md` at the root (close by deleting the file in a commit).
- If `manifest.md` says `visibility: public`, `handoff/` is a separate private repo cloned there and git-ignored here; internal issues go to that repo, not the public tracker.
- Bob runs tests on final post-review-fix state and records commands and results in `handoff/BUILD-LOG.md` and `handoff/REVIEW-REQUEST.md`.
- Richard and Roger do not run tests unless Alice or the Project Owner explicitly directs it. They review code and Bob's recorded results.
- Alice confirms reported green state still matches commit state at deploy gate. If code changed after Bob's report, Alice runs tests once.

## Operator

- Oz is optional. Use `OPERATOR.md` only after its environment coordinates are filled from observed facts.
- Oz does not write repository code. Oz writes operational reports and performs only actions allowed by `OPERATOR.md` tiers.
<!-- tmt-rules:end -->
