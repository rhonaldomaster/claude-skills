---
name: review-ticket-frontend-nextjs
description: Review a Jira ticket against the frontend codebase. Fetches the ticket, audits existing Next.js/React implementation, identifies what is already built, flags gaps, and checks for missing details in the ticket description. Optionally checks Tambora test cases for a given suite name.
user-invocable: true
argument-hint: '[ticket-id] [tambora-suite-name?] [--qa?]'
---

# Review Ticket (Frontend)

Parse `$ARGUMENTS` as follows:
- **First word** = Jira ticket ID (e.g. `MPP-221`)
- **`--qa` flag** (optional) = if present anywhere in the arguments, enable QA mode (see Step 8)
- **Remaining text after removing the ticket ID and `--qa`** (optional) = Tambora suite name (e.g. `MPP-150 Memories list view`)

You are performing a **ticket readiness analysis** for the Jira ticket ID extracted above.

The target codebase is the **MyParkPlanner frontend**: Next.js 16, React 19, TypeScript 5, Tailwind CSS 4, Auth.js 5, Zod 4, Vitest.

## Steps

> **Mode detection:** Check for `--qa` in the arguments first.
> - **Normal mode** (no `--qa`): run Steps 1–7.
> - **QA mode** (`--qa` present): run Steps 1, 2a, 6, 7, and 8. Skip Steps 2b–5 (deep audit, gap analysis, ticket quality check) — those are for the frontend developer only.

### 1. Fetch Ticket Details

Run `jira issue view <ticket-id> --plain` to get the full ticket details. Extract:

- Title and description
- Acceptance criteria
- Subtasks and their statuses
- Any linked issues

If the ticket has subtasks, also fetch each subtask with `jira issue view <subtask-id> --plain`.

### 2a. Frontend Readiness Check *(both modes)*

Do a focused, quick scan to determine whether the feature is actually built and testable. Check:

- **Pages:** does a relevant page or route exist under `src/app/`?
- **Components:** do the UI components the ticket requires exist?
- **API client:** does `src/lib/api/` have a function that calls the relevant backend endpoint?
- **Types/schemas:** do the TypeScript types or Zod schemas for the feature exist?
- **Auth/guards:** are protected routes or role checks wired up where needed?

Use Grep and Glob directly — this should be fast. The goal is a simple yes/no per acceptance criterion: "is the frontend ready for this to be tested?"

Present a short **Frontend Readiness** table in the output:

| Acceptance Criterion | Frontend Ready? | Notes |
|----------------------|----------------|-------|
| ...                  | Yes / No / Partial | ... |

If any criterion is **No** or **Partial**, flag it clearly so QA knows not to test it yet.

### 2b. Deep Frontend Code Audit *(normal mode only)*

Based on the ticket requirements, search the codebase thoroughly for any existing implementations. Use the Agent tool with subagent_type=Explore to search broadly. Check:

- **Pages & layouts:** `src/app/` — route segments, page.tsx, layout.tsx, loading.tsx, error.tsx
- **Route handlers:** `src/app/api/` — any Next.js API routes related to the feature
- **Components:** `src/components/` and co-located `_components/` folders — existing UI elements, props, variants
- **Storybook stories:** `__stories__/` folders — whether components are documented
- **API client functions:** `src/lib/api/` — fetcher functions, types, mocks
- **Custom hooks:** `src/lib/hooks/` — state management, data fetching hooks
- **Utilities & constants:** `src/lib/utils/`, `src/lib/constants/`
- **TypeScript types & Zod schemas:** `src/types/`, `*.types.ts` files
- **Auth & middleware:** `middleware.ts`, `src/lib/auth/`, `src/components/auth/`
- **Tests:** `__tests__/` folders, `*.test.tsx` files — Vitest unit and integration test coverage
- **Accessibility:** ARIA attributes, semantic HTML, keyboard navigation in components

### 3. Implementation Status Report *(normal mode only)*

For each requirement or acceptance criterion in the ticket, determine:

- **Implemented:** code exists and appears to satisfy the requirement
- **Partially implemented:** some code exists but is incomplete
- **Not implemented:** no relevant code found
- **Cannot determine:** ambiguous requirements or unclear mapping

### 4. Gap Analysis *(normal mode only)*

Identify gaps between what the ticket requires and what exists:

- Missing pages or route segments
- Missing or incomplete components (props, variants, states)
- Missing API client functions or type definitions
- Acceptance criteria not covered by Vitest tests
- Missing loading, error, or empty states
- Missing accessibility attributes (ARIA labels, keyboard nav, focus management)
- Missing Storybook stories for new/changed components
- Missing mobile-first responsive behavior (Tailwind breakpoints: sm:640, md:768, lg:1024, xl:1280)
- Missing auth guards or role checks

### 5. Ticket Quality Check *(normal mode only)*

Review the ticket description itself for quality issues:

- **Ambiguities:** vague language, undefined terms, or unclear scope
- **Missing UI states:** loading, empty, error states not specified
- **Missing edge cases:** scenarios the ticket doesn't address (e.g., offline, pagination, token expiry, concurrent edits)
- **Missing design specs:** no Figma link, missing responsive behavior, missing dark/light mode spec
- **Open decisions:** items marked as "TBD", "decision required", or similar
- **Missing technical details:** undefined API payloads, response shapes, or status codes
- **Accessibility gaps:** no mention of ARIA, keyboard nav, or screen reader requirements
- **Security considerations:** unaddressed auth, access control, or sensitive data exposure

