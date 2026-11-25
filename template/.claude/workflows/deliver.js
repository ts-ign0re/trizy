export const meta = {
  name: 'deliver',
  description: 'trizy delivery pipeline: task → approved plan → packages in own worktrees → independent gate → deliver/<slug> → verify + journal',
  whenToUse:
    'A feature or fix big enough to split into packages. args {task} returns the plan for approval; args {task, plan} builds the approved plan. Never merges into the main branch or pushes.',
  phases: [
    { title: 'Plan', detail: 'Fable splits the task into packages with numeric checks and optimality blocks', model: 'fable' },
    { title: 'Build', detail: 'one Opus agent per package in its own worktree', model: 'opus' },
    { title: 'Gate', detail: 'independent review + re-run of the checks, at most 3 attempts', model: 'opus' },
    { title: 'Merge', detail: 'accepted packages into deliver/<slug>' },
    { title: 'Verify', detail: 'every plan check + the deliver:verify flow, journal entry, cleanup', model: 'opus' },
  ],
}

const input = typeof args === 'string' ? { task: args } : args || {}
if (!input.task) throw new Error("args.task is required: the task in the owner's words")
const TASK = input.task
const REPO = input.repo || null // the repository root, when the session runs elsewhere
const KIT = '.trizy/bin/trizy'
const STANDING =
  'STANDING: you are one step of the trizy `deliver` workflow, started by the repository owner. ' +
  "The task below is the owner's own request relayed by the orchestrator; act on it within AGENTS.md, .trizy/AGENTS.trizy.md, " +
  '.trizy/CONSTRAINTS.md and .trizy/rules/*.md (read them first).' +
  (REPO ? ` The repository is ${REPO}: run every command there or in the worktrees named below.` : '') +
  '\n\n'
const COMMON =
  `Heavy commands (tests, builds, linters) go through \`${KIT} heavy -- <cmd>\`. Logs go to files under .trizy/local/logs; ` +
  'report summaries and failures only. Never touch a shared stand. Private test infra: if TEST_INFRA_UP is set in ' +
  '.trizy/project.conf, start yours in the SAME Bash command as the tests (env does not carry between calls): ' +
  '`. .trizy/project.conf && infra="$(NAME=<name> sh -c "$TEST_INFRA_UP")" && eval "$infra" && <tests>`, and tear it down with ' +
  '`NAME=<name> sh -c "$TEST_INFRA_DOWN"` when done (also when blocked).'
const flowStep = (stage) =>
  `Flow deliver:${stage}: \`${KIT} flow show deliver:${stage}\` lists its steps; do every ask step and run every run step ` +
  `(\`${KIT} flow run deliver:${stage}\` from your worktree root); report each one in your evidence/checks.`
const bullets = (xs) => xs.map((x) => `\n- ${x}`).join('')
const checkLine = (c) => (typeof c === 'string' ? c : `${c.what}: \`${c.command}\` → expect ${c.expect}`)
const OPT_MISSING = '(none in the plan: run optimality-check for this package yourself before anything else)'
// Required skills per stage, loaded with the Skill tool first and reported in skillsUsed; a stage without them failed.
const REQUIRED = {
  plan: ['optimality-check'],
  build: ['ponytail', 'review-gate', 'optimality-check'],
  gate: ['review-gate', 'security-reviewer', 'ponytail-review', 'optimality-check'],
}
const loadFirst = (stage) =>
  `Before anything else load these skills with the Skill tool: ${REQUIRED[stage].join(', ')}. Report every skill you actually loaded in skillsUsed.\n`
const missing = (stage, r) => REQUIRED[stage].filter((s) => !(r?.skillsUsed || []).includes(s))

