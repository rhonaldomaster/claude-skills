---
name: refine-ticket
description: Analyze a Jira ticket and suggest improvements for clarity — adds motivation, scope, and acceptance criteria. Use when the user wants to improve a ticket, says "refine ticket", or asks to make a ticket clearer.
arguments:
  - name: TICKET_ID
    description: "Jira ticket key (e.g., 'PST-154'). Must include the project prefix."
    required: true
model: best
effort: high
---

# Refine Ticket

Analyze a Jira ticket and produce an improved version with clear motivation, scope, and acceptance criteria. This skill drafts improvements and asks for confirmation before updating Jira.

## Step 1: Read the Ticket

Run both commands in parallel:

```bash
jira issue view <TICKET_ID> --plain
jira issue view <TICKET_ID> --comments 10 --plain
```

Extract:
- Summary (title)
- Description (full text)
- Acceptance criteria (if any)
- Labels, priority, linked issues
- Comments that may contain hidden context or requirements

## Step 2: Load Project Context

Read the following files if they exist in the current working directory (in parallel):

1. `CLAUDE.md` — stack, architecture, module list, conventions
2. `PATTERNS.md` — recurring implementation patterns specific to this project

Use this context to:
- Understand which modules or layers the ticket touches
- Infer technical implications the ticket author may have left implicit
- Tailor acceptance criteria to match project conventions (e.g., migration commands, test commands, config file locations)

## Step 3: Analyze What's Missing

Evaluate the ticket against these dimensions:

| Dimension | Question to answer |
|---|---|
| **Motivation** | Why is this change needed? Is it a deprecation, bug, compliance issue, performance problem? |
| **Scope** | Which files, modules, or configs are affected? Is the surface area clear? |
| **Acceptance Criteria** | Are there verifiable, testable conditions for "done"? |
| **Risks** | Are there regressions, breaking changes, or environment-specific concerns? |
| **Missing details** | Are there ambiguous terms, unnamed accounts, vague actions ("update", "fix", "test")? |

## Step 4: Draft the Improved Description

Write the improved description in **English** using this structure:

```
**Motivation:**
<Why this change is needed — deprecation notice, bug, compliance, performance, etc.>

**Scope:**
- <File or component 1>: <what changes>
- <File or component 2>: <what changes>
- <Config file if applicable>: <what changes>

**<Named list if applicable — e.g., Accounts to verify, Endpoints to test>:**
- item 1
- item 2

**Acceptance Criteria:**
- [ ] <Verifiable condition 1>
- [ ] <Verifiable condition 2>
- [ ] <No regressions in <affected area>>
```

Rules for the draft:
- Use plain English, no jargon unless it matches the project stack
- Acceptance criteria must be testable — avoid "works correctly", prefer "returns HTTP 200" or "no errors in logs"
- Reference actual file paths from the project when known (use CLAUDE.md context)
- Keep it concise — clarity over completeness

## Step 5: Present & Confirm

Show the user:
1. A brief **analysis** of what was missing from the original ticket (2–4 bullet points)
2. The full **improved description** as a preview

Then ask: **"Should I update the Jira ticket with this description?"**

Do NOT update Jira until the user explicitly confirms.

## Step 6: Update Jira (only after confirmation)

```bash
jira issue edit <TICKET_ID> -b "<improved description>" --no-input
```

Confirm success and show the Jira URL.

## Important Rules

- Always write the improved description in **English**
- Never update Jira without explicit user confirmation
- Do not modify the ticket summary unless the user asks
- Do not add labels, assignees, or priority changes unless asked
- If the ticket already has good motivation and ACs, say so — don't pad it unnecessarily
