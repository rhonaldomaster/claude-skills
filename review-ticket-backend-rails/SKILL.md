---
name: review-ticket-backend-rails
description: |
  Fire when reviewing a Jira ticket for backend Rails readiness or implementation status against the current codebase.

  Use this skill to fetch the ticket, audit existing backend code, identify what is already implemented, flag gaps, and check for missing details in the ticket description. Optionally check Tambora test cases for a given suite name.

  Invoke explicitly with a Jira ticket ID, optionally followed by a Tambora suite name and `--qa` for QA mode.
user-invocable: true
argument-hint: '[ticket-id] [tambora-suite-name?] [--qa?]'
allowed-tools: Bash, Read, Glob, Grep, Agent
---

# Review Ticket

Parse `$ARGUMENTS` as follows:
- **First word** = Jira ticket ID (e.g. `MPP-221`)
- **`--qa` flag** (optional) = if present anywhere in the arguments, enable QA mode (see Step 8)
- **Remaining text after removing the ticket ID and `--qa`** (optional) = Tambora suite name (e.g. `MPP-150 Memories list view`)

You are performing a **ticket readiness analysis** for the Jira ticket ID extracted above.

## Steps

> **Mode detection:** Check for `--qa` in the arguments first.
> - **Normal mode** (no `--qa`): run Steps 1–7.
> - **QA mode** (`--qa` present): run Steps 1, 2a, and 8. Skip Steps 2b–7 (deep audit, gap analysis, ticket quality check, and other normal-mode-only review steps) — those are for the backend team only.

### 1. Fetch Ticket Details

Run `jira issue view <ticket-id> --plain` to get the full ticket details. Extract:

- Title and description
- Acceptance criteria
- Subtasks and their statuses
- Any linked issues

If the ticket has subtasks, also fetch each subtask with `jira issue view <subtask-id> --plain`.

### 2a. Backend Readiness Check *(both modes)*

Do a focused, quick scan to determine whether the feature is actually implemented and testable. Check:

- **Routes:** does a relevant API endpoint exist?
- **Controllers:** does the action exist and return the expected data?
- **Blueprints/Serializers:** are the fields the ticket requires present in the response?
- **Models:** do the relevant columns, scopes, or associations exist?

Use Grep and Glob directly — this should be fast. The goal is a simple yes/no per acceptance criterion: "is the backend ready for this to be tested?"

Present a short **Backend Readiness** table in the output:

| Acceptance Criterion | Backend Ready? | Notes |
|----------------------|---------------|-------|
| ...                  | Yes / No / Partial | ... |

If any criterion is **No** or **Partial**, flag it clearly so QA knows not to test it yet.

### 2b. Deep Backend Code Audit *(normal mode only)*

Based on the ticket requirements, search the codebase thoroughly for any existing implementations. Check:

- **Models:** relevant columns, associations, validations, scopes
- **Migrations:** any schema changes related to the feature
- **Controllers:** endpoints that serve or could serve the feature
- **Services:** business logic related to the feature
- **Routes:** API routes that match the feature's needs
- **Blueprints/Serializers:** how related data is serialized
- **Jobs:** any background processing related to the feature
- **Tests:** existing test coverage (request specs, model specs, swagger specs)
- **Mailers:** any email-related functionality

Use the Agent tool with subagent_type=Explore to search broadly across the codebase using keywords derived from the ticket.

### 3. Implementation Status Report *(normal mode only)*

For each requirement or acceptance criterion in the ticket, determine:

- **Implemented:** code exists and appears to satisfy the requirement
- **Partially implemented:** some code exists but is incomplete
- **Not implemented:** no relevant code found
- **Cannot determine:** ambiguous requirements or unclear mapping

### 4. Gap Analysis *(normal mode only)*

Identify gaps between what the ticket requires and what exists:

- Missing endpoints or incomplete implementations
- Acceptance criteria not covered by tests
- Missing validations or authorization checks
- Missing error handling for edge cases

### 5. Ticket Quality Check *(normal mode only)*

Review the ticket description itself for quality issues:

- **Ambiguities:** vague language, undefined terms, or unclear scope
- **Missing error states:** what happens when things go wrong?
- **Missing edge cases:** scenarios the ticket doesn't address (e.g., concurrency, rate limiting, pagination, token expiry, cleanup)
- **Open decisions:** items marked as "TBD", "decision required", or similar
- **Missing technical details:** undefined payload formats, response schemas, status codes
- **Security considerations:** are there any unaddressed auth, access control, or data exposure concerns?

## Output Format

**Normal mode** — full report:

```
## Ticket: [TICKET-ID] — [Title]

### Summary
Brief description of what the ticket asks for.

### Status
Current ticket status and subtask statuses.

### Backend Implementation Audit

#### What Already Exists
- List each piece of existing code with file paths and line numbers
- Group by category (models, controllers, services, etc.)

#### What Is Missing
- List any requirements that have no backend support yet

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

### Backend Readiness

| Acceptance Criterion | Backend Ready? | Notes |
|----------------------|---------------|-------|
| ...                  | Yes / No / Partial | ... |

> If any row is No or Partial, warn QA not to test those scenarios yet.

### Tambora Test Cases — [Suite Name]

| Code | Title | Severity | Testable? |
|------|-------|----------|-----------|
| ...  | ...   | ...      | Yes / No / Partial |
```

The **Testable?** column cross-references each test case against the Backend Readiness table — if the backend isn't ready for a given scenario, mark it as not testable yet.

Then proceed directly to Step 8 to record results.

### 6. Tambora Test Case Coverage *(normal mode only — skip in QA mode)*

**Only run this step if a Tambora suite name was provided and `--qa` is NOT present.**

1. Call `mcp__tambora__check_connectivity`. If it returns `reachable: false`, skip this step and note that Tambora is unavailable.
2. Call `mcp__tambora__list_test_cases` with the suite name extracted from the arguments (and module if identifiable from context).
3. For each test case returned, assess backend coverage using what you found in Steps 2–4:
   - **Fully covered** — backend implemented + existing spec exercises this scenario
   - **Backend supports it, no spec** — implementation exists but no test asserts it
   - **Partially covered** — some support exists but a known gap remains (describe the gap)
   - **Not implemented** — no backend support found
   - **Frontend only** — no backend action needed
4. Present the results as a coverage table with columns: Code | Title | Coverage Status | Notes
5. Highlight any test cases that reveal missing backend features not already flagged in the Gap Analysis.

### 7. Post Report to Jira *(normal mode only)*

After presenting the report, ask the user:

> "Would you like me to post any of these findings as a comment on a Jira ticket? If so, which ticket(s)?"

If the user says yes:

1. Ask which ticket(s) to comment on (it could be the main ticket, a subtask, or any other ticket ID).
2. Prepare a **professional, concise** version of the relevant findings for the Jira comment. Use a neutral, professional tone — no emojis, nicknames, or playful language.
3. Show the user the comment text and ask for confirmation before posting.
4. Post the comment by piping the body via stdin: `cat <<'EOF' | jira issue comment add <TICKET-ID> --template -\n<comment body>\nEOF`
5. Confirm once posted successfully.

The user may want to post different parts of the report to different tickets (e.g., quality issues to the parent ticket, implementation gaps to a subtask, Tambora coverage to the FE ticket). Support this by asking which sections to include for each ticket.

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