const SKILLS_USED = { type: 'array', items: { type: 'string' }, description: 'skills loaded with the Skill tool' }
const CHECKS = {
  type: 'array',
  items: {
    type: 'object',
    required: ['check', 'result', 'evidence'],
    properties: { check: { type: 'string' }, result: { enum: ['pass', 'fail', 'unresolved'] }, evidence: { type: 'string' } },
  },
}
const PLAN = {
  type: 'object',
  required: ['slug', 'summary', 'packages', 'openQuestions', 'skillsUsed'],
  properties: {
    slug: { type: 'string', description: 'kebab-case [a-z0-9-], ≤ 30 chars' },
    summary: { type: 'string' },
    packages: {
      type: 'array',
      items: {
        type: 'object',
        required: ['id', 'title', 'spec', 'files', 'checks', 'dependsOn', 'optimality'],
        properties: {
          id: { type: 'string', description: 'kebab-case [a-z0-9-], unique, ≤ 30 chars (it becomes branch and container names)' },
          title: { type: 'string' },
          spec: { type: 'string' },
          files: { type: 'array', items: { type: 'string' }, description: 'repo-relative paths/globs this package owns' },
          checks: {
            type: 'array',
            description: 'the stop condition: machine-checkable, numbers and facts, no adjectives',
            items: {
              type: 'object',
              required: ['what', 'command', 'expect'],
              properties: { what: { type: 'string' }, command: { type: 'string' }, expect: { type: 'string', description: 'exit 0, a count, an exact output' } },
            },
          },
          dependsOn: { type: 'array', items: { type: 'string' } },
          optimality: { type: 'string', description: 'the optimality-check YAML block for this package' },
        },
      },
    },
    openQuestions: { type: 'array', items: { type: 'string' }, description: 'owner decisions and assumptions, each with the default taken' },
    skillsUsed: SKILLS_USED,
  },
}
const SETUP = {
  type: 'object',
  required: ['worktree', 'sha', 'main'],
  properties: { worktree: { type: 'string', description: 'absolute path' }, sha: { type: 'string' }, main: { type: 'string' } },
}
const BUILD = {
  type: 'object',
  required: ['status', 'commit', 'files', 'evidence', 'skillsUsed'],
  properties: {
    status: { enum: ['done', 'blocked'] },
    blocker: { type: 'string' },
    commit: { type: 'string' },
    files: { type: 'array', items: { type: 'string' } },
    evidence: { type: 'array', items: { type: 'string' }, description: 'check → command → result' },
    skillsUsed: SKILLS_USED,
  },
}
const GATE = {
  type: 'object',
  required: ['verdict', 'findings', 'checks', 'skillsUsed'],
  properties: {
    verdict: { enum: ['pass', 'fail'] },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['severity', 'file', 'issue'],
        properties: {
          severity: { enum: ['blocker', 'major', 'minor'] },
          file: { type: 'string' },
          line: { type: 'number' },
          issue: { type: 'string' },
          fix: { type: 'string' },
        },
      },
    },
    checks: CHECKS,
    skillsUsed: SKILLS_USED,
  },
}
const MERGE = {
  type: 'object',
  required: ['merged'],
  properties: { merged: { type: 'boolean' }, sha: { type: 'string' }, conflicts: { type: 'array', items: { type: 'string' } } },
}
const VERIFY = { type: 'object', required: ['verdict', 'checks'], properties: { verdict: { enum: ['pass', 'fail'] }, checks: CHECKS } }

// Names become branch, worktree and container names: refuse anything else before any work starts.
function validate(plan) {
  const ok = (s) => typeof s === 'string' && s.length <= 30 && /^[a-z0-9]+(-[a-z0-9]+)*$/.test(s)
  if (!Array.isArray(plan.packages) || !plan.packages.length) throw new Error('plan.packages must be a non-empty array')
  for (const p of plan.packages) for (const k of ['files', 'checks', 'dependsOn']) if (!Array.isArray(p[k])) throw new Error(`${p.id}.${k} must be an array`)
  if (!ok(plan.slug)) throw new Error(`bad slug: ${plan.slug}`)
  const ids = plan.packages.map((p) => p.id)
  for (const id of ids) if (!ok(id)) throw new Error(`bad package id: ${id}`)
  if (new Set(ids).size !== ids.length) throw new Error(`duplicate package ids: ${ids.join(', ')}`)
  for (const p of plan.packages) {
    const unknown = p.dependsOn.filter((d) => !ids.includes(d))
    if (unknown.length) throw new Error(`${p.id} depends on unknown ${unknown.join(', ')}`)
    if (!p.checks.length) throw new Error(`${p.id} has no checks: a package without a stop condition never ends`)
  }
}

