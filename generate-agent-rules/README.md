# generate-agent-rules

Generates a per-stack code guidelines file for a project from this repo's `pr-cycle` review
rules, then wires a short pointer to it into the project's `CLAUDE.md`/`AGENTS.md` — instead of
pasting every rule inline and bloating that file.

Detects the project's stack (same table as `plan-ticket`/`dev-workflow`), pulls the code quality
rules from the matching `pr-cycle` skill (ignoring the PR/Jira/Tambora parts), rewrites each rule
as positive "write it this way" guidance grouped by priority, and writes it to
`docs/agent-rules/<stack>.md`.

`CLAUDE.md`/`AGENTS.md` gets one short, idempotent block instead of the full rule list:

```markdown
<!-- BEGIN generated-rules: nextjs -->
## Code style

When writing or reviewing nextjs code, read `docs/agent-rules/nextjs.md` first.
<!-- END generated-rules: nextjs -->
```

Does not review code and does not implement anything — only writes the guidelines doc and the
pointer block.

## Usage

```
/generate-agent-rules
```

Run it from the target project's root (the project you want rules generated for). It reads the
`pr-cycle` skill definitions from this `claude-skills` repo, so that repo must be reachable
(checked out, or available as an installed plugin) for the rules to be pr-cycle-derived rather
than generic fallbacks.

## Installation

```bash
ln -s /path/to/claude-skills/generate-agent-rules ~/.claude/skills/generate-agent-rules
```

Or copy into a project's `.claude/skills/` directory.
