# claude-skills

Collection of Claude Code skills for development workflows.

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| [generate-patterns](./generate-patterns/) | `/generate-patterns` | Explore a codebase and generate a `PATTERNS.md` documenting recurring implementation patterns for cross-session consistency |

## Installation

### Global (recommended)

Symlink a skill into your global Claude skills directory:

```bash
ln -s /path/to/claude-skills/generate-patterns ~/.claude/skills/generate-patterns
```

### Per-project

Copy the skill folder into a project's `.claude/skills/` directory.
