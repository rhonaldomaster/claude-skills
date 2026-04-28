---
name: backend-rails-pr-cycle
description: |
  Full PR cycle review for Ruby on Rails backend PRs. Reviews code quality against team lead standards AND cross-references the linked Jira ticket's acceptance criteria. Leaves inline GitHub comments and optionally moves the Jira ticket to QA when the PR is approved.

  Invoke with a PR number (required), optional Jira ticket ID, and optional Tambora suite name.
  Examples:
  - `backend-rails-pr-cycle 42`
  - `backend-rails-pr-cycle 42 MPP-221`
  - `backend-rails-pr-cycle 42 MPP-221 "MPP-150 Memories list view"`
user-invocable: true
argument-hint: '<PR_NUMBER> [JIRA_TICKET_ID?] [tambora-suite-name?]'
allowed-tools: Bash, Read, Glob, Grep, Agent
---

# Backend Rails PR Cycle Review

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

Study the full diff. Identify what types of files are changed and which rule sets apply:

- `.rb` files → apply Rails backend rules (Steps 3)
- `.html.erb` files → apply **both** ERB/view rules (Step 3) and frontend rules for ERB (Step 3, ERB section)
- `db/migrate/*.rb` → pay extra attention to migration rules (indexes, constraints)
- `spec/` or `test/` → apply testing rules
- `app/jobs/` → apply background job rules
- `app/mailers/` → apply mailer rules

For each changed file, also determine which acceptance criteria (if any) the change maps to.

**Reading diff line numbers:**

```diff
@@ -10,5 +10,8 @@ class PostsController < ApplicationController
  def index
-   @posts = Post.all
+   @posts = Post.all                     <- This is line 12
+   @posts.each do |post|                 <- This is line 13
+     puts post.author.name              <- This is line 14 (N+1 here)
+   end
  end
```

Count line numbers from the right side (`+`) of the `@@` hunk header. Always comment on the **exact line where the problem begins**.

---

## Step 3: Code Quality Review

Apply all rules below to every changed file based on the file type detected in Step 2.

### PR Metadata (check first)

#### Rule 0 — PR Title & Commit Messages
- PR title **must** include the Jira ticket number and a meaningful description.
- Commit messages **must** also reference the ticket.
- Reject vague titles: "initial commit", "update", "fix", "WIP", "changes".
- Expected format: `[TICKET-ID] Brief description of what changed`

---

### HIGH PRIORITY (Always comment)

#### Rule 1 — N+1 Queries
- Flag association access inside loops without `.includes`, `.preload`, or `.eager_load`.
- Check serializers and views too — N+1 can happen in ERB or JSON builders.

```ruby
# Bad
Post.all.each { |post| post.author.name }

# Good
Post.includes(:author).each { |post| post.author.name }
```

- **en:** "N+1 query — add `.includes(:association)` when fetching `Model`"
- **es:** "N+1 query — agregá `.includes(:association)` al traer `Model`"

#### Rule 2 — SQL Injection via String Interpolation
- Flag `where("name = '#{params[:name]}'")`  or `.sum("#{params[:col]}")`.
- Flag any raw SQL with user input interpolated directly.

```ruby
# Bad
User.where("email = '#{params[:email]}'")

# Good
User.where(email: params[:email])
```

- **en:** "SQL injection risk — use parameterized query: `.where(name: params[:name])`"
- **es:** "Riesgo de SQL injection — usá query parametrizada: `.where(name: params[:name])`"

#### Rule 3 — Missing Strong Parameters / Mass Assignment
- Flag `params.permit!` (allows all attributes).
- Flag `update(params)` or `create(params)` without whitelisting.
- Flag permitting sensitive attributes like `role`, `admin`, `deleted_at`.

- **en:** "Missing strong params — whitelist only the attributes this action needs"
- **es:** "Faltan strong params — permitir solo los atributos que esta acción necesita"

#### Rule 4 — Missing Database Index
- Flag new foreign key columns in migrations without a corresponding `add_index`.
- Flag uniqueness validations (`validates :email, uniqueness: true`) without a unique index in the migration.

- **en:** "Missing index on `column_name` — add `add_index :table, :column_name` to this migration"
- **es:** "Falta índice en `column_name` — agregar `add_index :table, :column_name` en esta migración"

