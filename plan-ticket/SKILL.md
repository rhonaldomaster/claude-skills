---
name: plan-ticket
description: Read a Jira ticket and generate a structured implementation plan. Use when the user wants to plan a ticket, mentions planning a Jira issue, or says "plan ticket".
arguments:
  - name: TICKET_ID
    description: "Jira ticket key (e.g., 'MPP-650'). Must include the project prefix."
    required: true
---

# Plan Ticket

Generate a structured implementation plan from a Jira ticket. This skill creates a plan file — it does NOT implement anything.

## Step 1: Resolve Ticket ID

- `$TICKET_ID` must include the project prefix (e.g., `MPP-650`, `KMB-123`)
- Use lowercase for folder naming (e.g., `mpp-650`)

## Step 2: Read the Jira Ticket

1. Run `jira issue view <TICKET_ID> --plain` to get the ticket details
2. Run `jira issue view <TICKET_ID> --comments 10 --plain` if comments may contain additional context or acceptance criteria
3. Extract from the output:
   - Summary (title)
   - Description (full text)
   - Acceptance criteria (if present)
   - Labels, priority, linked issues
4. Create the plan folder. Use the tool or method appropriate for the environment:
   - On macOS/Linux: `mkdir -p .docs/plans/<ticket-id-lowercase>/`
   - On Windows (PowerShell): `New-Item -ItemType Directory -Force -Path ".docs/plans/<ticket-id-lowercase>/"`
   - Or use the AI tool's built-in file creation capabilities if available

5. Check for attachments using the raw JSON output. If there are image attachments, extract and download them:
   ```bash
   # Extract attachment URLs from the Jira API response
   jira issue view <TICKET_ID> --raw | python -c "
   import sys, json
   data = json.load(sys.stdin)
   for a in data.get('fields', {}).get('attachment', []):
       print(a['filename'], a['content'])
   "
   ```
   > Note: Use `python` or `python3` depending on the system. Both are equivalent here.

   Then download each attachment using the Jira CLI login:
   ```bash
   # Read the Jira login from the config file
   # macOS/Linux:
   JIRA_LOGIN=$(grep '^login:' ~/.config/.jira/.config.yml | awk '{print $2}')
   # Windows (PowerShell):
   # $JIRA_LOGIN = (Select-String -Path "$env:USERPROFILE\.config\.jira\.config.yml" -Pattern "^login:" | ForEach-Object { $_.Line.Split(" ")[1] })

   curl -s -L -u "$JIRA_LOGIN:$JIRA_API_TOKEN" -o ".docs/plans/<ticket-id>/<filename>" "<content-url>"
   ```
   > If `curl` is not available, use the AI tool's built-in HTTP/fetch capabilities to download the file.

## Step 3: Detect Stack & Load Rules

Detect the project stack by checking files in the current working directory:

| Check (in priority order)                                          | Stack     |
| ------------------------------------------------------------------ | --------- |
| `Gemfile` exists AND contains `rails`                              | Rails     |
| `package.json` exists AND contains `next`                          | Next.js   |
| `composer.json` exists AND contains `yiisoft/yii2`                 | PHP Yii2  |
| `style.css` exists with `Theme Name:` header OR `functions.php` with WordPress hooks | WordPress |
| `config/settings_schema.json` exists OR `templates/*.json` + `sections/*.liquid` exist | Shopify   |

Once detected, read the corresponding stack rules file from the skill's base directory:

- **Rails**: `<skill-base-dir>/stacks/rails.md`
- **Next.js**: `<skill-base-dir>/stacks/nextjs.md`
- **PHP Yii2**: `<skill-base-dir>/stacks/php-yii2.md`
- **WordPress**: `<skill-base-dir>/stacks/wordpress.md`
- **Shopify**: `<skill-base-dir>/stacks/shopify.md`

