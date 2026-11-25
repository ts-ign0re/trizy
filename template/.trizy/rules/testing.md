# Testing rules

- **Real dependencies in tests.** No test doubles for databases, queues, caches or HTTP outside pure unit
  tests; I/O is proven against the real thing on private test infrastructure. External services you do not
  run may be replaced by recorded real responses covering every case.
- **Private test infrastructure.** Each agent gets its own containers (`TEST_INFRA_UP` in `project.conf`).
  Nothing runs on a shared stand, and you tear down what you started.
- **One test run at a time** per shared resource. Never start a run before the previous one, and its child
  processes, is verifiably dead. Fail fast.
- **Targeted while coding, full before handing over.** Run the tests you touched while you work. The
  independent gate runs the full suite.
- **Lock every bug with a test.** Edge cases are covered by unit and integration tests, not by slow
  end-to-end tests.
- **End-to-end tests run before a push** (the `push` flow), with a receipt per tree. A tree that passed is not
  run again.
- **No timing in tests.** Use fake clocks and explicit waits on conditions, never sleeps tuned to a machine.
  Order by a strictly increasing key, never by a timestamp two rows can share.
- **A flaky test is a bug.** Find the cause, fix it and lock it with a test. Re-running until it is green is
  allowed only to unblock unrelated work, and you say so in the report.
- **Formal proofs are optional.** Where an invariant is pure maths (a rounding or allocation formula, a
  limit, a state machine) and `LEAN_AVAILABLE=1`, the `optimality-check` skill describes the proof step. The
  proof sits next to the test and never replaces it.
