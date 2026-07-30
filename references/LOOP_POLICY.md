# Damage Report Loop Policy

This reference defines when the loop may proceed autonomously and when it must stop for a safety or product decision.

## Safe autonomous changes

The loop may usually proceed when the intended behavior is already clear and the fix is bounded:

- Null, bounds, or error-path corrections.
- Correcting a reachable logic defect.
- Adding missing validation consistent with existing contracts.
- Adding or repairing tests without weakening expectations.
- Narrow performance fixes that preserve behavior.
- Accessibility fixes that preserve design intent.
- Updating documentation to match verified behavior.
- Small dependency patch updates already permitted by project policy.

## Stop gates

Stop and report the required decision before doing any of the following unless the user's request already authorizes it clearly.

### Authentication and authorization

- Changing role definitions or permission boundaries.
- Making previously protected data public.
- Changing token lifetime, session policy, or account recovery semantics.
- Bypassing an authorization check to restore behavior.

### Data and migrations

- Destructive or irreversible migration.
- Column or table deletion.
- Reinterpreting existing persisted values.
- Backfill with business consequences.
- Changing transaction or consistency guarantees.
- Running any migration against a non-local database.

### Public contracts

- Breaking API, event, webhook, CLI, or SDK compatibility.
- Renaming externally consumed fields.
- Changing status codes or error contracts used by clients.
- Removing feature flags or fallback behavior.

### Dependencies and infrastructure

- Major dependency upgrade.
- Package manager or runtime migration.
- Cloud resource creation or deletion.
- Deployment, DNS, secrets, billing, or production configuration change.
- CI permission expansion.

### Product ambiguity

- Multiple plausible UX or business behaviors.
- A reviewer asks for a product decision rather than a code correction.
- Existing tests and documented requirements disagree.
- The fix changes pricing, entitlement, moderation, compliance, or user data retention.

## Handling a stop gate

1. Do not make the gated change.
2. Preserve all verified safe fixes already completed.
3. Mark the report and loop state as `blocked`.
4. State the exact decision needed, affected files, and available options.
5. Include the safest recommended option, clearly labeled as a recommendation.

## Preserving user work

At preflight, record existing modified and untracked files. Never:

- `git reset --hard`
- `git clean`
- blanket `git checkout -- .`
- force checkout another branch
- overwrite an existing stash
- amend or rewrite user commits
- force-push

A targeted revert is allowed only for changes made by the current loop and only when it cannot touch pre-existing user edits.
