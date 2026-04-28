---
name: frontend-nextjs-pr-cycle
description: |
  Full PR cycle review for Next.js/React frontend PRs. Reviews code quality against team lead standards AND cross-references the linked Jira ticket's acceptance criteria. Leaves inline GitHub comments and optionally moves the Jira ticket to QA when the PR is approved.

  Invoke with a PR number (required), optional Jira ticket ID, and optional Tambora suite name.
  Examples:
  - `frontend-nextjs-pr-cycle 42`
  - `frontend-nextjs-pr-cycle 42 MPP-221`
  - `frontend-nextjs-pr-cycle 42 MPP-221 "MPP-150 Memories list view"`
user-invocable: true
argument-hint: '<PR_NUMBER> [JIRA_TICKET_ID?] [tambora-suite-name?]'
allowed-tools: Bash, Read, Glob, Grep, Agent
---

# Frontend Next.js PR Cycle Review

Parse `$ARGUMENTS` as follows:
- **First token** = PR number (required, e.g. `42`)
- **Second token** (optional) = Jira ticket ID in `PROJECT-NNN` format (e.g. `MPP-221`). Detected by matching the pattern `[A-Z]+-[0-9]+`.
- **Remaining text** after removing the PR number and ticket ID = Tambora suite name (optional, e.g. `MPP-150 Memories list view`)

Set `COMMENT_LANGUAGE=es` for Spanish comments or `COMMENT_LANGUAGE=en` for English (default: `en`).

---

## Step 0: Setup

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

Check for **existing review comments** (from Copilot, other reviewers, bots) so we don't duplicate issues already reported:

```bash
gh api repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER/comments --jq '[.[] | {author: .user.login, path: .path, line: .line, body: .body}]'
```

Keep the list of already-reported issues in memory. For each violation you find later, check whether it has already been commented on (same file + same line range + same issue type). If it has, **skip it**.

---

## Step 1: Fetch Jira Ticket (if provided)

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

Study the full diff. For each changed file, determine:
- What functionality was added or modified
- Which acceptance criteria (if any) each change maps to

**Reading diff line numbers:**

```diff
@@ -40,5 +40,8 @@ export default function MyComponent() {
  return (
    <div className="container">
-     <p>Old content</p>
+     <div className="px-4 py-2">        <- This is line 42
+       <button>Click</button>           <- This is line 43
+     </div>                             <- This is line 44
    </div>
  )
}
```

The numbers after `+` in the `@@` hunk header tell you the starting line in the new file. Count down from there. Always comment on the **exact line where the problem begins**.

---

## Step 3: Code Quality Review

Apply all rules below to every changed file.

### PR Metadata (check first)

#### Rule 0 — PR Title & Commit Messages
- PR title **must** include the Jira ticket number and a meaningful description.
- Commit messages **must** also reference the ticket.
- Reject vague titles: "initial commit", "update", "fix", "WIP", "changes".
- Expected format: `[TICKET-ID] Brief description of what changed`

### HIGH PRIORITY

#### Rule 1 — Unnecessary DIVs (flag every instance)
- Remove divs that wrap a single element without adding functionality.
- Move classes from the wrapper to the child.

```jsx
// Bad
<div><div className="content">Text</div></div>

// Good
<div className="content">Text</div>
```

Also applies to unnecessary `<p>` inside links and buttons:

```jsx
// Bad
<Link className="flex items-center p-4">
  <p className="text-black">My Link</p>
</Link>

// Good
<Link className="flex items-center p-4 text-black">
  My Link
</Link>

// Exception — multiple semantic blocks inside are fine
<Link className="flex flex-col p-4">
  <p className="text-lg font-bold">Title</p>
  <p className="text-sm text-gray-600">Description</p>
</Link>
```

#### Rule 2 — Forgotten `console.log`
- Never leave `console.log()` in production code.

#### Rule 3 — Duplicate Files
- Check if images/assets already exist under another name.

#### Rule 4 — Duplicate Components
- Use existing components before creating new ones. Check the codebase for similar components before flagging.

### MEDIUM PRIORITY

#### Rule 5 — Image Paths
- Paths must start with `/`.
- Example: `/images/logo.png` not `images/logo.png`

#### Rule 6 — Component Documentation
- New components must be documented per project standards.

#### Rule 7 — Indentation
- Consistent indentation in arrays, objects, and JSX props. No mixed tabs/spaces.

