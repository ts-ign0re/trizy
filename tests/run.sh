#!/bin/sh
# trizy self-test: every command against throwaway repositories. POSIX sh + git.
# Run: sh tests/run.sh   (TRIZY_SH=dash sh tests/run.sh runs the CLI under another shell; hooks use /bin/sh)
set -u
KITSRC=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d)
export TRIZY_HEAVY_DIR="$T/heavy" GIT_CONFIG_GLOBAL="$T/gitconfig" GIT_CONFIG_NOSYSTEM=1
unset TRIZY_HEAVY_HELD # run from a flow, the suite must still exercise the queue itself
git config --global user.name tester
git config --global user.email tester@example.invalid
git config --global init.defaultBranch main
fails=0 n=0
ok() { n=$((n + 1)); if eval "$2" >/dev/null 2>&1; then printf 'ok   %s\n' "$1"; else printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); fi; }
new_repo() { d="$T/$1"; mkdir -p "$d" && cd "$d" && git init -q && printf 'x\n' >README && git add README && git commit -qm init; }
trizy() { ${TRIZY_SH:-} ./.trizy/bin/trizy "$@"; }
approve() { # fill the staged tree's receipt as an independent reviewer
  trizy review prepare >/dev/null
  r=.trizy/local/reviews/$(git write-tree).md
  sed -i.bak -e 's/^reviewer: *$/reviewer: gate/' -e 's/^decision: pending/decision: approve/' -e 's/^- \[ \]/- [x]/' "$r"
}

# --- init, track mode -----------------------------------------------------------------------------
new_repo track
printf '# Project rules\n' >AGENTS.md
${TRIZY_SH:-} "$KITSRC/template/.trizy/bin/trizy" init --track >"$T/init.log" 2>&1
ok "init --track installs the CLI" '[ -x .trizy/bin/trizy ]'
ok "init creates ignored local dirs" '[ -d .trizy/local/logs ] && [ -d .trizy/local/receipts ] && git check-ignore -q .trizy/local/x'
J=.git/trizy/runs
ok "init creates the local run journal in the common git dir" '[ -d "$J" ] && [ ! -e .trizy/runs ]'
ok "init keeps the project text of AGENTS.md" 'grep -q "^# Project rules" AGENTS.md && grep -q "trizy:begin" AGENTS.md'
ok "init writes the CLAUDE.md imports" 'grep -q "^@.trizy/AGENTS.trizy.md" CLAUDE.md && grep -q "^@.trizy/rules/testing.md" CLAUDE.md'
ok "init links the skills for Codex" '[ -L .codex/skills/optimality-check ] && [ -f .codex/skills/optimality-check/SKILL.md ]'
ok "init sets the hooks path" '[ "$(git config core.hooksPath)" = .trizy/hooks ]'
ok "init records the mode" 'grep -q "^TRIZY_GIT=track" .trizy/project.conf'
ok "track mode does not ignore the kit" '! git check-ignore -q .trizy/project.conf'
ok "check passes" 'trizy check'
${TRIZY_SH:-} "$KITSRC/template/.trizy/bin/trizy" init --track >/dev/null 2>&1
ok "a second init is idempotent (one block each)" '[ "$(grep -c "trizy:begin" AGENTS.md)" = 1 ] && [ "$(grep -c "trizy:begin" CLAUDE.md)" = 1 ] && [ "$(grep -cxF "/.trizy/local/" .gitignore)" = 1 ]'
ok "init without a mode and without a terminal refuses" '! ${TRIZY_SH:-} "$KITSRC/template/.trizy/bin/trizy" init </dev/null'

