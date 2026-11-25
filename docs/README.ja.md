<p align="center">
  <img src="../assets/icon.svg" width="128" alt="trizy">
</p>

<h1 align="center">trizy</h1>

<p align="center"><b>リポジトリのすべてのコーディングエージェントに、ひとつの運用契約を。</b></p>

<p align="center">計画、構築、レビュー、ゲート、ジャーナル。git フックで強制され、POSIX sh で書かれ、git 以外に何もインストール不要です。</p>

<p align="center">
  <a href="https://github.com/ts-ign0re/trizy/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/ts-ign0re/trizy/ci.yml?branch=main&style=flat-square&label=CI" alt="CI"></a>
  <a href="https://github.com/ts-ign0re/trizy/releases/latest"><img src="https://img.shields.io/github/v/release/ts-ign0re/trizy?style=flat-square" alt="Latest release"></a>
  <a href="../LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/POSIX-sh-4ade80?style=flat-square" alt="POSIX sh">
  <img src="https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey?style=flat-square" alt="Linux | macOS">
</p>

<p align="center">
  <a href="#trizy-とは">概要</a> ·
  <a href="#インストール">インストール</a> ·
  <a href="#クイックスタート">クイックスタート</a> ·
  <a href="#ドキュメント">ドキュメント</a>
</p>

<p align="center">
  <a href="../README.md">English</a> ·
  <a href="README.ru.md">Русский</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <b>日本語</b>
</p>

---

## trizy とは

trizy は、リポジトリが一度インストールするだけで、そのすべてのコーディングエージェント（Claude Code、Codex）と
すべての人に同時に適用されるフレームワークです。タスクをどう選び、構築し、レビューし、ゲートを通し、ジャーナルに
記録し、届けるかを定め、それを git フックが強制します。そのため、エージェントがルールを忘れてもルールは守られます。

エージェントはコードを書くのは得意でも、規律を守るのは苦手です。レビューを飛ばし、テストを実行せずに通ったと主張し、
作り込みすぎ、昨日誰かが訂正したミスを繰り返します。trizy は次の 4 つでこの穴をふさぎます。

1. **リポジトリ内の契約。** `AGENTS.trizy.md`、ルール、`CONSTRAINTS.md` が `CLAUDE.md` と `AGENTS.md` に
   インポートされます。人やゲートによる訂正はすべて `CONSTRAINTS.md` の 1 行になり、どのエージェントも同じミスを
   繰り返しません。
2. **拒否するゲート。** pre-commit フックは `commit` フローを実行し、ステージされたツリーにぴったり対応する
   承認済みレビューレシートのないコミットを拒否します。レビュアーは作成者であってはならず、ブロッカーまたはメジャーの
   指摘が未解決のまま残っていてもいけません。pre-push フックは、実行ジャーナルにないコミットを拒否します。
3. **決定ごとの最適性。** 新しいファイル、ストア、仕組み、フォーマットにはそれぞれ、より安価な選択肢と、それぞれを
   除外する制約を挙げた 1 行が必要です。`ponytail` スキルが diff を短く保ちます。
4. **実行の記憶。** ローカルのジャーナル（`.git/trizy/runs/`。すべての worktree で共有され、コミットはされません）。
   毎週の `retro` スキルがこれを読み、オーナーの承認を得るためのルール変更を提案します。

名前は TRIZ（発明的問題解決理論）にちなんでいます。その*理想的最終結果*とは、何も追加せずに機能が実現されることであり、
最適性チェックがすべての決定に求めるのもまさにそれです。

## 機能

- **どのエージェントにも、ひとつの契約。** `CLAUDE.md`（Claude Code がインポート）と `AGENTS.md`（Codex）に
  マーク付きのブロックを置きます。スキルは `.codex/skills/` にもリンクされます。
- **フローとステップ。** `commit`、`push`、独自のフローは、シェルの `run` ステップと `ask` 指示で構成され、
  `.trizy/flows.tsv` に保存されます。
- **レビューレシート。** `trizy review prepare` がステージされたすべてのファイルをレビュールール付きで一覧にし、
  `review-gate` スキルがレシートを記入します。