let plan = input.plan
if (!plan) {
  phase('Plan')
  plan = await agent(
    STANDING +
      `Task: ${TASK}\n\n` +
      loadFirst('plan') +
      'You plan; you edit nothing. Read the code the task touches and the docs that cover it. ' +
      'Split the task into packages. A package is one bounded job one agent can finish and prove: the files it owns and its checks. ' +
      'Each check is the stop condition in numbers and facts: a command and its expected result (exit 0, a count, an exact output), ' +
      'never an adjective. Fewer packages beat more; split by what each must read, not by folder; no two packages own the same file; ' +
      "dependsOn only when a package needs another's code. Stay in the asked scope. Checks run on private test infra or locally. " +
      'Spec and checks describe the change only: repo-relative paths, nothing about branches, worktrees, review or commits. ' +
      'optimality-check: run it for the task, then for every package, and put the block in its optimality field; a package whose cheaper ' +
      'candidate breaks no sourced constraint is replaced by that candidate or dropped. openQuestions = owner decisions and every ' +
      `assumption, each with the default you planned for. ${flowStep('plan')}`,
    { label: 'plan', schema: PLAN, model: 'fable', effort: 'high' },
  )
  if (!plan) throw new Error('planner returned nothing')
  if (missing('plan', plan).length) throw new Error(`planner skipped required skills: ${missing('plan', plan).join(', ')}`)
  validate(plan)
  return { plan, next: 'Approve (or edit) the plan, then run again with args {task, plan}.' }
}
validate(plan)

const BRANCH = `deliver/${plan.slug}`
// Test infra NAME prefix: slug head + a hash of the whole slug, so runs whose slugs share a head never share containers.
const CT = plan.slug.slice(0, 4) + [...plan.slug].reduce((h, c) => (h * 31 + c.charCodeAt(0)) >>> 0, 7).toString(36).slice(-4)

phase('Merge')
const setup = await agent(
  STANDING +
    `From the repository root: \`${KIT} worktree new ${BRANCH}\` (no base: it starts from the freshly fetched main branch, which ` +
    `the kit reads from git) prints the worktree path, or reuses the branch's worktree if it exists. Install the project's dependencies ` +
    `there if it has any (through \`${KIT} heavy --\`, log to a file). The main branch's name is the last word of the ` +
    `\`main branch <name>\` line that \`${KIT} check\` always prints. Return the worktree's ABSOLUTE path, its HEAD sha and that main branch name.`,
  { label: 'setup', schema: SETUP, effort: 'low' },
)
if (!setup?.worktree?.startsWith('/')) throw new Error(`setup did not return an absolute worktree path: ${JSON.stringify(setup)}`)
const WT = setup.worktree
const MAIN = setup.main || 'main'
log(`integration: ${BRANCH} at ${WT} (${setup.sha})`)

const status = {}
const accepted = (gate) =>
  gate.verdict === 'pass' && !gate.findings.some((f) => f.severity !== 'minor') && gate.checks.length > 0 && gate.checks.every((c) => c.result === 'pass')