# --- init over a foreign hooks path ---------------------------------------------------------------
new_repo merge
mkdir -p .githooks && printf '#!/bin/sh\necho mine >>"$PWD/mine.log"\nexit 0' >.githooks/pre-commit && chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
${TRIZY_SH:-} "$KITSRC/template/.trizy/bin/trizy" init --track --hooks=merge >/dev/null 2>&1
ok "merge keeps the foreign hooks path" '[ "$(git config core.hooksPath)" = .githooks ]'
ok "merge calls our hooks from the foreign ones" 'grep -q ".trizy/hooks/pre-commit" .githooks/pre-commit && [ -x .githooks/pre-push ] && grep -q ".trizy/hooks/pre-push" .githooks/pre-push'
${TRIZY_SH:-} "$KITSRC/template/.trizy/bin/trizy" init --track --hooks=merge >/dev/null 2>&1
ok "a second merge adds no second call" '[ "$(grep -c trizy .githooks/pre-commit)" = 1 ] && [ "$(grep -c trizy .githooks/pre-push)" = 1 ]'
${TRIZY_SH:-} "$KITSRC/template/.trizy/bin/trizy" init --track >"$T/merge2.log" 2>&1
ok "init over merged hooks says nothing about them" '! grep -q hooksPath "$T/merge2.log"'
ok "check accepts merged hooks" '! trizy check 2>&1 | grep -q hooksPath'
git config core.hooksPath .other
ok "check flags a foreign hooks path that does not call ours" 'trizy check 2>&1 | grep -q "core.hooksPath is .other"'
git config core.hooksPath .githooks
git add -A >/dev/null
ok "a merged hook runs our gate despite a trailing exit, and keeps the project hook" '! git commit -qm kit && [ ! -e mine.log ] && grep -q "^exit 0$" .githooks/pre-commit && sh .githooks/pre-push origin x </dev/null'
mv .trizy .trizy.away
ok "a merged hook skips our gate in a checkout without the kit" 'sh .githooks/pre-commit && grep -q mine mine.log'
mv .trizy.away .trizy
new_repo husky
git config core.hooksPath .husky/_/
${TRIZY_SH:-} "$KITSRC/template/.trizy/bin/trizy" init --track --hooks=merge >/dev/null 2>&1
ok "merge over husky 9 writes the hooks in .husky, not .husky/_" 'grep -q ".trizy/hooks/pre-commit" .husky/pre-commit && [ ! -e .husky/_/pre-commit ]'
new_repo replace
git config core.hooksPath .husky/_
${TRIZY_SH:-} "$KITSRC/template/.trizy/bin/trizy" init --track --hooks=replace >/dev/null 2>&1
ok "replace sets our hooks path" '[ "$(git config core.hooksPath)" = .trizy/hooks ]'
ok "merge outside the repository is refused" 'new_repo abs && git config core.hooksPath "$T/global-hooks" && ! ${TRIZY_SH:-} "$KITSRC/template/.trizy/bin/trizy" init --track --hooks=merge && [ ! -e "$T/global-hooks" ]'
cd "$T/track"

# --- flows and steps ------------------------------------------------------------------------------
trizy step add commit lint run 'echo linted >"$PWD/.trizy/local/tmp/linted"' >/dev/null
ok "step add appends a run step" 'grep -q "^commit	lint	run	" .trizy/flows.tsv'
ok "a duplicate step is refused" '! trizy step add commit lint run true'
ok "a step on an unknown flow is refused" '! trizy step add nope x run true'
trizy flow add release "ship a version" >/dev/null
trizy step add release notes ask "Write the notes from the journal." >/dev/null
trizy step add release tag run 'echo tagged' >/dev/null
ok "flow list shows the custom flow" 'trizy flow list | grep -q "^release .*custom"'
ok "flow show lists steps in order" 'trizy flow show release | head -1 | grep -q "1. notes \[ask\]"'
ok "flow run runs run steps and prints ask steps" 'trizy flow run release | grep -q "release/tag ok"'
trizy step add release broken run 'echo "error: boom"; exit 3' >/dev/null
ok "flow run fails fast with the error line" 'out=$(trizy flow run release 2>&1); [ $? -ne 0 ] && printf "%s" "$out" | grep -q "error: boom"'
trizy step rm release broken >/dev/null
ok "step rm removes the step" '! grep -q "^release	broken" .trizy/flows.tsv'
ok "a built-in flow cannot be removed" '! trizy flow rm commit'
trizy flow rm release >/dev/null
ok "flow rm removes the flow and its steps" '! grep -q "^release" .trizy/flows.tsv'

# --- review receipt and the commit gate -----------------------------------------------------------
git add -A >/dev/null
ok "commit without a receipt is refused" '! git commit -qm "kit"'
ok "the commit flow ran before the review check" '[ -f .trizy/local/tmp/linted ]'
trizy review prepare >/dev/null
r=.trizy/local/reviews/$(git write-tree).md
ok "prepare lists every staged file with its rules" 'grep -q "^- \[ \] A .trizy/bin/trizy: all" "$r"'
ok "an unfilled receipt is refused" '! trizy review verify'
sed -i.bak -e 's/^reviewer: *$/reviewer: tester/' -e 's/^decision: pending/decision: approve/' -e 's/^- \[ \]/- [x]/' "$r"
ok "the author cannot review their own change" '! trizy review verify'
sed -i.bak -e 's/^reviewer: tester/reviewer: gate/' "$r"
printf -- '- major | a:1 | leak | open\n' >>"$r"
ok "an open major finding is refused" '! trizy review verify'
sed -i.bak -e 's/| open$/| fixed/' "$r"
ok "a filled receipt passes" 'trizy review verify'
ok "the commit passes with the receipt" 'git commit -qm "chore: trizy"'
trizy log task="local entry" result=pass >/dev/null
ok "the journal never shows up in git status" '[ -z "$(git status --porcelain)" ]'
git checkout -q -b deliver/demo--pkg
printf 'pkg\n' >pkg.txt && git add pkg.txt
ok "a deliver package branch commits without a receipt" 'git commit -qm "feat: pkg"'
git checkout -q main && git merge -q --no-ff deliver/demo--pkg -m "merge pkg" && git branch -qD deliver/demo--pkg

