---
name: pr-cycle
description: |
  Full PR cycle review for Rails, WordPress, PHP Yii2, Next.js, or Shopify theme PRs. Detects the stack automatically, reviews code quality against stack-specific rules, and cross-references the linked Jira ticket's acceptance criteria. Leaves inline GitHub comments and optionally moves the Jira ticket to QA when the PR is approved.

  Invoke with a PR number (required), optional Jira ticket ID, and optional Tambora suite name.
  Examples:
  - `/dev-workflow:pr-cycle 42`
  - `/dev-workflow:pr-cycle 42 MPP-221`
  - `/dev-workflow:pr-cycle 42 MPP-221 "MPP-150 Memories list view"`
user-invocable: true
argument-hint: '<PR_NUMBER> [JIRA_TICKET_ID?] [tambora-suite-name?]'
allowed-tools: Bash, Read, Glob, Grep, Agent
model: opus
effort: xhigh
---

# PR Cycle Review

Parse `$ARGUMENTS` as follows:
- **First token** = PR number (required, e.g. `42`)
- **Second token** (optional) = Jira ticket ID in `PROJECT-NNN` format (e.g. `MPP-221`). Detected by matching the pattern `[A-Z]+-[0-9]+`.
- **Remaining text** after removing the PR number and ticket ID = Tambora suite name (optional, e.g. `MPP-150 Memories list view`)

Set `COMMENT_LANGUAGE=es` for Spanish comments or `COMMENT_LANGUAGE=en` for English (default: `en`).

**Ticket ID auto-inference:** If no Jira ticket ID was provided in `$ARGUMENTS`, fetch the PR title and extract the ticket ID from it using the pattern `\[([A-Z]+-\d+)\]`. Example: a PR titled `[MPP-221] Add payment flow` → infer `TICKET_ID=MPP-221`. Only use the inferred ID if no explicit one was provided.

---

## Step 0: Detect Stack & Load Rules

Read `<plugin-root>/references/stack-detection.md` and follow its table to detect the project
stack. Then map the detected stack to this skill's stack file:

| Stack     | Stack file             |
| --------- | ----------------------- |
| Rails     | `stacks/rails.md`      |
| Next.js   | `stacks/nextjs.md`     |
| PHP Yii2  | `stacks/yii2.md`       |
| WordPress | `stacks/wordpress.md`  |
| Shopify   | `stacks/shopify.md`    |

Once detected, read the corresponding stack file from `<skill-base-dir>/stacks/<stack>.md`. Each
field's value is its first non-blank line after the field's `##` heading; any prose after that
line is explanatory and not part of the value. A field with no non-blank line before the next
`##` heading is empty. It defines:

- **File → Ruleset Map** — which rule sets apply to which changed files (used in Step 2)
- **Diff Example** — a stack-specific example for reading diff line numbers (used in Step 2)
- **Code-Fence Language** — the language tag for multi-line suggestion blocks (used in Step 5 & 6)
- **Stack Label (en)** / **Stack Label (es)** — the stack name substituted into the summary-body
  templates (used in Step 5 & 6); may be empty for either language. The two are independent
  strings, not translations of each other — some stacks need a different grammatical form per
  language (see the note in `shopify.md` for the clearest example). Always use the label from the
  language matching `COMMENT_LANGUAGE`, and substitute it verbatim — never translate it yourself.
- **Tambora Orientation** — `backend` or `frontend`, decides which wording variant to use in the
  Step 8 coverage table
- **Example Phrasings** — optional; if present, example en/es comment strings to draw from when
  writing inline comments for this stack
- **Code Quality Rules** — the numbered rules (`Rule 0` through `Rule N`) with priority tier
  (HIGH/MEDIUM/LOW) and bad/good code examples (used in Step 3)

**Follow the loaded stack file for all stack-specific content referenced in Steps 2, 3, 5 & 6,
and 8 below.**

---

## Step 1: Setup

Collect repository metadata and the latest commit SHA:

```bash
REPO_OWNER=$(gh repo view --json owner --jq '.owner.login')
REPO_NAME=$(gh repo view --json name --jq '.name')
COMMIT_SHA=$(gh pr view $PR_NUMBER --json commits --jq '.commits[-1].oid')
```

Fetch the PR metadata:

```bash
gh pr view $PR_NUMBER --json title,body,commits,author,reviewDecision,reviews,comments
```

