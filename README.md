# claude-skills

Collection of Claude Code skills for development workflows.

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| [generate-patterns](./generate-patterns/) | `/generate-patterns` | Explore a codebase and generate a `PATTERNS.md` documenting recurring implementation patterns |
| [plan-ticket](./plan-ticket/) | `/plan-ticket` | Read a Jira ticket and generate a structured implementation plan (supports Next.js, Rails, PHP Yii2, WordPress, Shopify) |
| [lead-review](./lead-review/) | `/lead-review` | Frontend PR code review using team lead's architectural opinions and code standards |
| [rails-lead-review](./rails-lead-review/) | `/rails-lead-review` | Rails PR code review using team lead's architectural opinions and Rails best practices |
| [frontend-quality-rules](./frontend-quality-rules/) | `/frontend-quality-rules` | Frontend code quality rules for writing and reviewing React/JSX code |
| [refine-ticket](./refine-ticket/) | `/refine-ticket` | Read a Jira ticket and suggest edits to improve its quality |

## Plugin

| Plugin | Description |
|--------|-------------|
| [ticket-audit](./ticket-audit/) | Claude Code plugin bundling `review-ticket-frontend-nextjs` and `review-ticket-backend-rails` with optional Tambora QA integration |
| [pr-cycle](./pr-cycle/) | Claude Code plugin for full PR cycle reviews across 5 stacks (Next.js, Rails, Yii2, WordPress, Shopify): code quality + Jira AC coverage + Tambora |

## Installation

### Single skill (global)

Symlink a skill into your global Claude skills directory:

```bash
ln -s /path/to/claude-skills/<skill-name> ~/.claude/skills/<skill-name>
```

### Single skill (per-project)

Copy the skill folder into a project's `.claude/skills/` directory.

### Plugin (ticket-audit)

```bash
/plugin install ticket-audit@rhonaldomaster
```

Or run Claude with the plugin directory:

```bash
claude --plugin-dir /path/to/claude-skills/ticket-audit
```