# --- run journal and the push gate ----------------------------------------------------------------
ok "log refuses without task" '! trizy log result=pass'
ok "log refuses a bad result" '! trizy log task=x result=maybe'
trizy log task='quote " and back\slash' result=partial notes="two
lines" >/dev/null
ok "log escapes quotes, backslashes and newlines" 'tail -1 "$J"/*.jsonl | grep -qF "\"task\":\"quote \\\" and back\\\\slash\"" && tail -1 "$J"/*.jsonl | grep -qF "\"notes\":\"two\\nlines\"}"'
git init -q --bare "$T/remote.git"
git remote add origin "$T/remote.git"
trizy step add push test run 'echo tested' >/dev/null
git add -A >/dev/null; approve
git commit -qm "ci: push flow"
trizy log task="push flow" result=pass >/dev/null
ok "the first push runs the push flow" 'git push origin main 2>&1 | grep -q "push/test ok"'
sleep 1
printf 'y\n' >>README
git add README; approve
git commit -qm "docs: readme"
ok "a push without a journal entry is refused" '! git push -q origin main'
p=$(trizy worktree new other)
(cd "$p" && ./.trizy/bin/trizy log task="other branch" result=pass >/dev/null)
trizy worktree rm other >/dev/null
ok "another branch's journal entry does not cover this push" '! git push -q origin main'
trizy log task="readme" result=pass >/dev/null
ok "the push with a journal entry newer than its commits passes" 'git push -q origin main'
ok "a passed tree is not run again" 'trizy gate push "$(git rev-parse HEAD~1)" | grep -q "already passed"'

# --- update ---------------------------------------------------------------------------------------
printf '# local edit\n' >>.trizy/rules/testing.md
printf 'commit\tmine\trun\ttrue\n' >>.trizy/flows.tsv
cp -R "$KITSRC" "$T/kit2" && rm -rf "$T/kit2/.git"
printf 'NEW RULE\n' >>"$T/kit2/template/.trizy/rules/working.md"
echo 0.1.1 >"$T/kit2/template/.trizy/VERSION"
rm -rf "$T/kit2/template/.claude/skills/retro"
before=$(cat .trizy/VERSION)
mkdir -p "$T/tmpd"
TMPDIR="$T/tmpd" trizy update --from "$T/kit2" >"$T/update.log" 2>&1
ok "update leaves no temporary copy of the kit behind" '[ -z "$(ls -A "$T/tmpd")" ]'
ok "update reports the old and the new version" 'grep -q "updated $before -> 0.1.1" "$T/update.log"'
ok "update installs the new version" '[ "$(cat .trizy/VERSION)" = 0.1.1 ] && grep -q "NEW RULE" .trizy/rules/working.md'
ok "update keeps a local edit of a framework file in .orig" 'grep -q "local edit" .trizy/rules/testing.md.orig && ! grep -q "local edit" .trizy/rules/testing.md'
ok "update never touches project files" 'grep -q "^commit	mine" .trizy/flows.tsv && grep -q "^TRIZY_GIT=track" .trizy/project.conf'
ok "update removes a dropped skill and its Codex link" '[ ! -e .claude/skills/retro/SKILL.md ] && [ ! -L .codex/skills/retro ]'
ok "update keeps one block per entry file" '[ "$(grep -c "trizy:begin" CLAUDE.md)" = 1 ]'
(cd "$T/kit2" && git init -q && git add -A && git commit -qm v && git tag v0.1.1)
ok "update clones a git source at a ref" 'trizy update --from "$T/kit2" --ref v0.1.1'