## Output Format

**Normal mode** — full report:

```
## Ticket: [TICKET-ID] — [Title]

### Summary
Brief description of what the ticket asks for.

### Status
Current ticket status and subtask statuses.

### Frontend Implementation Audit

#### What Already Exists
- List each piece of existing code with file paths and line numbers
- Group by category (pages, components, API client, hooks, types, tests, etc.)

#### What Is Missing
- List any requirements that have no frontend implementation yet

### Acceptance Criteria Coverage

| Criterion | Status | Evidence |
|-----------|--------|----------|
| ...       | ...    | ...      |

### Ticket Quality Issues
- List any ambiguities, missing details, or open decisions
- Suggest specific improvements to the ticket description

### Recommendations
- Actionable next steps for the team

### Tambora Test Case Coverage (if suite name provided)

| Code | Title | Coverage Status | Notes |
|------|-------|-----------------|-------|
| ...  | ...   | ...             | ...   |
```

**QA mode** (`--qa`) — trimmed report focused on testability:

```
## Ticket: [TICKET-ID] — [Title]

### Summary
Brief description of what the ticket asks for.

### Status
Current ticket status.

### Frontend Readiness

| Acceptance Criterion | Frontend Ready? | Notes |
|----------------------|----------------|-------|
| ...                  | Yes / No / Partial | ... |

> If any row is No or Partial, warn QA not to test those scenarios yet.

### Tambora Test Cases — [Suite Name]

| Code | Title | Severity | Testable? |
|------|-------|----------|-----------|
| ...  | ...   | ...      | Yes / No / Partial |
```

The **Testable?** column cross-references each test case against the Frontend Readiness table — if the frontend isn't ready for a given scenario, mark it as not testable yet.

Then proceed directly to Step 8 to record results.

### 6. Tambora Test Case Coverage *(normal mode only — skip in QA mode)*

**Only run this step if a Tambora suite name was provided and `--qa` is NOT present.**

1. Call `mcp__tambora__check_connectivity`. If it returns `reachable: false`, skip this step and note that Tambora is unavailable.
2. Call `mcp__tambora__list_test_cases` with the suite name extracted from the arguments (and module if identifiable from context).
3. For each test case returned, assess frontend coverage using what you found in Steps 2–4:
   - **Fully covered** — feature implemented + Vitest test exercises this scenario
   - **UI exists, no test** — component/page exists but no test asserts this scenario
   - **Partially covered** — some implementation exists but a known gap remains (describe the gap)
   - **Not implemented** — no frontend code found for this scenario
   - **Backend only** — no frontend action needed
4. Present the results as a coverage table with columns: Code | Title | Coverage Status | Notes
5. Highlight any test cases that reveal missing frontend features not already flagged in the Gap Analysis.

### 7. Post Report to Jira *(normal mode only)*

After presenting the report, ask the user:

> "Would you like me to post any of these findings as a comment on a Jira ticket? If so, which ticket(s)?"

If the user says yes:

1. Ask which ticket(s) to comment on (it could be the main ticket, a subtask, or any other ticket ID).
2. Prepare a **professional, concise** version of the relevant findings for the Jira comment. Use a neutral, professional tone — no emojis, nicknames, or playful language.
3. Show the user the comment text and ask for confirmation before posting.
4. Post the comment by piping the body via stdin: `cat <<'EOF' | jira issue comment add <TICKET-ID> --template -\n<comment body>\nEOF`
5. Confirm once posted successfully.

The user may want to post different parts of the report to different tickets (e.g., quality issues to the parent ticket, gap analysis to a subtask, Tambora coverage to the BE ticket). Support this by asking which sections to include for each ticket.

### 8. QA Mode — Record Test Run Results (Optional)

**Only run this step if `--qa` was present in the arguments AND a Tambora suite name was provided.**

This step walks QA through recording execution results for each test case, one at a time.

1. Call `mcp__tambora__check_connectivity`. If unreachable, abort and inform the user.

2. Ask the user:
   > "Do you have an existing test run code to reuse (e.g. TR-MPP-14)? If not, I'll create a new one."

   - If they provide a code → use it as `test_run_code` for the rest of this step.
   - If they say no → call `mcp__tambora__create_test_run_from_suite` with the module and suite name extracted from arguments. Use the returned `test_run_code` going forward. Confirm to the user: "Created test run [code]. Let's record results."

3. For each test case from the suite (use the list already fetched in Step 6), ask the user one at a time:
   > "[TC-MPP-XXXX] — [Title]
   > Status? (passed / failed / skipped / broken) — or press Enter to skip"

   - Collect the status. If `failed` or `broken`, also ask: "Any error message to record? (optional)"
   - Store each response; do NOT submit to Tambora yet — wait until all cases are answered.

4. After going through all test cases, show a summary of the collected results and ask:
   > "Ready to submit these results to Tambora? (yes / no)"

5. If confirmed → call `mcp__tambora__add_test_run_results` with all collected results in one batch.

6. Ask the user:
   > "Mark this test run as completed? (yes / no)"

   If yes → call `mcp__tambora__complete_test_run` with the `test_run_code`.

7. Confirm the final state to the user (run code, how many accepted/rejected, completion status).
