<p align="center">
  <img src="../assets/icon.svg" width="128" alt="trizy">
</p>

<h1 align="center">trizy</h1>

<p align="center"><b>为仓库里的每一个编程智能体制定同一份工作契约。</b></p>

<p align="center">规划、构建、评审、门禁、记录：由 git 钩子强制执行，用 POSIX sh 编写，除了 git 无需安装任何东西。</p>

<p align="center">
  <a href="https://github.com/ts-ign0re/trizy/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/ts-ign0re/trizy/ci.yml?branch=main&style=flat-square&label=CI" alt="CI"></a>
  <a href="https://github.com/ts-ign0re/trizy/releases/latest"><img src="https://img.shields.io/github/v/release/ts-ign0re/trizy?style=flat-square" alt="Latest release"></a>
  <a href="../LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/POSIX-sh-4ade80?style=flat-square" alt="POSIX sh">
  <img src="https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey?style=flat-square" alt="Linux | macOS">
</p>

<p align="center">
  <a href="#这是什么">简介</a> ·
  <a href="#安装">安装</a> ·
  <a href="#快速开始">快速开始</a> ·
  <a href="#文档">文档</a>
</p>

<p align="center">
  <a href="../README.md">English</a> ·
  <a href="README.ru.md">Русский</a> ·
  <a href="README.es.md">Español</a> ·
  <b>简体中文</b> ·
  <a href="README.ja.md">日本語</a>
</p>

---

## 这是什么

trizy 是一个框架，一个仓库安装一次，就同时作用于它的所有编程智能体（Claude Code、Codex）和所有人员。它规定
任务如何选定、构建、评审、过门禁、记入运行记录并交付，并由 git 钩子强制执行，所以即使智能体忘了规则，规则依然有效。

智能体擅长写代码，却不擅长守纪律。它们会跳过评审，没运行测试就声称测试通过，过度构建，还会重犯别人昨天刚纠正过的
错误。trizy 用四样东西弥补这些缺口：

1. **仓库里的契约。** `AGENTS.trizy.md`、各项规则和 `CONSTRAINTS.md` 被导入 `CLAUDE.md` 和 `AGENTS.md`。
   人或门禁做出的每一次纠正都会成为 `CONSTRAINTS.md` 中的一行，这样就没有智能体会再犯。
2. **会拒绝的门禁。** pre-commit 钩子运行你的 `commit` 流程，如果没有恰好针对已暂存树的已批准评审回执，就拒绝提交。
   评审者不能是作者，也不能有任何未关闭的阻断级或重大问题。pre-push 钩子拒绝不在运行记录中的提交。
3. **每个决策都要论证最优。** 每个新增的文件、存储、机制或格式都需要一行说明，列出更便宜的方案以及排除每个方案的约束。
   `ponytail` 技能让 diff 保持简短。
4. **运行的记忆。** 一份本地运行记录（`.git/trizy/runs/`，所有 worktree 共享，从不提交）。每周运行的 `retro`
   技能读取它，并提出规则修改建议，交由所有者批准。

名字致敬 TRIZ，即发明问题解决理论。它的*最终理想解*是在不增加任何东西的前提下实现功能，而这正是最优性检查对每个
决策的要求。

## 功能

- **任意智能体，同一份契约。** 在 `CLAUDE.md`（Claude Code 导入）和 `AGENTS.md`（Codex）中各放一个带标记的块。
  技能也会链接到 `.codex/skills/`。
- **流程与步骤。** `commit`、`push` 以及你自己的流程，由 shell `run` 步骤和 `ask` 指令组成，保存在
  `.trizy/flows.tsv` 中。
- **评审回执。** `trizy review prepare` 列出每个已暂存文件及其评审规则，由 `review-gate` 技能填写回执。
- **`deliver` 流水线。** 把任务变成由所有者批准的计划，再拆成工作包。每个工作包在自己的 worktree 中构建，并在合并到
  `deliver/<slug>` 之前通过独立门禁。
- **worktree 与重任务队列。** `trizy worktree new` 从刚拉取的主分支开始。`trizy heavy -- make test`
  让重型命令在整台机器范围内排队。
- **与 husky 兼容。** 如果已设置其他钩子路径，`init` 会提议替换它或与之合并。
- **纳入版本控制或忽略。** 可以把智能体文件提交给整个团队，也可以只保留在你自己的克隆里。
- **按仓库固定版本。** 每个项目运行自己的副本（`.trizy/bin/trizy`），因此没有安装 trizy 的队友也有可用的钩子。

## 安装

### 环境要求

- **系统：** 带有 `sh`、`git`、`curl` 和 `tar` 的 Linux 或 macOS。不支持 Windows。
- **智能体：** Claude Code 和/或 Codex。trizy 两者都支持，也适用于两者都不用的人。

### 最新版本

```sh
curl -fsSL https://raw.githubusercontent.com/ts-ign0re/trizy/main/install.sh | sh
```

脚本会下载最新版本，校验其 SHA-256 校验和，把套件放到 `~/.local/share/trizy`，把 `trizy` 命令放到
`~/.local/bin`。无需 sudo。设置 `TRIZY_HOME` 和 `TRIZY_BIN` 可以安装到其他位置，设置
`TRIZY_VERSION=v0.3.0` 可以安装指定版本。

### 从源码安装

```sh
git clone https://github.com/ts-ign0re/trizy && cd trizy
sh install.sh              # installs this checkout's committed HEAD
```

`sh install.sh --uninstall` 会删除命令和安装内容。各仓库保留自己的副本。

## 快速开始

```sh
cd your-repo
trizy init                 # asks: agent files in git (team-wide) or ignored (local)?
$EDITOR .trizy/flows.tsv   # your lint and test commands as commit and push steps
trizy check
```

| 命令 | 作用 |
|---|---|
| `trizy init [--track\|--ignore] [--hooks=replace\|merge]` | 安装到当前仓库 |
| `trizy step add commit lint run "make lint"` | 向流程添加一个步骤 |
| `trizy flow run <flow>` | 运行流程的各个步骤，遇错即停，日志写入文件 |
| `trizy review prepare \| verify` | 已暂存树的评审回执 |
| `trizy log task="..." result=pass` | 向运行记录追加一条记录 |
| `trizy worktree new <branch>` | 基于最新主分支创建 worktree |
| `trizy heavy -- <cmd>` | 通过整台机器共享的队列运行重型命令 |
| `trizy upgrade`, `trizy update` | 安装最新版本，然后把仓库更新到该版本 |

| 门禁 | 拒绝 |
|---|---|
| pre-commit | 失败的 `commit` 步骤；没有恰好针对已暂存树的已批准回执的提交 |
| pre-push | 不是当前干净检出的 HEAD 的推送提交；之后没有运行记录条目的提交；失败的 `push` 步骤 |

## 文档

文档为英文。

- [参考手册](REFERENCE.md)：`init` 安装了什么、更新、流程与步骤、每个任务的流程、工具、复盘
- [契约](../template/.trizy/AGENTS.trizy.md)与[规则](../template/.trizy/rules/)
- [更新日志](../CHANGELOG.md)

开发：`sh tests/run.sh` 在一次性仓库上运行 99 项检查，`TRIZY_SH=dash sh tests/run.sh` 在严格的 POSIX shell
下运行 CLI。

## 许可证

trizy 采用 **MIT 许可证**分发。全文见 [LICENSE](../LICENSE)。

随附的第三方技能及其许可证列于 [THIRD-PARTY-NOTICES.md](../THIRD-PARTY-NOTICES.md)。