# --- worktrees ------------------------------------------------------------------------------------
p=$(trizy worktree new feat/x)
ok "worktree new starts the branch outside the repo" '[ -d "$p" ] && case "$p" in */track-worktrees/*) true ;; *) false ;; esac'
printf 'dirty\n' >"$p/README"
ok "worktree rm refuses a dirty worktree" '! trizy worktree rm feat/x'
ok "worktree rm --force removes it and keeps the branch" 'trizy worktree rm feat/x --force && git rev-parse -q --verify refs/heads/feat/x'
p=$(trizy worktree new feat/y)
ok "sweep removes a merged clean worktree" 'trizy worktree sweep && [ ! -d "$p" ]'
p=$(trizy worktree new feat/j)
before=$(cat "$J"/*.jsonl | wc -l)
(cd "$p" && ./.trizy/bin/trizy log task="from a worktree" result=pass >/dev/null)
ok "a worktree writes to the same journal as the main checkout" '[ "$(cat "$J"/*.jsonl | wc -l)" -eq $((before + 1)) ]'
trizy worktree rm feat/j >/dev/null
ok "the journal survives removing the worktree" 'tail -1 "$J"/*.jsonl | grep -q "from a worktree"'

# --- heavy ----------------------------------------------------------------------------------------
ok "heavy runs the command and returns its status" 'trizy heavy -- sh -c "exit 7"; [ $? -eq 7 ]'
( trizy heavy -- sh -c 'sleep 3' ) & bg=$!
sleep 1
start=$(date +%s); trizy heavy -- true >/dev/null 2>&1; waited=$(( $(date +%s) - start ))
wait $bg
ok "heavy queues a second command behind the first (1 slot)" '[ "$waited" -ge 1 ]'
mkdir -p "$TRIZY_HEAVY_DIR/slot-1"; echo "999999 dead" >"$TRIZY_HEAVY_DIR/slot-1/owner"
ok "heavy reclaims a slot whose holder died" 'trizy heavy -- true'
ok "nested heavy does not deadlock" 'trizy heavy -- ./.trizy/bin/trizy heavy -- true'

# --- the main branch comes from git --------------------------------------------------------------
git init -q --bare "$T/trunk.git" && git -C "$T/trunk.git" symbolic-ref HEAD refs/heads/trunk
new_repo seed
git push -q "$T/trunk.git" HEAD:refs/heads/trunk HEAD:refs/heads/other
git clone -q "$T/trunk.git" "$T/cloned" && cd "$T/cloned"
${TRIZY_SH:-} "$KITSRC/template/.trizy/bin/trizy" init --track >"$T/init-trunk.log" 2>&1
ok "init takes the main branch from the remote's default and says so" 'grep -q "main branch trunk from git" "$T/init-trunk.log" && trizy check | grep -q "main branch trunk$"'
ok "the main branch is not written into project.conf" '! grep -q "^MAIN_BRANCH=" .trizy/project.conf'
git -C "$T/trunk.git" symbolic-ref HEAD refs/heads/other
ok "until refreshed, the cached default stays" 'trizy check | grep -q "main branch trunk$"'
trizy update --from "$KITSRC" >/dev/null 2>&1
ok "update refreshes the default after a rename on the server" 'trizy check | grep -q "main branch other$"'
p=$(trizy worktree new feat/m)
ok "worktree new starts from the detected main branch" '[ "$(git -C "$p" rev-parse HEAD)" = "$(git rev-parse origin/other)" ]'
printf 'MAIN_BRANCH=trunk\n' >>.trizy/project.conf
ok "MAIN_BRANCH in project.conf overrides git" 'trizy check | grep -q "main branch trunk$"'
ok "check warns when MAIN_BRANCH overrides a different git default" 'trizy check | grep "overrides git" | grep -q "s other: delete"'
printf 'TRIZY_SOURCE=/some/local/kit\n' >>.trizy/project.conf
ok "check warns about a local TRIZY_SOURCE" 'trizy check | grep -q "TRIZY_SOURCE is a local path"'
ok "worktree new reuses the branch's worktree" '[ "$(trizy worktree new feat/m)" = "$p" ]'
ok "worktree new refuses a branch checked out in the main checkout" '! trizy worktree new "$(git branch --show-current)"'

# --- ignore mode ----------------------------------------------------------------------------------
new_repo ignored
${TRIZY_SH:-} "$KITSRC/template/.trizy/bin/trizy" init --ignore >/dev/null 2>&1
ok "ignore mode ignores the kit" 'git check-ignore -q .trizy/project.conf && git check-ignore -q .claude/skills/ponytail/SKILL.md && git check-ignore -q .codex/skills/ponytail'
ok "ignore mode writes CLAUDE.local.md, not CLAUDE.md" '[ ! -f CLAUDE.md ] && grep -q "trizy:begin" CLAUDE.local.md && git check-ignore -q CLAUDE.local.md'
ok "ignore mode still creates the journal and local dirs" '[ -d .git/trizy/runs ] && [ -d .trizy/local/logs ]'
ok "without a remote the main branch is main" 'trizy check | grep -q "main branch main$"'
ok "ignore mode leaves git status clean apart from .gitignore" '[ "$(git status --porcelain | grep -v "^?? .gitignore$" | wc -l | tr -d " ")" = 0 ]'
mkdir -p sub/.trizy && : >sub/.trizy/f && : >sub/AGENTS.md
ok "ignore entries are anchored: nested .trizy and AGENTS.md stay visible" '! git check-ignore -q sub/.trizy/f && ! git check-ignore -q sub/AGENTS.md'
new_repo ignored-tracked-agents
printf '# mine\n' >AGENTS.md && git add AGENTS.md && git commit -qm agents
${TRIZY_SH:-} "$KITSRC/template/.trizy/bin/trizy" init --ignore >/dev/null 2>&1
ok "ignore mode never edits a tracked AGENTS.md" '[ "$(cat AGENTS.md)" = "# mine" ]'

# --- user install (install.sh) and the trizy command ------------------------------------------
export HOME="$T/home"
mkdir -p "$HOME"
cp -R "$KITSRC" "$T/kit3" && rm -rf "$T/kit3/.git"
(cd "$T/kit3" && git init -q && git add -A && git commit -qm v1)
sh "$T/kit3/install.sh" >"$T/install.log" 2>&1
AK="$HOME/.local/bin/trizy"
ok "install.sh puts trizy in ~/.local/bin" '[ -x "$AK" ] && [ -x "$HOME/.local/share/trizy/template/.trizy/bin/trizy" ]'
ok "install.sh says how to put it on PATH" 'grep -q "export PATH=" "$T/install.log"'
ok "trizy version works outside a repository" '(cd "$T" && "$AK" version | grep -q "^installed: ")'
new_repo viacmd
ok "trizy init installs into the current repository" '"$AK" init --track && [ -x .trizy/bin/trizy ]'
ok "init never records a local path as TRIZY_SOURCE" '! grep -qE "^TRIZY_SOURCE=(/|file:)" .trizy/project.conf'
ok "project commands run the project copy" '"$AK" flow list | grep -q "^commit " && "$AK" version | grep -q "^project: "'
(cd "$T/kit3" && echo 0.9.0 >template/.trizy/VERSION && git commit -qam v2 && sh scripts/package.sh "$T/rel") >/dev/null
ok "package.sh builds the archive and its checksum" 'tar -tzf "$T/rel/trizy.tar.gz" | grep -q "^trizy/template/.trizy/bin/trizy$" && (cd "$T/rel" && { sha256sum -c trizy.tar.gz.sha256 2>/dev/null || shasum -a 256 -c trizy.tar.gz.sha256; })'
export TRIZY_RELEASE_URL="file://$T/rel"
printf '# mine\n' >>"$AK"
ok "trizy upgrade installs the latest release" '"$AK" upgrade && "$AK" version | grep -q "^installed: 0.9.0"'
ok "upgrade leaves the command as it is" 'grep -q "^# mine$" "$AK"'
ok "trizy update brings the repository to the installed version" '"$AK" update && [ "$(cat .trizy/VERSION)" = 0.9.0 ]'
ok "install through a pipe downloads the latest release" 'TRIZY_HOME="$T/pipe" TRIZY_BIN="$T/pipebin" sh <"$T/kit3/install.sh" && [ -x "$T/pipebin/trizy" ] && [ "$(cat "$T/pipe/template/.trizy/VERSION")" = 0.9.0 ]'
mkdir -p "$T/bad" && cp "$T/rel/trizy.tar.gz" "$T/bad/" && printf '%064d  trizy.tar.gz\n' 0 >"$T/bad/trizy.tar.gz.sha256"
ok "a checksum mismatch is refused and keeps the install" '! TRIZY_RELEASE_URL="file://$T/bad" TRIZY_HOME="$T/pipe" TRIZY_BIN="$T/pipebin" sh <"$T/kit3/install.sh" && [ "$(cat "$T/pipe/template/.trizy/VERSION")" = 0.9.0 ] && [ ! -e "$T/pipe.installing" ]'
unset TRIZY_RELEASE_URL
ok "install.sh --uninstall removes the command and the install" 'sh "$T/kit3/install.sh" --uninstall && [ ! -e "$AK" ] && [ ! -d "$HOME/.local/share/trizy" ] && [ -x .trizy/bin/trizy ]'

rm -rf "$T"
printf '\n%d checks, %d failed\n' "$n" "$fails"
[ "$fails" = 0 ]