#### Rule 5 — Forgotten Debug Statements
- Flag `binding.pry`, `byebug`, `debugger`, `puts`, `p `, `pp ` left in production code.

- **en:** "Leftover debug statement"
- **es:** "Se quedó un debug"

#### Rule 6 — Missing `null: false` Constraint
- Flag `validates :field, presence: true` in the model when the corresponding migration column lacks `null: false`.
- Validations can be bypassed via `update_column` or direct DB writes — the constraint must also exist at DB level.

- **en:** "Add `null: false` to the migration column — validations can be bypassed at DB level"
- **es:** "Agregá `null: false` a la migración — las validaciones se pueden bypassear a nivel DB"

---

### MEDIUM PRIORITY (Comment if obvious)

#### Rule 7 — Callback with Side Effects
- Flag `after_create`, `after_save`, etc. that send emails, make HTTP requests, or enqueue jobs.
- These should live in a service object or be explicit in the controller.

- **en:** "Move this side effect out of the callback — use a service object or explicit call in the controller"
- **es:** "Mover este side effect fuera del callback — usar un service object o llamada explícita en el controller"

#### Rule 8 — Logic in Views / ERB Files
- Flag database queries inside `.html.erb` files.
- Flag complex Ruby conditionals or loops in ERB.
- Suggest moving logic to helpers, presenters, or the controller.

- **en:** "Avoid queries/logic in views — move to a helper or presenter"
- **es:** "Evitar queries/lógica en las vistas — mover a un helper o presenter"

#### Rule 9 — Fat Controller
- Flag controllers with business logic: calculations, data transformation, multi-model operations.

- **en:** "Business logic in controller — extract to a service object"
- **es:** "Lógica de negocio en el controller — extraer a un service object"

#### Rule 10 — `deliver_now` in Mailers
- Flag `UserMailer.welcome.deliver_now` — should use `deliver_later` to avoid blocking the request.

- **en:** "Use `deliver_later` to avoid blocking the request thread"
- **es:** "Usar `deliver_later` para no bloquear el hilo de la request"

#### Rule 11 — Background Job Not Idempotent
- Flag jobs that are not safe to retry (e.g., charging a card, sending an email) without idempotency checks.
- Flag jobs passing full ActiveRecord objects as arguments (pass IDs instead).

```ruby
# Bad
MyJob.perform_later(user)

# Good
MyJob.perform_later(user.id)
```

- **en:** "Pass the record ID instead of the object — AR objects can go stale between enqueue and perform"
- **es:** "Pasar el ID en lugar del objeto — los objetos AR pueden quedar desactualizados entre enqueue y perform"

#### Rule 12 — `has_many` Missing `dependent:`
- Flag `has_many` or `has_one` associations that don't specify `dependent: :destroy` or `dependent: :nullify` when applicable.

- **en:** "Missing `dependent:` — decide if associated records should be destroyed or nullified when parent is deleted"
- **es:** "Falta `dependent:` — definir si los registros asociados se destruyen o nullifican cuando se elimina el padre"

#### Rule 13 — Repetitive ERB Markup
- When 3+ ERB blocks are identical and differ only in data, extract to a partial with locals.

- **en:** "Repetitive markup — extract to a partial: `render partial: 'item', collection: @items, as: :item`"
- **es:** "Markup repetitivo — extraer a un partial: `render partial: 'item', collection: @items, as: :item`"

#### Rule 14 — Instance Variables in Partials
- Flag partials that depend on `@instance_variables` set by a controller instead of receiving locals.

- **en:** "Pass locals to the partial instead of relying on `@instance_variable`"
- **es:** "Pasar locals al partial en lugar de depender de `@instance_variable`"

#### Rule 15 — Unnecessary Wrapper Elements in ERB
- Remove `<div>` or `<span>` wrappers that only wrap a single element with no semantic or styling purpose.
- Move classes from the wrapper to the child element.

- **en:** "One less wrapper, same result"
- **es:** "Un wrapper menos y el mismo resultado"

---

### LOW PRIORITY (Optional / Suggestions)

#### Rule 16 — Non-RESTful Custom Actions
- Flag controllers adding custom actions beyond the 7 standard REST actions without strong justification.

