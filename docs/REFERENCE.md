# trizy reference

## What `init` installs

- **`.trizy/` (framework):**
  - the contract `AGENTS.trizy.md` and `rules/*.md`;
  - the CLI `bin/trizy`;
  - the git hooks;
  - `VERSION` and `manifest`.
- **`.trizy/` (yours, never touched by `update`):**
  - `project.conf`;
  - `CONSTRAINTS.md`;
  - `flows.tsv`;
  - `review-rules.tsv`.
- **Always created:**
  - the run journal, `.git/trizy/runs/*.jsonl`: local to the clone, shared by its worktrees, never committed;
  - `.trizy/local/`, ignored: logs, receipts, review receipts, tmp.
- **Skills** in `.claude/skills/` (`optimality-check`, `ponytail`, `ponytail-review`, `review-gate`, `security-reviewer`, `retro`),
  linked into `.codex/skills/`.
- **The `deliver` workflow** in `.claude/workflows/`.
- **Entry points:**
  - a marked block in `AGENTS.md` (Codex) and `CLAUDE.md` (Claude Code imports);
  - in ignore mode, `CLAUDE.local.md`, and `AGENTS.md` only if git does not track it.
- **Hooks:** `core.hooksPath` is set to `.trizy/hooks`. If you already use another hooks path (husky…), `init`
  asks (or `--hooks=replace|merge`):
  - **replace** (recommended): `core.hooksPath` becomes `.trizy/hooks`, so the `commit` flow runs your tests and
    linters before every commit; move what your old hooks ran into the `commit`/`push` steps of `flows.tsv`;
  - **merge**: your `pre-commit` and `pre-push` (for husky 9, in `.husky/`) get a line that calls ours.

## Update

```sh
trizy upgrade                   # install the latest release as the user install (--version v0.3.0 for one)
trizy update                    # bring this repository to the installed version (no network)
trizy update --ref v0.3.0       # or straight from TRIZY_SOURCE (project.conf) at a tag
trizy update --from ~/trizy     # or from a checkout
trizy version                   # installed and project versions
```

- **Framework files** are replaced. If you edited one here, your version is kept next to it as `<file>.orig`.
  Lasting changes belong in `CONSTRAINTS.md` or `flows.tsv`.
- **Files the new version drops** are removed, unless you edited them.
- **Project files** are never touched.

## Flows and steps

A flow is an ordered list of steps in `.trizy/flows.tsv`.

- **`run` step:** a shell command. It runs from the repository root through the heavy queue, fails fast, and
  writes its log to a file.
- **`ask` step:** an instruction for the agent or person running the flow.

| Flow | Runs at |
|---|---|
| `commit` | the pre-commit hook, before the review receipt check |
| `push` | the pre-push hook, once per tree (a receipt skips a tree that passed) |
| `deliver:plan`, `deliver:build`, `deliver:gate`, `deliver:verify` | the stages of the `deliver` pipeline |
| your own | `trizy flow run <name>`, or by an agent told to run it |

The main branch is never stored: every command reads it from git (`origin/HEAD`; `init` and `update` refresh it from the
server, so a renamed default branch is followed). `MAIN_BRANCH` in `project.conf` only overrides it.

```sh
trizy flow list
trizy flow add release "ship a version"
trizy step add release notes ask "Write the release notes from the run journal."
trizy step add release tag run "git tag v\$(cat VERSION)"
trizy step add commit lint run "make lint"
trizy step add push test run "make test"
trizy step add deliver:gate api ask "The public API changes only additively."
trizy flow show release
trizy flow run release
trizy step rm release tag
trizy flow rm release
```

## Every task

1. Run the `optimality-check` skill.
2. Do the work, in a worktree for packages (`trizy worktree new`).
3. Run the flow.
4. Get an independent review: `trizy review prepare`, then the reviewer fills the receipt with the `review-gate`
   skill.
5. Journal it: `trizy log task=... result=...`.
6. Write any correction into `CONSTRAINTS.md`.

The details are in `.trizy/AGENTS.trizy.md`.

| Gate | Refuses |
|---|---|
| pre-commit | a failing `commit` step; a commit without an approved receipt for exactly the staged tree (the reviewer is not the author, every file ticked, no open blocker/major) |
| pre-push | a pushed commit that is not this clean checkout's HEAD; commits with no journal entry written after them; a failing `push` step |

Package branches of the `deliver` pipeline (`deliver/*--*`, `REVIEW_EXEMPT_BRANCHES`) skip the receipt: the
pipeline's independent gate reviews them before the merge.

## Tools

```sh
trizy worktree new feat/x [base] | rm feat/x [--force] | sweep | list   # always from the fresh main branch (from git)
trizy heavy -- make test        # machine-wide queue (HEAVY_SLOTS), nested calls pass through
trizy review prepare | verify
trizy log task="..." result=pass|fail|partial [key=value ...]
trizy gate commit | push
```

## The weekly retro

Run the `retro` skill weekly (for example from a scheduled Claude Code routine). It reads the journal and writes
proposed changes to the rules, flows and skills to `.trizy/local/retro-<date>.md`. Nothing is applied
without the owner's approval.
