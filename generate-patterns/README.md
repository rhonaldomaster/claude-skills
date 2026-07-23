## generate-patterns

Explore a project's codebase and generate a `PATTERNS.md` file documenting recurring implementation patterns (page structure, component patterns, state management, controller/service conventions, testing, etc.). Useful when starting work on a new project or onboarding to an unfamiliar codebase.

`PATTERNS.md` is local-only (added to `.gitignore`) and meant as a quick reference so patterns don't need to be re-explained every session.

## Usage

```
/generate-patterns
```

No arguments required. Run it from the project root.

## What it does

1. Checks whether `PATTERNS.md` already exists; if so, asks whether to regenerate or update it.
2. Reads `CLAUDE.md` (if present) and the project's dependency file (`package.json`, `Gemfile`, `go.mod`, etc.) to detect the stack.
3. Explores the codebase — structure, entry points, config, and stack-specific areas (frontend: pages/components/state/forms/styling; backend: controllers/services/models/jobs/auth).
4. Writes `PATTERNS.md` with a skeleton/template per pattern area — no business logic or project-specific data, just the shape to copy for new features.
5. Adds `PATTERNS.md` to `.gitignore` and, if `CLAUDE.md` exists, adds an instruction to read it at the start of each session.

## Updating

If `PATTERNS.md` already exists, the skill can update only the sections mentioned or do a full regeneration if asked — existing sections are preserved unless explicitly told to remove them.
