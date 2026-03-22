---
paths:
  - "docs/**"
  - "*.md"
  - ".claude/**"
---

# Document Size Rules

## Hard Limits

- **Plan section files** (`docs/plans/*/sections/*.md`): ≤300 lines. If a section exceeds this, split by task group.
- **Architecture foundation files** (`docs/architecture/foundations/*.md`): ≤150 lines. Keep decision + rationale + migration path concise.
- **Index/hub files** (`APP_ARCHITECTURE.md`, `plan.md`, `index.md`): ≤150 lines. These are navigation only — detail goes in linked files.
- **Handoff files** (`docs/handoffs/*.md`): ≤100 lines. Focus on what changed and why, not full context.
- **CLAUDE.md**: ≤60 lines. Point to other docs, don't embed.
- **CURRENT.md**: ≤60 lines. Snapshot, not history.

## Self-Contained Rule

Every file that a sub-agent will read independently MUST be self-contained:
- Has its own header explaining what it covers
- Lists file ownership (which files this section creates/modifies)
- States dependencies on prior work
- A reader should never need to open another file to understand this one

## When You Hit the Limit

1. Don't compress — split into sub-files with an index
2. Follow the pattern: `parent.md` (index, ≤150 lines) + `parent/part-N-name.md` (details, ≤300 lines)
3. Each sub-file gets a back-link to the index

## Why

- AI context window is not the bottleneck — **attention** is. After ~300 lines, AI starts missing details.
- Human reviewers won't read 1800-line plans. 300 lines is the upper bound of what gets actually reviewed.
- Split files enable parallel sub-agent execution (each reads only its section).