**If `TICKET_ID` was not set from `$ARGUMENTS`**, extract it from the PR title using `\[([A-Z]+-\d+)\]`. If a match is found, set `TICKET_ID` to the captured group. If not found, leave `TICKET_ID` unset and proceed with code-only review.

Check for **existing review comments** (from Copilot, other reviewers, bots) so we don't duplicate issues already reported:

```bash
gh api repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER/comments --jq '[.[] | {author: .user.login, path: .path, line: .line, body: .body}]'
```

Keep the list of already-reported issues in memory. For each violation you find later, check whether it has already been commented on (same file + same line range + same issue type). If it has, **skip it**.

---

## Step 1a: Fetch Jira Ticket (if provided)

If a Jira ticket ID was extracted from the arguments:

```bash
jira issue view $TICKET_ID --plain
```

If the ticket has subtasks, also fetch each subtask:

```bash
jira issue view $SUBTASK_ID --plain
```

Extract:
- Acceptance criteria (AC)
- Feature description / scope
- Any subtask statuses

If no Jira ticket was provided, skip this step and proceed with code-only review.

---

## Step 2: Review the Diff

```bash
gh pr diff $PR_NUMBER
```

Study the full diff. Identify what types of files are changed and which rule sets apply, using
the **File → Ruleset Map** from the loaded stack file.

For each changed file, also determine which acceptance criteria (if any) the change maps to.

**Reading diff line numbers:**

Use the **Diff Example** from the loaded stack file as a reference for how to read hunk headers
for this stack's file types.

Count line numbers from the right side (`+`) of the `@@` hunk header. Always comment on the **exact line where the problem begins**.

---

## Step 3: Code Quality Review

Apply all rules from the loaded stack file's **Code Quality Rules** section to every changed
file, based on the file type detected in Step 2.

---

## Step 4: Acceptance Criteria Coverage (if Jira ticket provided)

For each acceptance criterion from the Jira ticket, determine whether the PR diff satisfies it:

| Acceptance Criterion | Status | Evidence (file:line) |
|----------------------|--------|----------------------|
| ...                  | Implemented / Partial / Missing / N/A | ... |

Flag any AC that is **not implemented** or only **partially implemented** — note it in the summary review comment.

---

## Step 5 & 6: Unified Review — Inline Comments + Summary in One Request

All inline comments and the summary body must be submitted as a **single review** in one API call. GitHub rejects `event="PENDING"` on the creation endpoint, so do NOT use a two-step create-then-submit approach. Instead, pass the `comments` array and `event` together in the initial POST.

Build the JSON payload, then submit it:

```bash
gh api repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER/reviews \
  --method POST \
  --input - <<EOF
{
  "commit_id": "$COMMIT_SHA",
  "event": "REQUEST_CHANGES",
  "body": "SUMMARY_BODY",
  "comments": [
    {
      "path": "FILE_PATH",
      "line": EXACT_LINE_NUMBER,
      "side": "RIGHT",
      "body": "COMMENT_TEXT"
    }
  ]
}
EOF
```

For **multi-line comments** (problem spans several lines), add `start_line` and `start_side`:

```json
{
  "path": "FILE_PATH",
  "start_line": START_LINE_NUMBER,
  "start_side": "RIGHT",
  "line": END_LINE_NUMBER,
  "side": "RIGHT",
  "body": "COMMENT_TEXT"
}
```

**Notes:**
- `line` = exact file line number in the new version (right side of diff)
- `side` = `"RIGHT"` for additions/modifications, `"LEFT"` for deletions
- Use ` ```suggestion ` blocks for single-line fixes (enables one-click apply in GitHub UI)
- Use the loaded stack file's **Code-Fence Language** for multi-line suggestion blocks
- If there are **no inline comments**, omit the `"comments"` key entirely (empty array is also valid)
- If the loaded stack file has an **Example Phrasings** section, draw from it when writing inline comment text for this stack

When writing the summary body and any inline comment text, follow the user's global prose style rules: no em dash, short sentences, active voice, one word per concept, no long noun strings.

### Summary body — violations found

**COMMENT_LANGUAGE=en:**
```
Review completed: [X] comments left in the code

**Summary:**
- [Brief list of issue categories found]

**Acceptance criteria coverage:**
- [AC status summary if Jira ticket was provided]

**Positive observations:**
- [Things done well]

