---
name: damage-report-loop
description: >
  Iteratively audits and repairs local code changes or a GitHub pull request until the Damage Report is clear,
  required checks pass, and actionable current-head review feedback is resolved or explicitly blocked. Use when
  Cursor should keep reviewing, fixing, testing, and re-reviewing a branch in a bounded Greploop-style cycle.
license: MIT
compatibility: Designed for Cursor Agent. Requires git and the repository's normal build/test toolchain. GitHub PR synchronization requires authenticated gh. Works best with the companion damage-report skill installed.
metadata:
  author: Awkward8787
  version: "1.0.0"
  skill-family: damage-report
allowed-tools: Bash(git:*) Bash(gh:*) Read Grep Glob Edit Write
---

# Damage Report Loop

Run a bounded review-repair-verification cycle over the current worktree, branch, or GitHub pull request. The loop should improve the code based on evidence, not chase a score mechanically.

Use the companion `damage-report` skill for each audit when available. If it is unavailable, follow the condensed audit protocol in this file and produce the same machine-readable state footer.

## Inputs

Accept:

- A GitHub PR number or URL.
- A base ref such as `main` or `origin/develop`.
- `--max N`: maximum iterations, from 1 to 10. Default: 5.
- `--quick`: targeted checks on intermediate iterations; always use a full final audit.
- `--pr-sync`: after a verified iteration, commit, push, wait for current-head CI/review feedback, and continue.
- `--commit`: create local commits after verified iterations, but do not push.
- `--resolve`: resolve GitHub review threads only after the corresponding finding is demonstrably addressed.
- `--include-p3`: allow low-risk P3 cleanup when it is in changed files and does not expand scope.
- A named focus such as security, migrations, API contracts, accessibility, or performance.

Default mode is local: edit and test the current worktree without committing, pushing, or resolving remote threads.

## Success criteria

The loop is complete only when all are true:

1. The final Damage Report status is `clear`.
2. There are no actionable P0, P1, or P2 findings.
3. Required targeted checks and the practical full verification suite pass.
4. There are no unresolved actionable review threads against the current head SHA.
5. The fix did not create scope drift, hidden test suppression, or accidental generated files.
6. The final audit is based on the latest code, not a stale report or stale CI run.

P3 findings may remain when they are explicitly non-blocking and documented.

## Hard limits and safety

- Default maximum: 5 iterations.
- Absolute maximum: 10 iterations.
- Never run indefinitely.
- Stop immediately on a destructive or ambiguous safety gate.
- Preserve unrelated user changes. Do not reset, clean, checkout, stash, or overwrite them without explicit instruction.
- Never weaken tests, disable lint rules, add broad suppressions, use unsafe type escapes, or delete validation merely to make checks pass.
- Never expose or print secret values.
- Never deploy, run production migrations, rotate credentials, alter billing, or mutate production data.
- Do not rewrite published git history or force-push.
- Do not automatically merge a PR.

Read [references/LOOP_POLICY.md](references/LOOP_POLICY.md) before changing authentication, authorization, database schemas, public APIs, dependencies, infrastructure, or security-sensitive code.

## Procedure

### 0. Preflight

Confirm the repository and capture a baseline:

```bash
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
git rev-parse HEAD
git diff --stat
git diff --cached --stat
git ls-files --others --exclude-standard
```

Record all pre-existing modified and untracked files. They belong to the user unless the current task clearly created them.

Resolve the PR/base target using the same priority as `damage-report`:

1. Explicit PR number or URL.
2. PR associated with the current branch.
3. Explicit base ref.
4. Remote default branch.
5. `origin/main`, `origin/master`, `main`, or `master`.

If `--pr-sync` is active:

- Require `gh` authentication.
- Confirm the PR head branch matches the checked-out branch.
- Refuse force-push or history rewrite.
- Capture the current PR head SHA and current CI/review state.

Create or update:

```text
.cursor/damage-reports/loop-state.json
```

Use this shape:

```json
{
  "active": true,
  "target": "local-or-pr",
  "iteration": 0,
  "max_iterations": 5,
  "mode": "local",
  "status": "running",
  "initial_head_sha": "<sha>",
  "current_head_sha": "<sha>",
  "last_damage_score": null,
  "current_damage_score": null,
  "addressed_ids": [],
  "remaining_ids": [],
  "blocked_reasons": []
}
```

Do not stage this file unless requested.

### 1. Run the audit

Invoke `damage-report` against the same target and scope.

Intermediate iterations may use `--quick`, but the first iteration should understand the full change map and the final iteration must use `--full`.

Read:

```text
.cursor/damage-reports/latest.md
```

Parse the `DAMAGE_REPORT_STATE` footer. Reject the report as stale if its `head_sha` does not match the code being evaluated.

If `damage-report` is unavailable, perform this condensed audit:

1. Resolve base and head.
2. Inspect commit range, staged, unstaged, and untracked changes.
3. Reconstruct intended behavior.
4. Review correctness, security, data integrity, contracts, error paths, concurrency, performance, tests, UI/accessibility, deployment, and scope.
5. Run targeted tests, type checks, lint, build, and practical full tests.
6. Classify findings P0-P3.
7. Calculate the same Damage Score.
8. Write the standard report and machine-readable footer.