- **`deliver` パイプライン。** タスクをオーナーが承認する計画に変え、さらにパッケージに分けます。各パッケージは
  専用の worktree で構築され、`deliver/<slug>` にマージされる前に独立したゲートを通過します。
- **worktree と重いコマンドのキュー。** `trizy worktree new` は取得したばかりのメインブランチから始まります。
  `trizy heavy -- make test` は重いコマンドをマシン全体でキューに入れます。
- **husky と共存。** 別のフックパスが設定されている場合、`init` はそれを置き換えるか、統合するかを提案します。
- **管理するか、無視するか。** エージェント用ファイルをチーム全体向けにコミットすることも、自分のクローンだけに
  ローカルで置いておくこともできます。
- **リポジトリごとに固定。** 各プロジェクトは自分のコピー（`.trizy/bin/trizy`）を実行するため、trizy を
  インストールしていないチームメイトでもフックが動きます。

## インストール

### 必要なもの

- **システム:** `sh`、`git`、`curl`、`tar` がある Linux または macOS。Windows はサポートしていません。
- **エージェント:** Claude Code と Codex のどちらか、または両方。trizy はどちらでも動き、どちらも使わない人にも
  使えます。

### 最新リリース

```sh
curl -fsSL https://raw.githubusercontent.com/ts-ign0re/trizy/main/install.sh | sh
```

スクリプトは最新リリースをダウンロードし、SHA-256 チェックサムを検証して、キットを `~/.local/share/trizy` に、
`trizy` コマンドを `~/.local/bin` に置きます。sudo は不要です。別の場所にインストールするには `TRIZY_HOME` と
`TRIZY_BIN` を、特定のリリースをインストールするには `TRIZY_VERSION=v0.3.0` を設定します。

### ソースから

```sh
git clone https://github.com/ts-ign0re/trizy && cd trizy
sh install.sh              # installs this checkout's committed HEAD
```

`sh install.sh --uninstall` はコマンドとインストールを削除します。各リポジトリは自分のコピーを保持します。

## クイックスタート

```sh
cd your-repo
trizy init                 # asks: agent files in git (team-wide) or ignored (local)?
$EDITOR .trizy/flows.tsv   # your lint and test commands as commit and push steps
trizy check
```

| コマンド | 内容 |
|---|---|
| `trizy init [--track\|--ignore] [--hooks=replace\|merge]` | このリポジトリにインストールする |
| `trizy step add commit lint run "make lint"` | フローにステップを追加する |
| `trizy flow run <flow>` | フローのステップを実行し、最初の失敗で止まり、ログをファイルに書く |
| `trizy review prepare \| verify` | ステージされたツリーのレビューレシート |
| `trizy log task="..." result=pass` | 実行ジャーナルに追記する |
| `trizy worktree new <branch>` | 最新のメインブランチから worktree を作る |
| `trizy heavy -- <cmd>` | 重いコマンドをマシン全体のキュー経由で実行する |
| `trizy upgrade`, `trizy update` | 最新リリースをインストールし、リポジトリをそのリリースに更新する |

| ゲート | 拒否するもの |
|---|---|
| pre-commit | 失敗した `commit` ステップ。ステージされたツリーにぴったり対応する承認済みレシートのないコミット |
| pre-push | このクリーンなチェックアウトの HEAD ではないプッシュ対象のコミット。後にジャーナルエントリがないコミット。失敗した `push` ステップ |

## ドキュメント

ドキュメントは英語です。

- [リファレンス](REFERENCE.md): `init` がインストールするもの、更新、フローとステップ、すべてのタスクの手順、
  ツール、レトロ
- [契約](../template/.trizy/AGENTS.trizy.md)と[ルール](../template/.trizy/rules/)
- [変更履歴](../CHANGELOG.md)

開発: `sh tests/run.sh` は使い捨てのリポジトリに対して 99 個のチェックを実行し、`TRIZY_SH=dash sh tests/run.sh`
は厳格な POSIX シェルで CLI を実行します。

## ライセンス

trizy は **MIT ライセンス**で配布されます。全文は [LICENSE](../LICENSE) にあります。

同梱のサードパーティ製スキルとそのライセンスは [THIRD-PARTY-NOTICES.md](../THIRD-PARTY-NOTICES.md) に記載しています。
