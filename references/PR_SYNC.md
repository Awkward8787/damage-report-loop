# GitHub PR Synchronization

Use this workflow only when `--pr-sync` is explicitly active.

## Preconditions

- `gh auth status` succeeds.
- The checked-out branch is the PR head branch.
- The user has push permission.
- The branch is not protected from direct pushes, or the repository workflow allows them.
- The working tree contains no unrelated changes that would be swept into the commit.

## Fetch current PR state

```bash
gh pr view <PR> --json number,url,title,state,isDraft,baseRefName,headRefName,headRefOid,mergeable,reviewDecision,statusCheckRollup
gh pr checks <PR>
gh api --paginate "repos/{owner}/{repo}/issues/<PR>/comments?per_page=100"
gh api --paginate "repos/{owner}/{repo}/pulls/<PR>/reviews?per_page=100"
gh api --paginate "repos/{owner}/{repo}/pulls/<PR>/comments?per_page=100"
```

Keep only feedback relevant to the current head or explicitly carried forward from an older revision.

## Commit

Stage explicit files, never the entire worktree by default:

```bash
git add -- <verified-file-1> <verified-file-2>
git diff --cached --check
git diff --cached --stat
git commit -m "fix: address damage report findings DR-001 DR-002"
```

## Push

```bash
git push
```

Never use `--force`, `--force-with-lease`, or history rewriting.

After the push, capture:

```bash
HEAD_SHA="$(git rev-parse HEAD)"
REMOTE_HEAD="$(gh pr view <PR> --json headRefOid -q .headRefOid)"
```

The SHAs must match before treating remote checks as current.

## Wait for checks

Poll with bounded attempts. Prefer `gh pr checks --watch` when available:

```bash
gh pr checks <PR> --watch --interval 10
```

If a repository has long-running optional checks, distinguish required from optional checks rather than waiting indefinitely. Stop after a reasonable repository-specific timeout and mark verification blocked.

## Refresh feedback

Fetch all three GitHub feedback surfaces after each push:

1. General PR comments.
2. Review submissions.
3. Inline review comments and review threads.

Bots may edit a prior summary comment in place. Compare `updated_at`, not only `created_at`.

## Thread resolution

With `--resolve`:

- Resolve a thread only after the corresponding code is on the PR head and verification supports the fix.
- Reply with concise evidence when useful.
- Do not resolve an open product question or disagreement.
- Do not resolve a thread merely because it is old.

## Exit validation

Before declaring clear:

- Local `HEAD`, PR `headRefOid`, report `head_sha`, and CI commit SHA agree.
- Required checks for that SHA pass.
- Current-head actionable threads are zero.
- The PR is not in a conflicted or unknown merge state.
