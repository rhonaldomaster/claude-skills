# dev-workflow (plugin)

Standalone, all-in-one ticket-to-PR development workflow. One install gives you the full
`plan → implement → test → commit/PR → review` cycle with approval checkpoints, plus every
skill it orchestrates, bundled in a single plugin — no separate installs required.

## What's bundled

| Skill | Invocation | What it does |
|-------|-----------|---------------|
| `workflow` | `/dev-workflow:workflow` | The orchestrator — detects stack, loads project rules, walks phases 1-6 with checkpoints |
| `plan-ticket` | `/dev-workflow:plan-ticket <ID>` | Reads a Jira ticket, explores the codebase, writes an implementation plan |
| `pr-cycle-backend-rails` | `/dev-workflow:pr-cycle-backend-rails <PR> [TICKET] [suite]` | Full PR review for Rails |
| `pr-cycle-frontend-nextjs` | `/dev-workflow:pr-cycle-frontend-nextjs <PR> [TICKET] [suite]` | Full PR review for Next.js |
| `pr-cycle-backend-yii2` | `/dev-workflow:pr-cycle-backend-yii2 <PR> [TICKET] [suite]` | Full PR review for PHP Yii2 |
| `pr-cycle-backend-wordpress` | `/dev-workflow:pr-cycle-backend-wordpress <PR> [TICKET] [suite]` | Full PR review for WordPress |
| `pr-cycle-frontend-shopify` | `/dev-workflow:pr-cycle-frontend-shopify <PR> [TICKET] [suite]` | Full PR review for Shopify themes |
| `frontend-quality-rules` | `/dev-workflow:frontend-quality-rules` | React/JSX + CSS code quality rules, applied automatically for frontend JS stacks |
| `generate-agent-rules` | `/dev-workflow:generate-agent-rules` | Turns this plugin's `pr-cycle-*` rules into `docs/agent-rules/<stack>.md` + a pointer in `CLAUDE.md`/`AGENTS.md` |

`answer-to-copilot:respond` is used in Phase 5 if that separate plugin happens to be installed
too, but it is not bundled here.

## Relationship to the standalone skills in this repo

This plugin is a **copy**, packaged for one-shot installation elsewhere. The standalone skills
at the repo root (`plan-ticket/`, `pr-cycle/`, `frontend-quality-rules/`, `generate-agent-rules/`,
`dev-workflow/`) remain the actively maintained originals — this plugin's copies can drift out of
sync if the originals change and this plugin isn't updated to match. If you're working inside
this `claude-skills` repo, prefer the standalone skills; use this plugin when handing the whole
workflow to someone else as a single install.

## Installation

```bash
/plugin install dev-workflow@rhonaldomaster
```

Or run Claude Code with the plugin directory directly:

```bash
claude --plugin-dir /path/to/claude-skills/dev-workflow-plugin
```

## Requirements

Same as `pr-cycle` and `plan-ticket`: `gh` CLI for GitHub operations, `jira` CLI (or the
Atlassian MCP server as a fallback) for Jira operations.