- **en:** "Consider extracting `action_name` to a dedicated controller to keep this one RESTful"
- **es:** "Considerar extraer `action_name` a un controller dedicado para mantener el actual RESTful"

#### Rule 17 — Enum Without Validation
- Flag integer enums without a database-level check or model validation protecting valid values.

- **en:** "Add a validation or DB constraint to guard valid enum values"
- **es:** "Agregar una validación o constraint de DB para proteger los valores válidos del enum"

#### Rule 18 — Dead Code
- Flag commented-out code, unused methods, unused `require`/`require_relative`, orphaned routes.

- **en:** "Remove unused code"
- **es:** "Eliminar código sin uso"

#### Rule 19 — Inconsistent Naming Conventions
- Flag camelCase method or variable names (Rails convention is `snake_case`).
- Flag singular/plural inconsistencies in model/table names.

- **en:** "Rails convention: use `snake_case` for method/variable names"
- **es:** "Convención de Rails: usar `snake_case` para nombres de métodos y variables"

#### Rule 20 — Missing Test Coverage for New Code
- Flag new public methods, service objects, or controllers without corresponding spec files.

- **en:** "New public method — add a spec for this"
- **es:** "Nuevo método público — agregar un spec para esto"

---

### FRONTEND RULES FOR ERB FILES

When the PR contains `.html.erb` files, also apply these rules:

#### Rule 21 — No Blank Lines Between ERB Siblings
```erb
<%# Bad %>
<div>Content 1</div>

<div>Content 2</div>

<%# Good %>
<div>Content 1</div>
<div>Content 2</div>
```

#### Rule 22 — Eliminate Unnecessary DOM Wrappers in ERB
- Same principle as Ruby: remove `<div>` or `<span>` that only wrap a single child with no semantic or styling purpose.

#### Rule 23 — Use Semantic HTML
- Prefer `<button>`, `<a>`, `<nav>`, `<section>` over generic `<div>` for interactive or landmark elements.

#### Rule 24 — Use `link_to` for Internal Navigation
- Use `link_to` instead of `onclick` handlers or hardcoded `<a href="...">` with JS.

```erb
<%# Bad %>
<div onclick="window.location='/page'">Go</div>

<%# Good %>
<%= link_to 'Go', '/page' %>
```

#### Rule 25 — DRY: Move Repeated Classes to Parent or Extract to Partial
- When multiple sibling elements share the same classes, move inheritable ones to a parent wrapper or extract the block to a partial.

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
- Use ` ```ruby ` blocks for multi-line Ruby suggestions

**Comment format — code suggestion (single-line fix):**
```bash
gh api repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER/comments \
  -f body="N+1 query — add eager loading

\`\`\`suggestion
  @posts = Post.includes(:author).all
\`\`\`" \
  -f commit_id="$COMMIT_SHA" \
  -f path="app/controllers/posts_controller.rb" \
  -F line=12 \
  -f side="RIGHT"
```

**Comment format — before/after Ruby example (multi-line):**
```bash
gh api repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER/comments \
  -f body="SQL injection risk — use parameterized query

\`\`\`ruby
# Bad
User.where(\"email = '#{params[:email]}'\")

# Good
User.where(email: params[:email])
\`\`\`" \
  -f commit_id="$COMMIT_SHA" \
  -f path="app/controllers/users_controller.rb" \
  -F line=15 \
  -f side="RIGHT"
```

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
gh pr review $PR_NUMBER --approve --body "Everything looks good! Clean Rails code following project standards.

**Acceptance criteria:** All criteria from $TICKET_ID are addressed in this PR.

_Lead review bot_"
```

**COMMENT_LANGUAGE=es:**
```bash
gh pr review $PR_NUMBER --approve --body "Todo se ve bien! Codigo Rails limpio y siguiendo los estandares del proyecto.

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

3. For each test case, cross-reference against the PR diff and AC coverage from Step 4:

| Code | Title | Coverage Status | Notes |
|------|-------|-----------------|-------|
| ...  | ...   | Fully covered / Backend supports it, no spec / Partial / Not implemented / Frontend only | ... |

4. Highlight test cases that reveal missing backend features not already flagged in Step 4.

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
