## rails-lead-review

PR code review for Ruby on Rails projects using the team lead's architectural opinions and Rails best practices. Leaves inline GitHub comments on the exact lines where issues occur and posts a summary review (request-changes or approve).

## Requirements

### GitHub CLI (`gh`)

Used for all GitHub operations: reading PR diffs, leaving inline review comments, and submitting the final review decision.

Install: https://cli.github.com/

```bash
brew install gh
gh auth login
```

## Usage

```
/rails-lead-review <PR_NUMBER>
```

| Argument | Required | Description |
|----------|----------|--------------|
| `PR_NUMBER` | Yes | GitHub PR number to review |

Set `COMMENT_LANGUAGE=es` for Spanish review comments. Default is English (`en`).

## What it does

1. Checks PR title and commit messages for a valid ticket reference (rejects vague titles like "update", "fix", "WIP").
2. Reviews the diff and applies rules based on file type: `.rb` for Rails backend rules, `.html.erb` for view rules plus the frontend rules in [quality-rules.md](quality-rules.md), `db/migrate/` for migration rules, `spec/`/`test/` for testing, `app/jobs/` for background jobs, `app/mailers/` for mailers.
3. Checks for N+1 queries, SQL injection via string interpolation, missing strong parameters, missing database indexes, forgotten debug statements, missing `null: false` constraints, side effects in callbacks, fat controllers, `deliver_now` in mailers, non-idempotent jobs, missing `dependent:` on associations, and more (20 rules total).
4. Leaves inline comments on the exact line where each issue occurs, using `` ```suggestion `` or `` ```ruby `` blocks for fixes.
5. Posts a summary review: `--request-changes` if violations were found, `--approve` if the code is clean.

## Related

- [lead-review](../lead-review/) — same reviewer style, for general frontend/React PRs.
