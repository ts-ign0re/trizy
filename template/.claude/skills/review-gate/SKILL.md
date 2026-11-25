---
name: review-gate
description: >-
  The independent review every change gets before its commit, run with trizy's built-in review receipt, no
  external tools. Use for a package's gate in the deliver pipeline, for any staged change before a commit, and
  for a builder's self-review. The reviewer reads every staged file against the project's review rules,
  verifies each finding at HEAD and fills the receipt; the pre-commit hook refuses a commit without an approved
  receipt for exactly that tree.
---

# Review gate

## Procedure

1. **Prepare.** The author stages the change and runs `trizy review prepare`. It prints the receipt path,
   `.trizy/local/reviews/<tree>.md`, which lists every staged file with the rule ids of
   `.trizy/review-rules.tsv` that match it.
2. **Review every file.**
   - Read the diff (`git diff --cached -- <file>`; new files whole) and enough of the surrounding code to judge
     it.
   - Apply the listed rules, then the lenses of the skills your stage requires: `security-reviewer`,
     `ponytail-review` and `optimality-check`. For the last: does every new file, directory, store, mechanism or
     format in the diff have its own optimality line, and does each one hold?
   - Look for classes of defects, not single lines: every place the same mistake occurs is one finding.
3. **Verify each finding at HEAD** before you write it down. A finding you could not reproduce is dropped.
4. **Fill the receipt.**
   - `reviewer:` your name or role. It must differ from the author's.
   - Tick every file: `- [x]`.
   - One line per finding: `- major | path:line | the defect and its fix | open`.
   - `decision: approve` only if no blocker or major finding is open. Otherwise `reject`; the author fixes the
     findings, marks them `fixed` and re-stages.
5. **A re-staged tree is a new tree.** The author runs `trizy review prepare` again and the reviewer re-reviews
   only what changed.

## Severity

- **blocker:** wrong results, data loss, a security hole, a broken contract, a failing check.
- **major:** a missing test for changed behaviour, an unhandled error path, a resource leak, a decision without
  its optimality line or with an unproven one, or an abstraction or dependency nobody asked for that adds risk.
- **minor:** everything else worth saying. Drop pure style nits.

Security, data-loss and contract findings are at least major, and are fixed in the same package.

## Self-check before you sign

- Is every file ticked because I read it, not because it looked small?
- Did I re-run the checks myself, after the last edit?
- Would the finding still hold if I checked it out fresh?