The stack file defines:
- Which Explore agents to launch and what they should investigate
- Stack-specific plan sections (e.g., Database Changes for Rails, Component Structure for Next.js)
- Verification commands (e.g., `rspec` vs `pnpm test:run`)

**Follow the instructions in the loaded stack file for Steps 3a (Explore) and the stack-specific sections in Step 4.**

If the stack cannot be detected, ask the user which stack to use before proceeding.

## Step 3a: Explore the Codebase

Investigate the codebase based on the loaded stack rules file. The stack file defines up to 3 areas of exploration that should be performed in parallel when possible.

- **Claude Code**: Launch up to 3 Explore agents in parallel (Agent tool with subagent_type=Explore)
- **Cursor / Windsurf / other AI tools**: Perform the same searches sequentially using the available codebase search tools
- **Manual use**: Use the exploration checklist as a guide for what to investigate

**Important**: If the scope is unclear after exploration, **ask the user** before finalizing the plan.

If the ticket mentions functionality that overlaps with existing code, verify whether it can be extended before proposing new implementations.

## Step 4: Generate the Plan

Write the plan to `.docs/plans/<ticket-id-lowercase>/plan.md` using this structure:

```markdown
# <TICKET-ID>: <Summary from Jira>

## Context

<Why this change is needed, based on ticket description.>
<Mention affected areas of the codebase if relevant.>
<Reference attachments: `.docs/plans/<ticket-id>/filename.png` if any.>

## Files to Modify/Create

| File   | Action | Description |
| ------ | ------ | ----------- |
| `path` | Modify | What change |
| `path` | Create | What it is  |

## Reusable Code (no changes needed)

- List existing code that can be leveraged as-is
- Include base classes, shared concerns, utilities, hooks, etc.

<!-- STACK-SPECIFIC SECTIONS GO HERE -->
<!-- Loaded from the stack rules file (e.g., Database Changes, Component Structure, etc.) -->

## Implementation Steps

### 1. Step title

**File:** `path/to/file`
<Exact location (line numbers where possible), code blocks with copy-pasteable code.>

### 2. Step title

...

## Testing

<!-- Testing sections as defined by the stack rules file -->

## Browser Testing (optional)

> If the `agent-browser` skill is available in the project, include a section with manual or automated browser test scenarios:

- **Preconditions**: What state the app needs to be in
- **Scenarios**: Step-by-step actions and expected outcomes
- **Tip**: These can be executed with `/agent-browser` after implementation

> If `agent-browser` is not available, omit this section entirely.

## Verification

- Manual QA checklist:
  - <Specific checks based on the feature, one per line>
- <Verification commands from the stack rules file>
```

### Plan Quality Guidelines

- **Be prescriptive**: Include exact file paths, line numbers, and copy-pasteable code blocks
- **Reuse over create**: Always reference existing code before proposing new implementations
- **Respect project conventions**: Follow the existing code patterns defined in the project's configuration (e.g., `CLAUDE.md`, `.cursorrules`, `.windsurfrules`, or equivalent)
- **Keep it scannable**: Use tables, numbered lists, and clear headings

## Step 5: Present Summary & Ask Questions

After generating the plan:

1. Show a brief summary of what the plan covers (files to change, new items, estimated scope)
2. Ask the user about any ambiguities found during exploration:
   - Architectural decisions not clear from the ticket
   - Whether existing code should be extended or new code created
   - Design decisions that could go either way

## Important Rules

- **DO NOT implement anything** — this skill only creates the plan file and folder
- **DO NOT create a git branch** — branch creation happens when implementation begins (confirm branch name and base with user)
- **DO NOT modify any source code files** — only create files inside `.docs/plans/`
- **Always ask the user** when scope is uncertain or architectural decisions are needed
- **Always prioritize** existing code and patterns over creating new ones
- **Always read the project's configuration file** (`CLAUDE.md`, `.cursorrules`, `.windsurfrules`, or equivalent) if present, to follow project-specific conventions
