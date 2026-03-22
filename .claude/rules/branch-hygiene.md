---
paths:
  - "**"
---

# Branch Hygiene Rules

## PR Size Limits

- **Single PR should not exceed 30 files or 1500 lines changed**
- If a feature touches more files, split into:
  - PR A: docs only (architecture, handoffs, plans)
  - PR B: code changes (implementation)
  - PR C: tests (if not co-located with code)

## Branch Lifetime

- Feature branches should not accumulate >20 commits before merging
- If a branch has been open >3 days, consider splitting and merging what's ready

## Commit Discipline

- One logical change per commit
- Don't mix docs + code + config in a single commit unless they're tightly coupled
- Commit after every task completion, not in batches

## Why

- 74-file PRs don't get reviewed — they get rubber-stamped
- Long-lived branches accumulate merge conflicts that waste time
- Small PRs merge fast and reduce blast radius of mistakes