#### Rule 8 — Appropriate Elements
- Avoid `onClick` on non-interactive elements like `<div>`.
- Use `<Link>` for internal navigation, `<a>` for external — not `<button onClick={() => router.push(...)}>`

```jsx
// Bad
<button onClick={() => router.push('/page')}>Go</button>

// Good
<Link href="/page">Go</Link>
```

#### Rule 9 — Repetitive JSX
- 3+ identical JSX blocks that differ only in text/one prop → extract to `const` array + `.map()`.
- Keep the data array above the `return`, not inline.

### LOW PRIORITY

#### Rule 10 — Dead Code
- Remove commented-out code, unused imports, test stubs.

#### Rule 11 — SVG Tags
- Properly close tags in SVG/sprite files.

#### Rule 12 — URL Parameters
- Be specific with query params: `pay-card?card=x4953` not just `pay-card`.

#### Rule 13 — Inconsistent Indentation
- Mixed tabs/spaces or wrong indentation levels.

### CODE QUALITY RULES (apply throughout)

#### Rule 14 — No Leading/Trailing Whitespace in Attributes
```jsx
// Bad
<div className=" flex items-center " />

// Good
<div className="flex items-center" />
```

#### Rule 15 — No Blank Lines Between JSX Siblings
```jsx
// Bad
<div>Content 1</div>

<div>Content 2</div>

// Good
<div>Content 1</div>
<div>Content 2</div>
```

#### Rule 16 — No Unnecessary Variables
```jsx
// Bad
const title = 'Page Title';
return <h1>{title}</h1>;

// Good
return <h1>Page Title</h1>;
```

#### Rule 17 — No Trivial Named Functions
```jsx
// Bad
const handleClick = () => setOpen(true);
<button onClick={handleClick}>Open</button>

// Good
<button onClick={() => setOpen(true)}>Open</button>
```

#### Rule 18 — No Unnecessary Comments
Remove obvious or redundant comments. Code should be self-documenting.

#### Rule 19 — DRY on Inheritable Classes
Move repeated inheritable classes to parent containers.

```jsx
// Bad
<div>
  <p className="text-base font-medium">Item 1</p>
  <p className="text-base font-medium">Item 2</p>
</div>

// Good
<div className="text-base font-medium">
  <p>Item 1</p>
  <p>Item 2</p>
</div>
```

#### Rule 20 — No Duplicated Derived State
```jsx
// Bad
const [items, setItems] = useState([]);
const [itemCount, setItemCount] = useState(0);

// Good
const [items, setItems] = useState([]);
const itemCount = items.length;
```

#### Rule 21 — Condense Simple Conditionals
```jsx
// Bad
if (condition) {
  return <ComponentA />;
} else {
  return <ComponentB />;
}

// Good
return condition ? <ComponentA /> : <ComponentB />;
```

#### Rule 22 — Use Destructuring When Beneficial
```jsx
// Bad
<Link href={`/${props.persona}/${props.platform}/page`}>

// Good
const { persona, platform } = props;
<Link href={`/${persona}/${platform}/page`}>
```

#### Rule 23 — Custom Classes Override Defaults
```jsx
// Bad
<div className="px-4 py-2 bg-white rounded">

// Good
<div className={customClassesModal || 'px-4 py-2 bg-white rounded'}>
```

---

## Step 4: Acceptance Criteria Coverage (if Jira ticket provided)

For each acceptance criterion from the Jira ticket, determine whether the PR diff satisfies it:

| Acceptance Criterion | Status | Evidence (file:line) |
|----------------------|--------|----------------------|
| ...                  | Implemented / Partial / Missing / N/A | ... |

Flag any AC that is **not implemented** or only **partially implemented** — note it in the summary review comment.

---

## Step 5: Leave Inline Comments

For each violation found (skipping any already reported by other reviewers):

**Single-line comment (preferred for focused issues):**
```bash
gh api repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER/comments \
  -f body="COMMENT_TEXT" \
  -f commit_id="$COMMIT_SHA" \
  -f path="FILE_PATH" \
  -F line=EXACT_LINE_NUMBER \
  -f side="RIGHT"
```

