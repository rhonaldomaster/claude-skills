# frontend-nextjs-pr-cycle

Full PR cycle review skill for Next.js/React frontend PRs. Combines code quality review (team lead standards) with Jira ticket acceptance criteria coverage, inline GitHub comments, and optional Tambora QA integration.

## Requirements

### GitHub CLI (`gh`)

Used for all GitHub operations: reading PR diffs, leaving inline review comments, and submitting the final review decision.

Install: https://cli.github.com/

```bash
brew install gh
gh auth login
```

### Jira CLI (`jira`)

Used to fetch ticket details (acceptance criteria, subtasks) and optionally move tickets to a QA status column and post comments.

Install: https://github.com/ankitpokhrel/jira-cli

```bash
brew tap ankitpokhrel/jira-cli
brew install jira-cli
jira init
```

The skill uses:
- `jira issue view <TICKET_ID> --plain` — fetch ticket details
- `jira issue move <TICKET_ID> <STATUS>` — move ticket to QA column
- `jira issue comment add <TICKET_ID>` — post a comment on the ticket

> If the Jira CLI is not available or not authenticated, the Atlassian MCP server is used as a fallback for ticket reads only.

## Installation

```bash
ln -s /path/to/claude-skills/frontend-nextjs-pr-cycle ~/.claude/skills/frontend-nextjs-pr-cycle
```

Or copy the folder into a project's `.claude/skills/` directory for project-scoped use.

## Usage

```
/frontend-nextjs-pr-cycle <PR_NUMBER> [JIRA_TICKET_ID] [tambora-suite-name]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `PR_NUMBER` | Yes | GitHub PR number to review |
| `JIRA_TICKET_ID` | No | Jira ticket ID (e.g. `MPP-221`). Enables AC coverage check and post-approval ticket move. |
| `tambora-suite-name` | No | Tambora test suite name. Enables test case coverage table and optional result recording. |

### Examples

```bash
# Code review only
/frontend-nextjs-pr-cycle 42

# Code review + Jira AC coverage
/frontend-nextjs-pr-cycle 42 MPP-221

# Full cycle: code review + AC coverage + Tambora
/frontend-nextjs-pr-cycle 42 MPP-221 "MPP-150 Memories list view"
```

## What it does

1. **Reads existing PR comments** — skips issues already flagged by Copilot or other reviewers, avoiding duplicate feedback.
2. **Fetches the Jira ticket** (if provided) — extracts acceptance criteria and subtask statuses.
3. **Reviews the PR diff** against team lead code quality rules (18 quality rules + architectural patterns).
4. **Maps the diff to acceptance criteria** — reports which ACs are implemented, partial, or missing.
5. **Leaves inline GitHub comments** on the exact lines where issues occur, with one-click suggestion blocks where possible.
6. **Posts a summary review** (request-changes or approve) with an AC coverage summary.
7. **Offers to move the Jira ticket to QA** after approval (uses `jira issue move` + `jira issue comment add`).
8. **Tambora test case coverage** (if suite provided) — shows coverage status per test case and optionally records run results interactively.

## Inline comment approach

Comments are posted using the GitHub API with **file line numbers** (right-side of the diff):

```bash
gh api repos/OWNER/REPO/pulls/PR/comments \
  -f body="One less div, same result

\`\`\`suggestion
<button className="px-4 py-2">Click</button>
\`\`\`" \
  -f commit_id="COMMIT_SHA" \
  -f path="src/components/MyComponent.tsx" \
  -F line=42 \
  -f side="RIGHT"
```

Multi-line comments use `-F start_line=START -F line=END`.

## Language

Set `COMMENT_LANGUAGE=es` at the top of your invocation context for Spanish review comments. Default is English (`en`).