### 2. Decide whether to stop

Stop successfully when the success criteria are met.

Stop as `blocked` when:

- Product intent is required to choose between materially different behaviors.
- Necessary credentials, services, fixtures, hardware, or environment access are unavailable.
- A failing check is unrelated and cannot be isolated safely.
- The branch has merge conflicts that require product or ownership decisions.
- A safety gate requires explicit approval.
- The report cannot be tied to the current head SHA.

Stop as `maxed` when the maximum iteration count is reached.

Do not call a loop successful merely because the score improved.

### 3. Select findings for this iteration

Process in this order:

1. P0 findings.
2. P1 findings.
3. Root-cause P2 findings.
4. Failing required checks.
5. Current-head actionable review comments.
6. P3 findings only with `--include-p3`.

Deduplicate findings that share one root cause. Prefer one coherent fix over multiple local patches.

Before editing, write a compact iteration plan containing:

- Finding IDs.
- Root cause.
- Files expected to change.
- Test or proof that will demonstrate the fix.
- Safety gate status.

Do not expand into unrelated refactors.

### 4. Implement the smallest correct fix

For each selected root cause:

1. Read the surrounding implementation and canonical patterns.
2. Trace callers, data flow, types, and error paths.
3. Add or update a test that reproduces the defect when practical.
4. Make the minimum complete production change.
5. Preserve public behavior not implicated by the finding.
6. Keep schema, API, and configuration changes backward-compatible unless the intended change explicitly requires a break.
7. Update documentation only when behavior or operator workflow changes.

Forbidden shortcuts:

- Deleting or skipping a failing test.
- Broad `any`, `@ts-ignore`, blanket exception swallowing, or linter suppression.
- Hard-coded test-only branches in production code.
- Removing authorization, validation, retries, or error handling to quiet a failure.
- Changing expected output solely to match the defect.
- Large dependency upgrades to solve a narrow finding unless explicitly required.

### 5. Verify the iteration

Run verification in increasing scope:

1. The new or directly affected test.
2. Tests for the changed subsystem.
3. Type checking or compilation.
4. Lint/static analysis.
5. Build.
6. Practical full suite.

Record exact commands and outcomes. A command that could not run is `blocked`, not `passed`.

Inspect the new diff:

```bash
git diff --check
git diff --stat
git diff
git status --short
```

Check for:

- Accidental files.
- Debug logging.
- Secret material.
- Lockfile churn.
- Unrelated formatting.
- Missing tests.
- New warnings.
- Scope expansion.

### 6. Re-audit

Run `damage-report` again against the updated code.

Compare:

- Previous and current Damage Score.
- Addressed IDs.
- New findings.
- Check status.
- Head SHA.
- Scope size.

If the Damage Score increases, identify the regression before continuing. Revert only the loop's own faulty changes, and only when they can be isolated without touching pre-existing user work.

A finding is addressed only when the code and verification evidence prove it, not when the text disappears from a report.

### 7. Optional commit and PR synchronization

#### Local commit mode

With `--commit`, commit only verified files created or changed by this loop. Do not include pre-existing unrelated changes.

Use a focused message such as:

```bash
git commit -m "fix: address damage report findings DR-001 DR-002"
```

#### PR synchronization mode

With `--pr-sync`, follow [references/PR_SYNC.md](references/PR_SYNC.md):

1. Commit verified changes.
2. Push normally to the existing PR branch.
3. Capture the new head SHA.
4. Wait for checks associated with that SHA.
5. Fetch current-head reviews, general comments, and inline comments.
6. Rerun the audit.
7. Continue only from current-head evidence.

Do not post repeated trigger comments to third-party bots unless the user explicitly requested that integration.

With `--resolve`, resolve only threads whose issue was fixed or shown to be informational with evidence. Never resolve an unresolved human design question on the user's behalf.

### 8. Update loop state

After every iteration, update `loop-state.json` with:

- Iteration number.
- Previous and current Damage Score.
- Current head SHA.
- Addressed IDs.
- Remaining IDs.
- New findings.
- Verification summary.
- Status: `running`, `clear`, `blocked`, or `maxed`.
- Blocked reasons.

When complete, set `"active": false`.

### 9. Final full audit

Regardless of intermediate mode, run a full final Damage Report on the latest code.

Confirm:

```bash
git diff --check
git status --short --branch
```

For PR synchronization, confirm the report head SHA matches the remote PR head SHA and the relevant CI runs belong to that SHA.

### 10. Final response

Return:

- Final state: `CLEAR`, `BLOCKED`, or `MAX ITERATIONS`.
- Iterations completed.
- Initial and final Damage Score.
- Findings fixed, remaining, and newly discovered.
- Exact checks passed, failed, or blocked.
- Files changed by the loop.
- Commits and push status, when applicable.
- Current report path.
- Merge recommendation.
- Any safety or product decision still required.

Do not conceal remaining risk.
