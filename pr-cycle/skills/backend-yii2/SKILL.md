---
name: backend-yii2
description: |
  Full PR cycle review for PHP Yii2 backend PRs. Reviews code quality against team lead standards AND cross-references the linked Jira ticket's acceptance criteria. Leaves inline GitHub comments and optionally moves the Jira ticket to QA when the PR is approved.

  Invoke with a PR number (required), optional Jira ticket ID, and optional Tambora suite name.
  Examples:
  - `backend-yii2 42`
  - `backend-yii2 42 MPP-221`
  - `backend-yii2 42 MPP-221 "MPP-150 Memories list view"`
user-invocable: true
argument-hint: '<PR_NUMBER> [JIRA_TICKET_ID?] [tambora-suite-name?]'
allowed-tools: Bash, Read, Glob, Grep, Agent
---

# Backend Yii2 PR Cycle Review

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

- `controllers/` → apply controller rules
- `models/` → apply model/ActiveRecord rules
- `views/` → apply view/template rules
- `migrations/` → pay extra attention to migration rules (indexes, constraints)
- `components/`, `widgets/` → apply reusable component rules
- `commands/` → apply console command rules
- `tests/` → apply testing rules
- `assets/` → apply asset rules

For each changed file, also determine which acceptance criteria (if any) the change maps to.

**Reading diff line numbers:**

```diff
@@ -10,5 +10,8 @@ class UserController extends Controller
  public function actionIndex()
  {
-    $users = User::find()->all();
+    $users = User::find()->all();              <- This is line 13
+    foreach ($users as $user) {               <- This is line 14
+      echo $user->profile->name;             <- This is line 15 (N+1 here)
+    }
  }
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

#### Rule 1 — SQL Injection via String Interpolation
- Flag raw SQL with user input concatenated or interpolated directly.
- Always use parameterized queries or ActiveRecord.

```php
// Bad
$users = Yii::$app->db->createCommand("SELECT * FROM user WHERE name = '$name'")->queryAll();

// Good
$users = Yii::$app->db->createCommand('SELECT * FROM user WHERE name = :name', [':name' => $name])->queryAll();

// Better — use ActiveRecord
$users = User::find()->where(['name' => $name])->all();
```

- **en:** "SQL injection risk — use parameterized query or ActiveRecord instead of string interpolation"
- **es:** "Riesgo de SQL injection — usar query parametrizada o ActiveRecord en vez de interpolación de string"

#### Rule 2 — XSS via Unescaped Output
- Flag output that renders user-controlled data without escaping in views.
- Use `Html::encode()` for plain text, `HtmlPurifier::process()` for rich text.

```php
// Bad
<?= $model->comment ?>

// Good
<?= Html::encode($model->comment) ?>
```

- **en:** "XSS risk — escape user-controlled output with `Html::encode()`"
- **es:** "Riesgo de XSS — escapar salida controlada por el usuario con `Html::encode()`"

#### Rule 3 — Missing Input Validation (No `rules()`)
- Flag `$_POST`, `$_GET`, or `Yii::$app->request->post()` used directly without going through a model's `rules()`.
- Flag mass assignment: `$model->attributes = $data` without `$model->load()` + `$model->validate()`.

```php
// Bad
$model->name = Yii::$app->request->post('name');
$model->save();

// Good
if ($model->load(Yii::$app->request->post()) && $model->validate()) {
    $model->save();
}
```

- **en:** "Missing validation — use `$model->load()` + `$model->validate()` before saving"
- **es:** "Falta validación — usar `$model->load()` + `$model->validate()` antes de guardar"

#### Rule 4 — Missing CSRF Protection
- Flag AJAX requests or form submissions that don't include the CSRF token.
- Flag actions decorated with `$this->enableCsrfValidation = false` without justification.

- **en:** "CSRF token missing — ensure forms include `<?= Html::hiddenInput(Yii::$app->request->csrfParam, Yii::$app->request->csrfToken) ?>` or use `ActiveForm`"
- **es:** "Falta el CSRF token — verificar que el formulario incluya el token o usar `ActiveForm`"

#### Rule 5 — N+1 Queries
- Flag relation access inside loops without eager loading via `with()` or `joinWith()`.

```php
// Bad
$orders = Order::find()->all();
foreach ($orders as $order) {
    echo $order->customer->name; // N+1
}

