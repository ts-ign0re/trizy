---
name: retro
description: >-
  The weekly meta-loop of trizy. Reads the run journal (`$(git rev-parse --git-common-dir)/trizy/runs/*.jsonl`, local to the clone), CONSTRAINTS.md, the rules
  and the flows, and proposes changes to them as a file the owner approves. It never applies them itself. Use
  on a weekly schedule, after a run of failed gates, or when asked "what keeps going wrong?".
---

# Retro

## Procedure

1. **Read the journal since the last retro.** `$(git rev-parse --git-common-dir)/trizy/runs/*.jsonl` holds one JSON object per line. Group
   the entries by:
   - result;
   - repeated gate findings (the `gates`, `findings` and `corrections` fields);
   - tasks that took more than one attempt.
2. **Read** `.trizy/CONSTRAINTS.md`, `.trizy/rules/*.md`, `.trizy/flows.tsv` and the skills.
3. **For each repeated failure class** (at least 2 occurrences), propose the smallest change that would have
   prevented it, in this order of preference:
   1. a `run` step in a flow (a check a machine does);
   2. a line in `CONSTRAINTS.md`;
   3. a change to a skill or a rule.

   Cite the journal entries (`ts`, `task`) as evidence.
4. **Propose deletions too.** A rule nothing has needed in a month is surface; a constraint that contradicts
   another, or the code, is a defect.
5. **Write the proposal** to `.trizy/local/retro-<date>.md`. Each item gets:
   - the class;
   - the evidence;
   - the exact diff;
   - the expected effect.

   Then stop. The owner approves items one by one; only approved items are applied, by whoever applies them,
   with a `trizy log` entry.

## Never

- Apply a change yourself.
- Remove or weaken a constraint because it is inconvenient. Propose it, with evidence that it is wrong.

## Self-check

- Does every item cite at least two journal entries?
- Is a machine-checkable step preferred over prose wherever one is possible?
