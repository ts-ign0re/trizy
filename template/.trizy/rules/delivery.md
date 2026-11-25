# Delivery rules

- **Every change gets an independent review before its commit.** One review per package, by someone who did
  not write it (`trizy review prepare`, the `review-gate` skill). No extra whole-branch review before the merge.
- **The gate re-runs the checks after its own last edit.** A builder's report is a claim, not evidence.
- **At most 3 gate attempts per package.** Each one returns the findings with their reasons. After the third,
  the package is reported failed, with its worktree left for inspection.
- **Worktrees only through `trizy worktree`.** They start from the freshly fetched main branch and are removed
  right after the merge. `trizy worktree sweep` runs before new work. Never mass-delete branches.
- **Migrations keep the running version working.**
  - Expand, migrate the code, contract in a later release.
  - Every migration is idempotent, so a re-run after a crash passes.
  - A rollback restores code, never data.
- **Before a push, run locally everything CI would run** for the files you touched (the `push` flow). A red CI
  log you are shown means: fix it, re-run the failing jobs locally and, if pushing was asked for, push in the
  same turn.
- **The commit message carries the optimality line** for small changes. Packages carry the block in the plan
  or the merge request.
- **Merging into the main branch, pushing, releasing and deploying are the owner's call**, unless
  `CONSTRAINTS.md` grants them.
