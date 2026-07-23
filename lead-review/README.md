## lead-review

PR code review using the team lead's architectural opinions and code standards — general frontend/React focus. Leaves inline GitHub comments on the exact lines where issues occur and posts a summary review (request-changes or approve).

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
/lead-review <PR_NUMBER>
```

| Argument | Required | Description |
|----------|----------|--------------|
| `PR_NUMBER` | Yes | GitHub PR number to review |

Set `COMMENT_LANGUAGE=es` for Spanish review comments. Default is English (`en`).

## What it does

1. Checks PR title and commit messages for a valid ticket reference (rejects vague titles like "update", "fix", "WIP").
2. Reviews the diff against the lead's review patterns — unnecessary DIVs, forgotten `console.log`, duplicate files/components, image paths, missing documentation, indentation, inappropriate elements, repetitive JSX — plus the supplemental rules in [quality-rules.md](quality-rules.md).
3. Leaves inline comments on the exact line where each issue occurs, using `` ```suggestion `` blocks for one-click fixes where possible.
4. Posts a summary review: `--request-changes` if violations were found, `--approve` if the code is clean.

## Related

- [rails-lead-review](../rails-lead-review/) — same reviewer style, adapted for Ruby on Rails backend PRs.
