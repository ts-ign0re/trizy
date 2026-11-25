# Working rules

- **Stay in the asked scope.** An API plan is not a client migration; a bug fix is not a refactor. When
  something next to the task needs work, list it and leave it.
- **Simplest fix first.** For a bug or a flake, try the cheapest knob first: a limit or a config value. Ask
  before any structural change nobody asked for. A question ("why?") is not an order to build.
- **Never idle on a blocker.** A blocked line never ends the turn while other work is possible. Say what is
  blocked, then do the rest.
- **After a plan is approved, run its packages back to back.** Don't ask "go?" between packages; report once
  at the end. Never stop a running pipeline to re-plan it; let it finish or fail.
- **Plan for parallelism.** Packages run as parallel as their file ownership allows. Give the wall-clock
  estimate before a long run starts.
- **Self-healing over runbooks.** Recovery is automatic: retries, sweeps, quarantine with automatic resend. A
  manual "run this to unblock" step is a defect.
- **Blast radius.** In every design and audit, say what one customer, tenant, user or job can block, starve or
  drop for the others on a shared resource.
- **Bugs a person reports by clicking** you reproduce, fix and test yourself in one thread. Agents are for
  large independent packages.
- **Clean up after yourself.** Test containers, scratch namespaces, worktrees, background processes, browser
  tabs: tear down what you started when the work ends.
- **Never touch the machine's shared toolchain.** No system package manager uninstall, upgrade or relink. Pin
  tools in user-level wrappers.
- **Only the harness you run in.** No external models or agent CLIs for code or review, unless the project
  allows them in `CONSTRAINTS.md`.
