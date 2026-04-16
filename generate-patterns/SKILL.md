---
name: generate-patterns
description: Explore a project's codebase and generate a PATTERNS.md file documenting recurring implementation patterns. Use when starting work on a new project, onboarding to a codebase, or when the user says "generate patterns".
---

# Generate Patterns

Explore the current project's codebase and generate a `PATTERNS.md` file that documents recurring implementation patterns. This file serves as a quick-reference for future sessions so that patterns are followed consistently without the user having to re-explain them.

## When to Use

- Starting work on a new project that doesn't have a `PATTERNS.md`
- The user asks to document or generate patterns
- The user says `/generate-patterns`

## Pre-flight Checks

1. Check if `PATTERNS.md` already exists in the project root. If it does, ask the user whether to regenerate or update it.
2. Read the project's `CLAUDE.md` (if it exists) to understand the stack, structure, and conventions already documented.
3. Read `package.json`, `Gemfile`, `go.mod`, `requirements.txt`, or equivalent to identify the tech stack.

## Exploration Phase

Use the Explore agent to thoroughly analyze the codebase. Adapt the exploration areas to the detected stack, but always cover:

### For any project
- **Project structure**: Directory layout, key folders, naming conventions
- **Entry points**: How the app starts, routes, or main files
- **Configuration**: Environment setup, build tools, deployment

### For frontend projects (React, Next.js, Vue, Angular, etc.)
- **Page/Route structure**: How pages are organized, server vs client components, params handling
- **Component patterns**: Props, composition, conditional rendering, variants
- **State management**: Context, stores, hooks, data fetching (React Query, SWR, etc.)
- **Form patterns**: Validation, libraries, input components
- **Styling**: CSS approach, design tokens, responsive patterns
- **Dialog/Modal patterns**: Types available, when to use each
- **Navigation**: Routing utilities, back navigation, layout context
- **Icons/Assets**: Icon system, image handling

### For backend projects (Rails, Django, Express, Go, etc.)
- **Controller/Handler pattern**: Base classes, concerns/middleware, response format
- **Service/Use-case layer**: How business logic is organized
- **Serialization**: How responses are shaped (blueprints, serializers, DTOs)
- **Models/Entities**: Validations, scopes, associations, callbacks
- **Authorization**: Access control patterns
- **Background jobs**: Queue system, job structure
- **Error handling**: How errors are standardized
- **Database**: Migrations, queries, N+1 prevention

### For all projects
- **Testing**: Framework, conventions, file location, mocking patterns
- **API patterns**: How endpoints are structured, data fetching, error handling
- **Authentication**: Auth flow, session management

## Writing the PATTERNS.md

### Structure rules

1. **Title**: `# Project Patterns` with a one-line description of purpose.
2. **Sections**: One section per pattern area, with `## Section Title` and `---` separator.
3. **Code examples**: Show the minimal skeleton for each pattern — the template someone would copy to implement a new instance.
4. **No project-specific data**: Don't include actual business logic, route names, or model fields. Keep patterns generic/templated so they apply to new features.
5. **File references**: Mention key file paths only when they're structural (e.g., "Blueprints live in `app/blueprints/`"), not for specific implementations.
6. **Tables for quick reference**: Use tables to summarize variants, types, or options (e.g., dialog types, queue names, authorization levels).
7. **Keep it concise**: Each section should be scannable. If a pattern needs more than ~20 lines of example code, it's too detailed.

### What NOT to include

- Full file contents or large code blocks
- Business logic or domain-specific data
- Things already documented in CLAUDE.md (don't duplicate)
- Git workflows, CI/CD, deployment (those belong in CLAUDE.md or docs)
- Aspirational patterns that aren't actually used in the codebase

## Post-generation Steps

After creating `PATTERNS.md`:

1. **Add to `.gitignore`**: This file is local-only. Append `PATTERNS.md` to the project's `.gitignore` (in the AI/automation section if one exists).

2. **Add auto-read instruction to `CLAUDE.md`**: If the project has a `CLAUDE.md`, add this near the top (after any existing IMPORTANT notes):
   ```
   **IMPORTANT**: At the start of each session, if `PATTERNS.md` exists in the project root, read it before implementing any feature. It contains recurring patterns that must be followed for consistency.
   ```
   Adapt the parenthetical to mention the relevant pattern areas for the project's stack.

3. **Report to user**: Summarize the sections created in a table format.

## Updating an Existing PATTERNS.md

If the file already exists and the user wants to update it:

1. Read the current `PATTERNS.md`
2. Explore only the areas the user mentions, or do a full re-exploration if they say "regenerate"
3. Update the relevant sections, preserving sections that haven't changed
4. Do NOT remove sections unless the user explicitly asks

## Example Output Structure

```markdown
# Project Patterns

Recurring implementation patterns for this project. Consult this file before implementing new features to maintain consistency.

---

## Page Structure
[skeleton + key points]

---

## Components
[skeleton + key points]

---

## Data Fetching
[skeleton + key points]

(... more sections as needed ...)
```
