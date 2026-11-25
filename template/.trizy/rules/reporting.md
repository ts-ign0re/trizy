# Reporting rules

- **Short status.** A status message is 1–3 lines of facts, no narration of options you will not pursue.
- **Say what is happening on long runs.** One line when a run starts, with its estimate, and one at each
  milestone, before anyone has to ask.
- **Logs go to files; the screen gets the summary and the failures.** Grep narrowly: the failing test's
  name and its assertion, not the whole log.
- **Watch long runs.** Every background run longer than a few minutes gets a watcher that reports progress,
  every failure state and more than 15 minutes of log silence. A step that writes nothing until it ends
  needs a check of its process, not only of its log.
- **Report faithfully.**
  - A failing check is reported with its output.
  - A skipped check is reported as skipped, with the reason.
  - A green result is stated plainly, without hedging.
  - Never claim success for a check you did not run.
  - A wrapper's exit code is not the command's: read the command's own status.
- **The final answer follows the format in `AGENTS.trizy.md`.** It includes the optimality line and the journal
  line.