async function buildAndGate(p) {
  const branch = `${BRANCH}--${p.id}`
  const name = `${CT}--p-${p.id}`
  const others = plan.packages.filter((q) => q.id !== p.id).flatMap((q) => q.files)
  const checks = bullets(p.checks.map(checkLine))
  let wt = null
  let build = null
  let gate = null
  for (let attempt = 1; attempt <= 3; attempt++) {
    build = await agent(
      STANDING +
        `Package ${p.id} — ${p.title}, part of the task: ${TASK}\n\nSpec: ${p.spec}\nFiles you own: ${p.files.join(', ')}\n` +
        `Files other packages own (never touch them; needing one = return blocked): ${others.join(', ') || 'none'}\n` +
        `Checks (your stop condition):${checks}\nOptimality (the plan's choice; build exactly the chosen candidate — a cheaper one ` +
        `that breaks no sourced constraint = return blocked naming it):\n${p.optimality || OPT_MISSING}\n\n` +
        loadFirst('build') +
        (attempt === 1
          ? `Setup: from ${WT}, \`${KIT} worktree new ${branch} ${BRANCH}\` prints your worktree path (reused if it exists). `
          : `Attempt ${attempt}: your worktree for ${branch} exists (\`git worktree list\`). The gate returned this package; fix THIS ` +
            `package only:\n${JSON.stringify({ findings: gate.findings, failedChecks: gate.checks.filter((c) => c.result !== 'pass') })}\n`) +
        'Work only in that worktree; touch only your files plus what your change directly forces (its tests, fixtures, registries) and ' +
        "list every extra file in `files`; needing another package's behaviour = return blocked. Ponytail: the shortest working diff. " +
        `While coding run the checks and the tests you touched (private infra NAME=${name}); the gate runs the full suite. ` +
        `${flowStep('build')} ${COMMON}\n` +
        'Before the commit, self-review your staged diff with the review-gate skill and fix every real finding (package branches ' +
        'need no receipt: the gate is their independent review; never edit hooks). ' +
        `Commit on ${branch} with the optimality line in the message. Never push, never touch ${MAIN} or other worktrees. ` +
        'Return the commit sha, the files changed and one evidence line per check (command → result).',
      { label: `build:${p.id}#${attempt}`, phase: 'Build', schema: BUILD, model: 'opus', effort: 'high' },
    )
    if (!build || build.status !== 'done') return { ok: false, why: build?.blocker || 'builder died', build, gate, attempts: attempt, branch }
    if (missing('build', build).length) {
      gate = { verdict: 'fail', checks: [], findings: [{ severity: 'major', file: '-', issue: `required skills not loaded: ${missing('build', build).join(', ')}` }] }
      continue
    }
    const gatePrompt =
      STANDING +
      `Independent gate for package ${p.id} — ${p.title} (task: ${TASK}). You did not write it; don't trust the builder's report, check.\n` +
      loadFirst('gate') +
      `Spec: ${p.spec}\nChecks:${checks}\nThe package is branch ${branch} (find its worktree in \`git worktree list\`); diff: ` +
      `\`git diff ${BRANCH}...${branch}\`.\nOptimality block of the plan:\n${p.optimality || OPT_MISSING}\n` +
      '1. Review every changed file with the review-gate skill and the project rules in .trizy/review-rules.tsv, through the ' +
      'security-reviewer lens, the ponytail-review lens (logic, safety, load, tests, every line needed; over-building is major when it adds risk or surface) and the optimality-check lens (every new file, directory, store, mechanism or format in the diff has its own optimality line, ' +
      'else major; the diff builds the chosen candidate; a cheaper candidate that breaks no sourced constraint, or a rejection without sourced ' +
      'evidence, is major). Verify every finding at HEAD before reporting it.\n' +
      `2. Re-run every check yourself in the package worktree, after your last read of the code, on private infra NAME=${CT}--g-${p.id}. ` +
      `${flowStep('gate')} ${COMMON}\n` +
      '3. pass only if every check passes and no blocker or major finding remains; security, data-loss and contract findings are at ' +
      'least major. Read-only: never edit, commit or push.'
    gate = await agent(gatePrompt, { label: `gate:${p.id}#${attempt}`, phase: 'Gate', schema: GATE, model: 'opus', effort: 'high' })
    if (gate && missing('gate', gate).length) gate = await agent(gatePrompt, { label: `gate:${p.id}#${attempt}b`, phase: 'Gate', schema: GATE, model: 'opus', effort: 'high' })
    if (!gate) return { ok: false, why: 'gate died', build, gate, attempts: attempt, branch }
    if (missing('gate', gate).length) return { ok: false, why: `gate skipped ${missing('gate', gate).join(', ')}`, build, gate, attempts: attempt, branch }
    if (accepted(gate)) return { ok: true, build, gate, attempts: attempt, branch }
  }
  return { ok: false, why: 'gate failed 3 times', build, gate, attempts: 3, branch }
}

