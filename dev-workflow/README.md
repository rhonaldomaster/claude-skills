# dev-workflow

Stack-agnostic ticket-to-PR development workflow with explicit approval checkpoints.

Detects the project's stack (Rails, Next.js, PHP Yii2, WordPress, Shopify — same detection
table as `plan-ticket`), loads its own `CLAUDE.md`/`AGENTS.md`/`.cursorrules` rules, and guides
plan → implement → test → commit/PR → review, stopping at each checkpoint for approval.

It orchestrates existing skills rather than duplicating them:

- [`plan-ticket`](../plan-ticket/) for Phase 1
- [`frontend-quality-rules`](../frontend-quality-rules/) for frontend JS stacks
- [`pr-cycle`](../pr-cycle/) skills for Phase 6 review
- `answer-to-copilot:respond` for Phase 5, only if that plugin is installed

Does not generate project rules (`CLAUDE.md`/`AGENTS.md`) — that's a separate, future skill.

## Usage

```
/dev-workflow
```

Or just start working a ticket and mention you want the full workflow.

## Installation

Symlink into your global skills directory:

```bash
ln -s /path/to/claude-skills/dev-workflow ~/.claude/skills/dev-workflow
```

Or copy into a project's `.claude/skills/` directory.
