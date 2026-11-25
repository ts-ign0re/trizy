# trizy operating contract

Binds every coding agent (Claude Code, Codex, any other) and every person working in this repository. Project
rules outside `.trizy/` may add to it; where they contradict it, the project rule wins and says so.

## Read first, in this order

1. This file.
2. `.trizy/CONSTRAINTS.md`: corrections earned the hard way. They outrank your habits.
3. `.trizy/rules/*.md`: how to work, test, deliver and report.
4. `.trizy/project.conf` and `.trizy/flows.tsv`: this project's settings and the steps of its flows.
5. The project's own docs, contracts and the code the task touches.

Source of truth, highest first: the code and its tests → contracts and schemas → `CONSTRAINTS.md` →
the project's docs → this contract and the rules → the chat. A conflict you cannot resolve is a question for the
owner, never a silent pick.

## Every task, in this order

1. **Classify.** Docs, code, schema or migration, infra, review. If unsure, take the stricter class.
2. **Optimality check.** Load the `optimality-check` skill before you write anything. One line or block per
   **decision** that adds a file, directory, store, mechanism or format, not one per package. Small decisions
   get the one-line form; packages, migrations, new endpoints or entities and infra get the YAML block.
3. **Work.**
   - Small changes go on the current branch.
   - Packages go in their own worktree: `trizy worktree new <branch>`, and remove it right after the merge.
   - Use the `ponytail` skill: the shortest working diff.
4. **Prove.** Run targeted tests while you work, and the flow's run steps before you hand the work over
   (`trizy flow run <flow>`). Heavy commands go through `trizy heavy --`.
5. **Review.** `trizy review prepare`; then someone who did not write the change fills the receipt with the
   `review-gate` skill. A blocker or major finding is fixed in the same package; security, data-loss and
   contract findings are never deferred.
6. **Journal.** `trizy log task="..." result=pass|fail|partial gates="..." corrections="..."`. The journal is local
   (`.git/trizy/runs/`, shared by every worktree, never committed). A push without an entry newer than its commits is refused.
7. **Corrections.** Any correction from a person or a gate becomes one line in `CONSTRAINTS.md` in the same turn.
8. **Report** in the final format below.

## Delivery pipeline (packages)

Claude Code runs it as the `deliver` workflow (`.claude/workflows/deliver.js`). Anyone else (Codex, a person)
walks the same steps by hand:

1. **Plan.** Split the task into packages, each with the files it owns, numeric stop checks (a command plus its
   expected result) and its optimality block. Run the `deliver:plan` flow. The owner approves the plan before
   anything is built.
2. **Build.** One builder per package, each in its own worktree off `deliver/<slug>`. Self-review the diff with
   the `review-gate` skill, then run the `deliver:build` flow.
3. **Gate.** Someone who did not build the package reviews it:
   - with the `review-gate`, `security-reviewer`, `ponytail-review` and `optimality-check` skills;
   - re-runs every check and the `deliver:gate` flow.

   It passes only if no blocker or major finding is open and every check passes. At most 3 attempts, each
   returning the findings with their reasons; then the package is reported failed.
4. **Merge** the accepted packages one by one into `deliver/<slug>`.
5. **Verify.** Run every plan check and the `deliver:verify` flow, log the run (`trizy log`), and tear down every
   test container and worktree the run created.

Merging into the main branch and pushing are the owner's call.

## Never

- Push, merge into the main branch, deploy or delete data without the owner's word.
- Bypass a hook (`--no-verify`) or edit a gate to make it pass.
- Relax a rule in `CONSTRAINTS.md` yourself. Propose the change and let the owner approve it.
- Send code or data to a model or service outside the harness you run in, unless the project allows it.

## Final response format

```text
Changed:   <short list, files>
Verified:  <command>: passed | <command>: skipped, <reason>
Optimality: chose <x>; cheaper <x0/x1> rejected by <constraint> (<source>)
Journal:   <the trizy log line, or why none>
Risks:     <known gaps, or "none known">
```
