---
name: optimality-check
description: >-
  Mandatory for every task by every team member, human or agent: plan, code, migration, infra, docs, review.
  Proves a choice is the cheapest one that satisfies every hard constraint by naming the binding constraint.
  Write the objective f and the constraints Ф from files in this repository, list cheaper candidates (nothing to
  build, an existing part does it, a config knob), and reject each one with the constraint it breaks plus
  evidence. Also the answer to "prove this is optimal", "why not simpler?" or "почему так?".
---

# Optimality check

    x*  = argmin f(x)   subject to   Ф(x) ≥ 0

The proof is the binding constraint, written down. Formal maths is an optional extra (step 8), never the
default.

## Scope

One line or block per **decision**, not per package. A decision is anything that adds a file, a directory, a
store, a mechanism, a format or a dependency. A package of ten files carries a line for each such choice: where
data lives, what is committed, how two copies merge, what runs where. A single block for a whole package lets
the small choices through unchecked; a journal committed to git, which conflicts on every merge, got through that
way.

How much you write per decision depends on its size:

- **Small changes** (one file, no new entity, endpoint, table or dependency) need one line, in the commit body or
  the final answer: `optimality: chose <x>; cheaper <x0/x1> rejected by <constraint> (<source>)`.
- **Everything else** (packages, migrations, new endpoints or entities, infra, a choice between
  implementations) needs the YAML block below.
- **Reviews** check the author's lines and blocks. A new file, directory, store, mechanism or format with no line
  of its own, or a cheaper candidate that breaks no sourced constraint, is a major finding.

## The terms

- **x** is a concrete change: a plan, a diff or a config value.
- **f** is compared lexicographically; an earlier term wins:
  1. **People's time.** Questions, waits on gates, manual steps, recovery commands. Self-healing beats a
     runbook.
  2. **New surface.** Entities, endpoints, tables, services, files, lines, dependencies. Deleting is negative
     surface.
  3. **Run cost.** Latency or throughput on hot paths, CI minutes, infrastructure.
- **Ф** comes only from these sources; cite the file:
  - the code and its tests;
  - contracts and schemas;
  - `.trizy/CONSTRAINTS.md`, `.trizy/rules/*.md` and `.trizy/flows.tsv`;
  - the project's docs;
  - owner decisions quoted in the task or the approved plan, with their date.

  A constraint you cannot point to is an **assumption**. List it and ask; never use it to reject a cheaper
  candidate.

## Procedure

1. **Say which term of f decides this case.**
2. **List the Ф that apply**, each with its source.
3. **Write the candidates from cheapest to dearest.** Always include:
   - `x0`: the problem goes away. An existing part of the system already does it, or a reformulated task no
     longer needs it. The best invention is the one that does not exist.
   - `x1`: the cheapest knob. A limit, a config value, a setting.
   - `x2…`: real code, smallest diff first.
4. **Resolve trade-offs.** If A beats B on one term and loses on another, look for a C that is no worse than
   either on any term before you pick a side. A and B are then dominated and dropped.
5. **Check whether a harmful effect can do the job.** An existing side effect, such as a retry, a sweep, a
   reconnect or a replay, may already deliver the wanted behaviour under other conditions.
6. **Pick the first candidate, in f order, that satisfies every Ф.** The constraint that rejected the candidate
   just before it is the **binding constraint**. Name it.
7. **Prove it.** For each rejected cheaper candidate give one line: the violated constraint, its source, and a
   check under a minute that shows it (a command, a test name, a file:line).
8. **Formal proof (optional).** Do this only when the core of the change is a pure-maths invariant (a rounding
   or allocation formula, a limit, a state machine's reachable states) and `LEAN_AVAILABLE=1` in
   `.trizy/project.conf`.
   - Formalise the invariant in Lean and finish the proof with no `sorry`.
   - Keep it next to the test. It adds to the test, never replaces it.
   - If Lean is not available, say "formal proof: skipped, Lean not installed". That is not a failure.

## Stop condition

You are done when all of these hold:

- every candidate cheaper than the pick has a violated constraint with evidence;
- no reason is an adjective ("cleaner", "more robust", "best practice");
- no assumption was used to reject a candidate;
- the pick names its binding constraint.

Otherwise either the pick is not optimal (take the cheaper candidate) or a constraint is missing (ask). Never
relax a constraint yourself.

## Output

```yaml
optimality:
  f_term: people_time | surface | run_cost
  constraints:
    - {id: C1, rule: "<one line>", source: "<file[:line] | owner YYYY-MM-DD>"}
  candidates:                       # cheapest first
    - {id: x0, what: "<one line>", verdict: rejected, violates: C1, evidence: "<command | test | file:line>"}
    - {id: x1, what: "<one line>", verdict: chosen}
  binding_constraint: C1
  formal_proof: none | "<file>" | "skipped: <reason>"
  assumptions: []                   # anything unsourced, to ask about
```

## Example

The question: an API gets a per-client request limit. Why not none, and why not a new token-bucket service?

- **x0, no limit.** Rejected: a rule in `CONSTRAINTS.md` says one client may not starve the others on a shared
  process.
- **x1, reuse the fixed-window limiter the service already has for another route.** Chosen.
- **x2, a new token-bucket service.** Rejected: more surface than x1, and no constraint that x1 fails to meet.

Binding constraint: the shared-process rule. The proof is the limiter's test for the new route.

## Self-check before you hand in

- Does every new file, directory, store, mechanism and format in my diff have its own line?
- Did I name x0 even though it looked impossible?
- Is every `violates` a constraint with a source?
- Is `assumptions` empty, or did I ask about each one?