// Good
$orders = Order::find()->with('customer')->all();
foreach ($orders as $order) {
    echo $order->customer->name;
}
```

- **en:** "N+1 query — add eager loading: `->with('relation')`"
- **es:** "N+1 query — agregar eager loading: `->with('relation')`"

#### Rule 6 — Missing Database Index
- Flag new foreign key columns in migrations without a corresponding `createIndex()`.
- Flag unique validations in `rules()` without a unique index in the migration.

```php
// Bad migration — missing index
$this->addColumn('{{%order}}', 'user_id', $this->integer()->notNull());

// Good
$this->addColumn('{{%order}}', 'user_id', $this->integer()->notNull());
$this->createIndex('idx_order_user_id', '{{%order}}', 'user_id');
```

- **en:** "Missing index on `column_name` — add `createIndex()` to this migration"
- **es:** "Falta índice en `column_name` — agregar `createIndex()` en esta migración"

#### Rule 7 — Forgotten Debug Statements
- Flag `var_dump()`, `print_r()`, `echo` used for debugging, `Yii::debug()` calls left in production paths.

- **en:** "Leftover debug statement"
- **es:** "Se quedó un debug"

---

### MEDIUM PRIORITY (Comment if obvious)

#### Rule 8 — Logic in Views
- Flag database queries or complex business logic inside view files.
- Views should only render data prepared by the controller or passed as `$model`.

```php
// Bad — in a view file
$users = User::find()->where(['active' => 1])->all();

// Good — query in controller, pass to view
// Controller: $this->render('index', ['users' => $users]);
// View: foreach ($users as $user) { ... }
```

- **en:** "Avoid queries/logic in views — move to controller or model"
- **es:** "Evitar queries/lógica en las vistas — mover al controller o modelo"

#### Rule 9 — Fat Controller
- Flag controllers that contain business logic: calculations, complex data transformations, multi-model operations.
- Suggest extracting to a service class or model method.

- **en:** "Business logic in controller — extract to a service class or model method"
- **es:** "Lógica de negocio en el controller — extraer a una clase de servicio o método del modelo"

#### Rule 10 — `notNull()` Missing in Migration
- Flag `validates(['field'], 'required')` in the model when the migration column lacks `->notNull()`.
- Validations can be bypassed via direct DB writes.

```php
// Bad
$this->addColumn('{{%user}}', 'email', $this->string());

// Good
$this->addColumn('{{%user}}', 'email', $this->string()->notNull());
```

- **en:** "Add `->notNull()` to the migration column — required validations can be bypassed at DB level"
- **es:** "Agregar `->notNull()` a la migración — las validaciones requeridas se pueden bypassear a nivel DB"

#### Rule 11 — Missing Access Control
- Flag controller actions that don't check permissions via `behaviors()` with `AccessControl` or `VerbFilter`.
- Flag missing `Yii::$app->user->can()` checks for RBAC-protected operations.

- **en:** "Missing access control — add `AccessControl` behavior or `Yii::$app->user->can()` check"
- **es:** "Falta control de acceso — agregar behavior `AccessControl` o verificación `Yii::$app->user->can()`"

#### Rule 12 — Queue Job Passing Full ActiveRecord Object
- Flag jobs that serialize a full ActiveRecord object instead of passing its ID.
- AR objects can go stale between enqueue and execution.

```php
// Bad
Yii::$app->queue->push(new SendEmailJob(['user' => $user]));

