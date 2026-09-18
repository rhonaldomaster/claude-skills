---
name: generate-agent-rules
description: Generate a per-stack code guidelines file for a project (docs/agent-rules/<stack>.md) from this repo's pr-cycle review rules, then wire a short pointer to it into the project's CLAUDE.md or AGENTS.md. Use when the user wants to set up coding rules for agents in a project, asks to "generate rules", or wants CLAUDE.md/AGENTS.md kept short while still enforcing stack conventions.
---

# Generate Agent Rules

Turns this repo's `pr-cycle` review rules (the checks used to review PRs) into a code
guidelines file for the target project, then points the project's `CLAUDE.md`/`AGENTS.md` at
it with one short line — instead of pasting every rule into the agent config and bloating it.

This skill only writes guideline docs and a pointer. It does not review code and does not
implement anything.

## Step 1: Detect Stack

Run in the target project's root, using the same detection table as `plan-ticket` /
`dev-workflow`:

| Check (in priority order)                                                      | Stack     | Source rules (`pr-cycle` skill) |
| -------------------------------------------------------------------------------| --------- | -------------------------------- |
| `Gemfile` exists AND contains `rails`                                          | Rails     | `backend-rails`                  |
| `package.json` exists AND contains `next`                                     | Next.js   | `frontend-nextjs`                |
| `composer.json` exists AND contains `yiisoft/yii2`                            | PHP Yii2  | `backend-yii2`                   |
| `style.css` with `Theme Name:` header OR `functions.php` with WordPress hooks | WordPress | `backend-wordpress`              |
| `config/settings_schema.json` OR `templates/*.json` + `sections/*.liquid`     | Shopify   | `frontend-shopify`               |

If the stack cannot be detected, or more than one stack is present (e.g. a Next.js frontend
alongside a Rails API), ask the user which stack(s) to generate rules for.

## Step 2: Extract Source Rules

Read the corresponding skill file from this repo's `pr-cycle` plugin:

`<this-repo>/pr-cycle/skills/<stack>/SKILL.md`

Where `<stack>` is one of: `backend-rails`, `frontend-nextjs`, `backend-yii2`,
`backend-wordpress`, `frontend-shopify`.

Extract only the **"Step 3: Code Quality Review"** section — the numbered rules (`Rule 0`
through `Rule N`) with their priority tier (HIGH / MEDIUM / LOW) and bad/good code examples.
Ignore everything else in that file (PR metadata fetching, Jira, GitHub review API, Tambora) —
none of that belongs in agent guidelines.

If this repo's `pr-cycle` plugin is not available (e.g. running against a project that doesn't
have this skills repo checked out), ask the user for the rules source or fall back to well-known
conventions for the detected stack, and say explicitly that you're not using the pr-cycle rules.

## Step 3: Rewrite as Positive Guidelines

Convert each rule from "flag X when reviewing" into "write it this way" guidance, so an agent
reads it once and writes correct code from the start rather than getting corrected after the
fact. Keep the bad/good examples — they're already in the right format.

Group by priority, security/correctness first:

1. **Security & correctness** (the rules marked HIGH PRIORITY — injection, XSS, missing auth,
   missing validation, N+1, debug leftovers)
2. **Structure & conventions** (MEDIUM PRIORITY — logic placement, fat controllers, naming,
   repetitive markup)
3. **Style & cleanliness** (LOW PRIORITY — dead code, indentation, wrappers)

Rewrite pattern, per rule:

```markdown
### <Positive instruction derived from the rule title>

<One or two lines: what to do and why, adapted from the rule's flag description.>

\`\`\`<lang>
// Bad
<bad example from source rule>

// Good
<good example from source rule>
\`\`\`
```

Example — Rails Rule 1 ("N+1 Queries") becomes:

```markdown
### Eager-load associations accessed in loops

Use `.includes`, `.preload`, or `.eager_load` when a loop accesses an association — avoid N+1
queries. Applies to controllers, serializers, and views alike.

\`\`\`ruby
// Bad
Post.all.each { |post| post.author.name }

// Good
Post.includes(:author).each { |post| post.author.name }
\`\`\`
```

Keep the file scannable: one `##` heading per priority group, one `###` per rule, no filler
prose between rules.

## Step 4: Write the Guidelines File

Write to `docs/agent-rules/<stack>.md` in the target project (create the directory if needed).

If the file already exists, ask whether to overwrite it or merge (append rules not already
present, keep the rest untouched) — do not silently overwrite prior edits.

File header:

```markdown
# <Stack> Code Guidelines

Rules an agent should follow when writing or reviewing <stack> code in this project. Derived
from the pr-cycle review checks so code passes review on the first try.

<!-- rule groups from Step 3 go here -->
```

## Step 5: Wire the Pointer into CLAUDE.md / AGENTS.md

Find `CLAUDE.md` or `AGENTS.md` at the target project root (prefer whichever already exists; if
both exist, ask which one to update; if neither exists, ask which one to create).

Insert or update a marked, idempotent block — never touch anything outside these markers:

```markdown
<!-- BEGIN generated-rules: <stack> -->
## Code style

When writing or reviewing <stack> code, read `docs/agent-rules/<stack>.md` first.
<!-- END generated-rules: <stack> -->
```

- If a block with the same `<stack>` marker already exists, replace only its contents.
- If the file has blocks for other stacks (multi-stack project), leave those untouched and add
  a new block for this stack.
- If neither `CLAUDE.md` nor `AGENTS.md` exists yet, ask the user which filename to create
  before writing anything.

## Step 6: Confirm

Present:
1. The path to the guidelines file written (or merged)
2. The exact block added/updated in `CLAUDE.md`/`AGENTS.md`
3. How many rules were carried over, grouped by priority

## Important Rules

- **Do not paste the full rule list into `CLAUDE.md`/`AGENTS.md`** — that's the problem this
  skill exists to avoid. Only the pointer block goes there.
- **Do not modify source code** — this skill only writes docs and the pointer block.
- **Do not invent rules** not present in the source `pr-cycle` skill, unless the user explicitly
  asks for additions — note any addition as user-requested, separate from the derived rules.
- **Ask before overwriting** an existing guidelines file or a differently-scoped section of
  `CLAUDE.md`/`AGENTS.md`.