_Lead review bot_
```

**COMMENT_LANGUAGE=es:**
```
Revision completada: [X] comentarios dejados en el codigo

**Resumen:**
- [Breve lista de categorias de issues encontrados]

**Cobertura de criterios de aceptacion:**
- [Resumen del estado de los ACs si se proporcionó un ticket de Jira]

**Observaciones positivas:**
- [Cosas bien hechas]

_Lead review bot_
```

### Summary body — no violations (approve)

Use `"event": "APPROVE"` in the payload instead of `"REQUEST_CHANGES"`. Include the Acceptance
criteria line only if `TICKET_ID` was set — omit it entirely for code-only reviews. Use the
loaded stack file's **Stack Label (en)** or **Stack Label (es)** (matching `COMMENT_LANGUAGE`) in
place of `<STACK_LABEL>` below. If the matching label is empty, drop it entirely rather than
leaving a double space — e.g. "Code follows project standards" instead of "<STACK_LABEL> code
follows project standards". Substitute the label verbatim; do not translate it yourself even if
the two languages' labels aren't literal translations of each other.

**COMMENT_LANGUAGE=en:**
```
No violations found. <STACK_LABEL> code follows project standards.

**Acceptance criteria:** All criteria from $TICKET_ID are addressed in this PR.

_Lead review bot_
```

**COMMENT_LANGUAGE=es:**
```
Sin violaciones. El codigo <STACK_LABEL> sigue los estandares del proyecto.

**Criterios de aceptacion:** Todos los criterios de $TICKET_ID estan cubiertos en este PR.

_Lead review bot_
```

---

## Step 7: Post-Approval — Move Ticket to QA (if approved)

**Only run this step if the PR was approved (no violations) AND a Jira ticket ID was provided.**

Ask the user:

> "The PR looks good! Would you like me to move `$TICKET_ID` to the QA column and leave a comment on the ticket?"

If the user says yes:

1. Ask for the target status/column name (e.g. `"QA"`, `"Ready for QA"`, `"In QA"`). Suggest common options if unsure.

2. Move the ticket:
```bash
jira issue move $TICKET_ID "TARGET_STATUS"
```

3. Draft a comment for the Jira ticket and show it to the user for confirmation before posting. Example:

```
PR #$PR_NUMBER has been reviewed and approved. Ready for QA testing.

PR link: [use `gh pr view $PR_NUMBER --json url --jq '.url'`]
```

4. After user confirms, post the comment:
```bash
cat <<'EOF' | jira issue comment add $TICKET_ID --template -
PR #PR_NUMBER has been reviewed and approved. Ready for QA testing.

PR: URL_HERE
EOF
```

5. Confirm to the user: "Done! `$TICKET_ID` moved to `TARGET_STATUS` and comment posted."

---

## Step 8: Tambora Test Case Coverage (if suite name provided)

**Only run if a Tambora suite name was provided.**

1. Call `mcp__tambora__check_connectivity`. If `reachable: false`, skip and note unavailability.

2. Call `mcp__tambora__list_test_cases` with the suite name extracted from arguments.

3. For each test case, cross-reference against the PR diff and AC coverage from Step 4. Use the
   coverage status wording that matches the loaded stack file's **Tambora Orientation**:
   - `backend` stacks: `Fully covered / Backend supports it, no spec / Partial / Not implemented / Frontend only`
   - `frontend` stacks: `Fully covered / UI exists, no test / Partial / Not implemented / Backend only`

| Code | Title | Coverage Status | Notes |
|------|-------|-----------------|-------|
| ...  | ...   | (see wording above) | ... |

4. Highlight test cases that reveal missing features (on the side matching this stack's
   Tambora Orientation) not already flagged in Step 4.

5. Ask the user if they want to record test run results:

> "Would you like to record test run results for this suite in Tambora?"

If yes, follow the QA recording flow:

- Ask if they have an existing test run code or need a new one.
- If new → call `mcp__tambora__create_test_run_from_suite` and confirm the run code.
- Walk through each test case one at a time asking for status: `passed / failed / skipped / broken`.
- For `failed` or `broken`, also ask for an optional error message.
- Collect all results, show a summary, then ask for confirmation before submitting.
- Call `mcp__tambora__add_test_run_results` with all collected results in one batch.
- Ask if the run should be marked complete → call `mcp__tambora__complete_test_run` if yes.
- Confirm final state to the user (run code, accepted/rejected count, completion status).