// Good
Yii::$app->queue->push(new SendEmailJob(['userId' => $user->id]));
```

- **en:** "Pass the record ID instead of the object — AR objects can go stale between enqueue and execution"
- **es:** "Pasar el ID en lugar del objeto — los objetos AR pueden quedar desactualizados entre enqueue y ejecución"

#### Rule 13 — Repetitive View Markup
- When 3+ view blocks are identical and differ only in data, extract to a partial using `$this->render()` with params or a widget.

- **en:** "Repetitive markup — extract to a partial: `$this->render('_item', ['model' => $item])`"
- **es:** "Markup repetitivo — extraer a un partial: `$this->render('_item', ['model' => $item])`"

#### Rule 14 — Missing `defaultScope` / Soft Delete Guard
- Flag queries on models that implement soft delete (e.g. `deleted_at`) without a scope filtering deleted records.

- **en:** "Soft delete model — ensure queries filter out deleted records with a default scope or explicit condition"
- **es:** "Modelo con soft delete — asegurarse de filtrar registros eliminados con un scope por defecto o condición explícita"

---

### LOW PRIORITY (Optional / Suggestions)

#### Rule 15 — Non-RESTful Custom Actions
- Flag controllers adding actions beyond standard REST actions without justification.
- Suggest dedicated controllers for custom resource operations.

- **en:** "Consider extracting `actionName` to a dedicated controller to keep this one RESTful"
- **es:** "Considerar extraer `actionName` a un controller dedicado para mantener el actual RESTful"

#### Rule 16 — Dead Code
- Flag commented-out code, unused methods, unused `use` imports, orphaned routes in `config/web.php`.

- **en:** "Remove unused code"
- **es:** "Eliminar código sin uso"

#### Rule 17 — Inconsistent Naming Conventions
- Flag camelCase properties that should be `snake_case` at DB level.
- Flag non-PSR-compliant class or method names.
- Yii2 convention: `camelCase` for methods/properties, `snake_case` for DB columns.

- **en:** "Naming inconsistency — Yii2 convention: `camelCase` for methods, `snake_case` for DB columns"
- **es:** "Inconsistencia de nombres — convención Yii2: `camelCase` para métodos, `snake_case` para columnas DB"

#### Rule 18 — Missing Test Coverage for New Code
- Flag new public methods, services, or controllers without corresponding test files in `tests/`.

- **en:** "New public method — add a test for this in `tests/`"
- **es:** "Nuevo método público — agregar un test en `tests/`"

#### Rule 19 — Unnecessary View Wrappers
- Remove `<div>` or `<span>` wrappers in view files that only wrap a single child with no semantic or styling purpose.

- **en:** "One less wrapper, same result"
- **es:** "Un wrapper menos y el mismo resultado"

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
- Use ` ```php ` blocks for multi-line PHP suggestions

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
gh pr review $PR_NUMBER --approve --body "Everything looks good! Clean Yii2 code following project standards.

**Acceptance criteria:** All criteria from $TICKET_ID are addressed in this PR.

_Lead review bot_"
```

**COMMENT_LANGUAGE=es:**
```bash
gh pr review $PR_NUMBER --approve --body "Todo se ve bien! Codigo Yii2 limpio y siguiendo los estandares del proyecto.

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

3. Draft a comment for the Jira ticket and show it to the user for confirmation before posting:

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
| ...  | ...   | Fully covered / Backend supports it, no test / Partial / Not implemented / Frontend only | ... |

4. Highlight test cases that reveal missing backend features not already flagged in Step 4.

5. Ask the user if they want to record test run results:

> "Would you like to record test run results for this suite in Tambora?"

If yes:
- Ask if they have an existing test run code or need a new one.
- If new → call `mcp__tambora__create_test_run_from_suite` and confirm the run code.
- Walk through each test case one at a time asking for status: `passed / failed / skipped / broken`.
- For `failed` or `broken`, also ask for an optional error message.
- Collect all results, show a summary, then ask for confirmation before submitting.
- Call `mcp__tambora__add_test_run_results` with all collected results in one batch.
- Ask if the run should be marked complete → call `mcp__tambora__complete_test_run` if yes.
- Confirm final state to the user (run code, accepted/rejected count, completion status).