**Multi-line comment (when the problem spans several lines):**
```bash
gh api repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER/comments \
  -f body="COMMENT_TEXT" \
  -f commit_id="$COMMIT_SHA" \
  -f path="FILE_PATH" \
  -F start_line=START_LINE_NUMBER \
  -F line=END_LINE_NUMBER \
  -f side="RIGHT"
```

**Notes:**
- `line` = exact file line number in the new version of the file (right side of diff)
- `side` = `"RIGHT"` for additions/modifications, `"LEFT"` for deletions
- Use ` ```suggestion ` blocks for single-line fixes (enables one-click apply in GitHub UI)
- For complex multi-line changes, use traditional before/after ` ```jsx ` format

**Comment format — code suggestion:**
```
[Concise title of the problem]

```suggestion
[Corrected code replacing the problematic line(s)]
```
```

**Comment format — before/after example:**
```
[Concise title of the problem]

```jsx
// Before
<div className="px-4"><button>Click</button></div>

// After
<button className="px-4">Click</button>
```
```

### Comment phrasing by language

**COMMENT_LANGUAGE=en:**
- "PR title must include the ticket number, e.g. `[TICKET-ID] Add payment flow`. 'initial commit' is not valid."
- "Commit messages should reference the ticket: `[TICKET-ID] Description`"
- "One less div, same result"
- "Leftover console.log"
- "This file already exists as `filename.ext`"
- "There's a component for this (recently added) `ComponentName`"
- "Remember to add documentation for this component"
- "Repetitive markup — extract into a const array and use `.map()`"
- "Use `<Link>` for internal navigation instead of `onClick` + `router.push`"

**COMMENT_LANGUAGE=es:**
- "El titulo del PR debe incluir el numero del ticket, ej. `[TICKET-ID] Agregar flujo de pago`. 'initial commit' no es valido."
- "Los commits deben referenciar el ticket: `[TICKET-ID] Descripcion del cambio`"
- "Un div menos y el mismo resultado"
- "Se fue un console.log"
- "Este archivo ya existe como `filename.ext`"
- "Para esto hay un componente (es reciente) `ComponentName`"
- "Recuerda crear documentacion para este componente"
- "Markup repetitivo — extraer a un array const y usar `.map()`"
- "Usa `<Link>` para navegacion interna en vez de `onClick` + `router.push`"

---

## Step 6: Summary Review Comment

After all inline comments, post a summary review.

If there are violations:

**COMMENT_LANGUAGE=en:**
```bash
gh pr review $PR_NUMBER --request-changes --body "Review completed: [X] comments left in the code

**Summary:**
- [Brief list of issue categories found]

**Acceptance criteria coverage:**
- [AC status summary if Jira ticket was provided]

**Positive observations:**
- [Things done well]

_Lead review bot_"
```

**COMMENT_LANGUAGE=es:**
```bash
gh pr review $PR_NUMBER --request-changes --body "Revision completada: [X] comentarios dejados en el codigo

**Resumen:**
- [Breve lista de categorias de issues encontrados]

**Cobertura de criterios de aceptacion:**
- [Resumen del estado de los ACs si se proporcionó un ticket de Jira]

**Observaciones positivas:**
- [Cosas bien hechas]

_Lead review bot_"
```

If there are **no violations** and all ACs are covered:

**COMMENT_LANGUAGE=en:**
```bash
gh pr review $PR_NUMBER --approve --body "Everything looks good! Clean code following project standards.

**Acceptance criteria:** All criteria from $TICKET_ID are addressed in this PR.

_Lead review bot_"
```

**COMMENT_LANGUAGE=es:**
```bash
gh pr review $PR_NUMBER --approve --body "Todo se ve bien! Codigo limpio y siguiendo los estandares del proyecto.

**Criterios de aceptacion:** Todos los criterios de $TICKET_ID estan cubiertos en este PR.

_Lead review bot_"
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

3. Draft a comment for the Jira ticket and show it to the user for confirmation before posting. Example comment:

```
PR #$PR_NUMBER has been reviewed and approved. Ready for QA testing.

PR link: [paste URL or use `gh pr view $PR_NUMBER --json url --jq '.url'`]
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

3. For each test case, cross-reference against the PR diff and AC coverage from Step 4:

| Code | Title | Coverage Status | Notes |
|------|-------|-----------------|-------|
| ...  | ...   | Fully covered / UI exists, no test / Partial / Not implemented / Backend only | ... |

4. Highlight test cases that reveal missing frontend features not already flagged in Step 4.

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
