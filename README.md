<p align="center">
  <img src="assets/icon.svg" width="128" alt="trizy">
</p>

<h1 align="center">trizy</h1>

<p align="center"><b>One operating contract for every coding agent in your repository.</b></p>

<p align="center">Plan, build, review, gate and journal: enforced by git hooks, written in POSIX sh, nothing to install but git.</p>

<p align="center">
  <a href="https://github.com/ts-ign0re/trizy/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/ts-ign0re/trizy/ci.yml?branch=main&style=flat-square&label=CI" alt="CI"></a>
  <a href="https://github.com/ts-ign0re/trizy/releases/latest"><img src="https://img.shields.io/github/v/release/ts-ign0re/trizy?style=flat-square" alt="Latest release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/POSIX-sh-4ade80?style=flat-square" alt="POSIX sh">
  <img src="https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey?style=flat-square" alt="Linux | macOS">
</p>

<p align="center">
  <a href="#what-it-is">About</a> ·
  <a href="#installation">Installation</a> ·
  <a href="#quick-start">Quick start</a> ·
  <a href="#documentation">Documentation</a>
</p>

<p align="center">
  <b>English</b> ·
  <a href="docs/README.ru.md">Русский</a> ·
  <a href="docs/README.es.md">Español</a> ·
  <a href="docs/README.zh-CN.md">简体中文</a> ·
  <a href="docs/README.ja.md">日本語</a>
</p>

---

## What it is

trizy is a framework that one repository installs for all of its coding agents (Claude Code, Codex) and all of
its people at once. It decides how a task is chosen, built, reviewed, gated, journalled and delivered, and git
hooks enforce it, so the rules hold even when the agent forgets them.

Agents are good at writing code but bad at discipline. They skip the review, claim a test passed without running
it, over-build, and repeat a mistake someone corrected yesterday. trizy closes those gaps with four things:

1. **A contract in the repository.** `AGENTS.trizy.md`, the rules and `CONSTRAINTS.md` are imported into
   `CLAUDE.md` and `AGENTS.md`. Every correction a person or a gate makes becomes one line in `CONSTRAINTS.md`,
   so no agent repeats it.
2. **Gates that refuse.** The pre-commit hook runs your `commit` flow and refuses a commit without an approved
   review receipt for exactly the staged tree. The reviewer can't be the author, and no blocker or major
   finding can be open. The pre-push hook refuses commits that are not in the run journal.
3. **Optimality per decision.** Every new file, store, mechanism or format needs a line that names the cheaper
   options and the constraint that rules each one out. The `ponytail` skill keeps the diff short.
4. **A memory of runs.** A local journal (`.git/trizy/runs/`, shared by worktrees, never committed). The
   weekly `retro` skill reads it and proposes changes to the rules for the owner to approve.

The name is a nod to TRIZ, the theory of inventive problem solving. Its *ideal final result* is the function
delivered with nothing added, and that is what the optimality check asks of every decision.

## Features

- **Any agent, one contract.** A marked block in `CLAUDE.md` (Claude Code imports) and `AGENTS.md` (Codex).
  The skills are linked into `.codex/skills/` as well.
- **Flows and steps.** `commit`, `push` and your own flows, made of shell `run` steps and `ask` instructions,
  kept in `.trizy/flows.tsv`.
- **Review receipts.** `trizy review prepare` lists every staged file with its review rules, and the
  `review-gate` skill fills the receipt.
- **The `deliver` pipeline.** Turns a task into a plan the owner approves, then into packages. Each package
  is built in its own worktree and passes an independent gate before it is merged into `deliver/<slug>`.
- **Worktrees and a heavy queue.** `trizy worktree new` starts from the freshly fetched main branch.
  `trizy heavy -- make test` queues heavy commands across the whole machine.
- **Plays well with husky.** If another hooks path is set, `init` offers to replace it or to merge with it.
- **Track or ignore.** Commit the agent files for the whole team, or keep them local to your clone.
- **Pinned per repository.** Every project runs its own copy (`.trizy/bin/trizy`), so teammates without
  the install still have working hooks.

## Installation

### Requirements

- **System:** Linux or macOS with `sh`, `git`, `curl` and `tar`. Windows is not supported.
- **Agents:** Claude Code and/or Codex. trizy works with either and with people who use neither.

### Latest release

```sh
curl -fsSL https://raw.githubusercontent.com/ts-ign0re/trizy/main/install.sh | sh
```

The script downloads the latest release, verifies its SHA-256 checksum, puts the kit in
`~/.local/share/trizy` and the `trizy` command in `~/.local/bin`. No sudo. Set `TRIZY_HOME` and `TRIZY_BIN`
to install elsewhere, or `TRIZY_VERSION=v0.3.0` to install a specific release.

### From source

```sh
git clone https://github.com/ts-ign0re/trizy && cd trizy
sh install.sh              # installs this checkout's committed HEAD
```

`sh install.sh --uninstall` removes the command and the install. Repositories keep their own copy.

## Quick start

```sh
cd your-repo
trizy init                 # asks: agent files in git (team-wide) or ignored (local)?
$EDITOR .trizy/flows.tsv   # your lint and test commands as commit and push steps
trizy check
```

| Command | What it does |
|---|---|
| `trizy init [--track\|--ignore] [--hooks=replace\|merge]` | installs into this repository |
| `trizy step add commit lint run "make lint"` | adds a step to a flow |
| `trizy flow run <flow>` | runs a flow's steps, fails fast, logs to files |
| `trizy review prepare \| verify` | the review receipt for the staged tree |
| `trizy log task="..." result=pass` | appends to the run journal |
| `trizy worktree new <branch>` | a worktree from the fresh main branch |
| `trizy heavy -- <cmd>` | runs a heavy command through the machine-wide queue |
| `trizy upgrade`, `trizy update` | installs the latest release, then brings a repository to it |

| Gate | Refuses |
|---|---|
| pre-commit | a failing `commit` step; a commit without an approved receipt for exactly the staged tree |
| pre-push | a pushed commit that is not this clean checkout's HEAD; commits with no journal entry after them; a failing `push` step |

## Documentation

- [Reference](docs/REFERENCE.md): what `init` installs, update, flows and steps, every task, tools, the retro
- [The contract](template/.trizy/AGENTS.trizy.md) and [the rules](template/.trizy/rules/)
- [Changelog](CHANGELOG.md)

Develop: `sh tests/run.sh` runs 99 checks against throwaway repositories, and `TRIZY_SH=dash sh tests/run.sh`
runs the CLI under a strict POSIX shell.

## License

trizy is distributed under the **MIT License**. The full text is in [LICENSE](LICENSE).

The bundled third-party skills and their licenses are listed in
[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