// Waves in dependency order; at most 3 packages at once.
for (;;) {
  const pending = plan.packages.filter((p) => !status[p.id])
  if (!pending.length) break
  let spread = false
  for (const p of pending) {
    const bad = p.dependsOn.filter((d) => status[d] && !status[d].ok)
    if (bad.length) {
      status[p.id] = { ok: false, why: `depends on failed ${bad.join(', ')}` }
      spread = true
    }
  }
  if (spread) continue
  const ready = pending.filter((p) => p.dependsOn.every((d) => status[d]?.ok))
  if (!ready.length) {
    for (const p of pending) status[p.id] = { ok: false, why: 'dependency cycle' }
    break
  }
  for (let i = 0; i < ready.length; i += 3) {
    const chunk = ready.slice(i, i + 3)
    const results = await parallel(chunk.map((p) => () => buildAndGate(p)))
    for (const [k, p] of chunk.entries()) {
      const r = results[k] || { ok: false, why: 'crashed' }
      if (r.ok) {
        const merge = await agent(
          STANDING +
            `In ${WT}: \`git merge --no-ff ${r.branch} -m "merge(${plan.slug}): ${p.id} — ${p.title}"\`. ` +
            `On conflict: \`git merge --abort\` and return merged=false with the files. On success: \`${KIT} worktree rm ${r.branch}\` then ` +
            `\`git branch -d ${r.branch}\`.`,
          { label: `merge:${p.id}`, phase: 'Merge', schema: MERGE, effort: 'low' },
        )
        r.merge = merge
        if (!merge?.merged) Object.assign(r, { ok: false, why: `merge conflict: ${(merge?.conflicts || []).join(', ')}` })
      }
      status[p.id] = r
      log(`${p.id}: ${r.ok ? `merged after ${r.attempts} attempt(s)` : `FAILED — ${r.why}`}`)
    }
  }
}

const merged = plan.packages.filter((p) => status[p.id].ok)
phase('Verify')
let verify = null
if (merged.length) {
  verify = await agent(
    STANDING +
      `Final checks on ${BRANCH} in ${WT} (task: ${TASK}). Fix nothing; report.\n` +
      `1. Each plan check, one row each (pass/fail/unresolved, evidence = command + result), on private infra NAME=${CT}--final:${bullets(
        merged.flatMap((p) => p.checks.map((c) => `[${p.id}] ${checkLine(c)}`)),
      )}\n2. ${flowStep('verify')}\n${COMMON}`,
    { label: 'verify', phase: 'Verify', schema: VERIFY, model: 'opus', effort: 'high' },
  )
}
const summary = plan.packages.map((p) => `${p.id}:${status[p.id].ok ? 'ok' : 'failed'}/${status[p.id].attempts || 0}`).join(' ')
const result = merged.length === plan.packages.length && verify?.verdict === 'pass' ? 'pass' : merged.length ? 'partial' : 'fail'
const findings = plan.packages.flatMap((p) => (status[p.id].gate?.findings || []).map((f) => `${p.id}:${f.severity}:${f.issue}`)).join(' | ')
// Whatever died mid-way: the run is journalled and no test infra of this run survives; failed packages keep their worktrees.
const cleanup = await agent(
  STANDING +
    `1. In ${WT}: \`${KIT} log task=${JSON.stringify(`deliver ${plan.slug}: ${TASK}`.slice(0, 300))} result=${result} ` +
    `packages=${JSON.stringify(summary)} findings=${JSON.stringify(findings.slice(0, 1500))}\` (the journal is local, never committed).\n` +
    `2. Tear down every private test infra of this run (NAME prefix ${CT}--) with TEST_INFRA_DOWN from .trizy/project.conf, if set. ` +
    'Touch nothing else. Return one line: the journal entry and what was torn down.',
  { label: 'cleanup', phase: 'Verify', effort: 'low' },
)

return {
  branch: BRANCH,
  worktree: WT,
  result,
  plan: { slug: plan.slug, summary: plan.summary, openQuestions: plan.openQuestions },
  packages: plan.packages.map((p) => ({
    id: p.id,
    ok: status[p.id].ok,
    why: status[p.id].why,
    attempts: status[p.id].attempts,
    commit: status[p.id].build?.commit,
    openFindings: status[p.id].gate?.findings?.length || 0,
    leftBranch: status[p.id].ok ? undefined : status[p.id].branch,
  })),
  verify,
  cleanup,
  next: "The owner reviews the branch; merging into the main branch and pushing are the owner's call.",
}
