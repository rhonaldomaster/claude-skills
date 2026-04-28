---
name: backend-wordpress
description: |
  Full PR cycle review for WordPress theme/plugin PRs. Reviews code quality against WordPress coding standards and security best practices AND cross-references the linked Jira ticket's acceptance criteria. Leaves inline GitHub comments and optionally moves the Jira ticket to QA when the PR is approved.

  Invoke with a PR number (required), optional Jira ticket ID, and optional Tambora suite name.
  Examples:
  - `backend-wordpress 42`
  - `backend-wordpress 42 MPP-221`
  - `backend-wordpress 42 MPP-221 "MPP-150 Memories list view"`
user-invocable: true
argument-hint: '<PR_NUMBER> [JIRA_TICKET_ID?] [tambora-suite-name?]'
allowed-tools: Bash, Read, Glob, Grep, Agent
---

# Backend WordPress PR Cycle Review

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

- `functions.php`, `inc/`, `includes/` → apply hooks, enqueue, and general PHP rules
- `template-parts/`, `templates/`, `*.php` theme templates → apply template and output escaping rules
- `*.php` plugin files → apply plugin-specific rules (activation hooks, options API, REST endpoints)
- `assets/js/` → apply JavaScript/AJAX rules
- `acf-json/` → apply ACF field group rules

For each changed file, also determine which acceptance criteria (if any) the change maps to.

**Reading diff line numbers:**

```diff
@@ -15,5 +15,8 @@ function my_theme_setup() {
  function my_custom_query() {
-   $posts = get_posts(['post_type' => 'event']);
+   global $wpdb;                                         <- This is line 18
+   $type = $_GET['type'];                                <- This is line 19
+   $posts = $wpdb->get_results("SELECT * FROM wp_posts WHERE post_type = '$type'"); <- line 20 (injection)
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

#### Rule 1 — SQL Injection via `$wpdb`
- Flag `$wpdb->query()`, `$wpdb->get_results()`, etc. with user input concatenated or interpolated directly.
- Always use `$wpdb->prepare()`.

```php
// Bad
$results = $wpdb->get_results("SELECT * FROM {$wpdb->posts} WHERE post_status = '$status'");

// Good
$results = $wpdb->get_results($wpdb->prepare(
    "SELECT * FROM {$wpdb->posts} WHERE post_status = %s",
    $status
));
```

- **en:** "SQL injection risk — use `$wpdb->prepare()` for all queries with dynamic values"
- **es:** "Riesgo de SQL injection — usar `$wpdb->prepare()` para todas las queries con valores dinámicos"

#### Rule 2 — XSS via Unescaped Output
- Flag `echo`, `print`, or template output that renders user-controlled data without escaping.
- Use the appropriate escaping function for context.

```php
// Bad
echo get_post_meta($post->ID, 'user_bio', true);

// Good — plain text context
echo esc_html(get_post_meta($post->ID, 'user_bio', true));

// Good — attribute context
echo esc_attr($value);

// Good — URL context
echo esc_url($url);

// Good — rich text (trusted HTML)
echo wp_kses_post($content);
```

- **en:** "XSS risk — escape output with `esc_html()`, `esc_attr()`, `esc_url()`, or `wp_kses_post()` depending on context"
- **es:** "Riesgo de XSS — escapar salida con `esc_html()`, `esc_attr()`, `esc_url()`, o `wp_kses_post()` según el contexto"

#### Rule 3 — Missing Input Sanitization
- Flag `$_POST`, `$_GET`, `$_REQUEST` used directly without sanitization.
- Use WordPress sanitization functions before processing or storing.

```php
// Bad
$name = $_POST['name'];
update_post_meta($post_id, 'name', $name);

// Good
$name = sanitize_text_field(wp_unslash($_POST['name']));
update_post_meta($post_id, 'name', $name);
```

- **en:** "Missing sanitization — use `sanitize_text_field()`, `absint()`, `sanitize_email()`, etc. before processing user input"
- **es:** "Falta sanitización — usar `sanitize_text_field()`, `absint()`, `sanitize_email()`, etc. antes de procesar input del usuario"

#### Rule 4 — Missing Nonce Verification
- Flag form submissions and AJAX handlers that don't verify a nonce.
- Flag missing `check_ajax_referer()` or `wp_verify_nonce()` in AJAX callbacks.

```php
// Bad
add_action('wp_ajax_my_action', function() {
    $data = $_POST['data'];
    // process...
});

// Good
add_action('wp_ajax_my_action', function() {
    check_ajax_referer('my_action_nonce', 'nonce');
    $data = sanitize_text_field(wp_unslash($_POST['data']));
    // process...
});
```

- **en:** "Missing nonce verification — add `check_ajax_referer()` or `wp_verify_nonce()` before processing the request"
- **es:** "Falta verificación de nonce — agregar `check_ajax_referer()` o `wp_verify_nonce()` antes de procesar la request"

#### Rule 5 — Hardcoded `<script>` or `<link>` Tags
- Flag scripts or styles added directly in PHP files instead of through the enqueue system.

```php
// Bad
echo '<script src="/assets/js/my-script.js"></script>';

// Good
add_action('wp_enqueue_scripts', function() {
    wp_enqueue_script('my-script', get_template_directory_uri() . '/assets/js/my-script.js', [], '1.0.0', true);
});
```

- **en:** "Never hardcode `<script>` or `<link>` tags — use `wp_enqueue_script()` / `wp_enqueue_style()`"
- **es:** "No hardcodear tags `<script>` o `<link>` — usar `wp_enqueue_script()` / `wp_enqueue_style()`"

#### Rule 6 — Missing Capability Check
- Flag AJAX handlers, REST endpoints, and admin actions that don't verify the user's capability before performing privileged operations.

```php
// Bad
add_action('wp_ajax_delete_item', function() {
    wp_delete_post(intval($_POST['id']));
});

// Good
add_action('wp_ajax_delete_item', function() {
    if (!current_user_can('delete_posts')) {
        wp_send_json_error('Unauthorized', 403);
    }
    check_ajax_referer('delete_item_nonce', 'nonce');
    wp_delete_post(absint($_POST['id']));
});
```

- **en:** "Missing capability check — verify with `current_user_can()` before performing privileged operations"
- **es:** "Falta verificación de capacidad — verificar con `current_user_can()` antes de realizar operaciones privilegiadas"

#### Rule 7 — Forgotten Debug Statements
- Flag `var_dump()`, `print_r()`, `error_log()` calls, `WP_DEBUG` dumps left in production code.

- **en:** "Leftover debug statement"
- **es:** "Se quedó un debug"

---

### MEDIUM PRIORITY (Comment if obvious)

#### Rule 8 — Direct Database Queries Instead of WP APIs
- Flag `$wpdb` queries that could be replaced with `WP_Query`, `get_posts()`, `get_post_meta()`, etc.
- Prefer WordPress APIs over raw SQL for portability and caching compatibility.

- **en:** "Prefer WordPress APIs (`WP_Query`, `get_post_meta()`) over direct `$wpdb` queries when possible"
- **es:** "Preferir las APIs de WordPress (`WP_Query`, `get_post_meta()`) sobre queries directas de `$wpdb` cuando sea posible"

#### Rule 9 — Not Translation Ready
- Flag user-facing strings that are not wrapped in translation functions.

```php
// Bad
echo 'Submit your review';

// Good
echo esc_html__('Submit your review', 'my-theme');
```

- **en:** "Not translation ready — wrap user-facing strings with `__()`, `_e()`, or `esc_html__()`"
- **es:** "No está listo para traducción — envolver strings de usuario con `__()`, `_e()`, o `esc_html__()`"

#### Rule 10 — Logic in Templates
- Flag complex PHP logic, queries, or business rules inside template files (`template-parts/`, `*.php` templates).
- Templates should receive pre-prepared data via the template loader or global variables set in `functions.php`.

- **en:** "Avoid queries/logic in templates — move to `functions.php`, a custom class, or a template controller"
- **es:** "Evitar queries/lógica en templates — mover a `functions.php`, una clase personalizada, o un template controller"

#### Rule 11 — Missing `wp_unslash()` Before Sanitizing
- Flag code that sanitizes `$_POST`/`$_GET` without first calling `wp_unslash()`.
- WordPress adds slashes to incoming data; skipping `wp_unslash()` leads to corrupted stored values.

```php
// Bad
$value = sanitize_text_field($_POST['value']);

// Good
$value = sanitize_text_field(wp_unslash($_POST['value']));
```

- **en:** "Missing `wp_unslash()` — call it before sanitizing `$_POST`/`$_GET` to avoid double-slashing"
- **es:** "Falta `wp_unslash()` — llamarlo antes de sanitizar `$_POST`/`$_GET` para evitar doble escape"

#### Rule 12 — Repetitive Template Markup
- When 3+ template blocks are identical and differ only in data, extract to a `get_template_part()` call.

```php
// Bad — repeated block for each card
// <div class="card">...</div> × 3

// Good
get_template_part('template-parts/card', null, ['post' => $post]);
```

- **en:** "Repetitive markup — extract to a template part: `get_template_part('template-parts/card', null, ['post' => $post])`"
- **es:** "Markup repetitivo — extraer a un template part: `get_template_part('template-parts/card', null, ['post' => $post])`"

#### Rule 13 — REST API Endpoint Missing Permission Callback
- Flag `register_rest_route()` calls where `permission_callback` is set to `__return_true` or is missing for endpoints that should be protected.

```php
// Bad
register_rest_route('my-plugin/v1', '/data', [
    'methods' => 'GET',
    'callback' => 'my_get_data',
    'permission_callback' => '__return_true',
]);

// Good
register_rest_route('my-plugin/v1', '/data', [
    'methods' => 'GET',
    'callback' => 'my_get_data',
    'permission_callback' => function() {
        return current_user_can('read_private_posts');
    },
]);
```

- **en:** "REST endpoint has no real permission check — replace `__return_true` with an actual capability check"
- **es:** "El endpoint REST no tiene verificación de permisos real — reemplazar `__return_true` con una verificación de capacidad"

---

### LOW PRIORITY (Optional / Suggestions)

#### Rule 14 — Unnecessary Template Wrappers
- Remove `<div>` or `<span>` wrappers in template files that only wrap a single child with no semantic or styling purpose.

- **en:** "One less wrapper, same result"
- **es:** "Un wrapper menos y el mismo resultado"

#### Rule 15 — Dead Code
- Flag commented-out code, unused hooks, functions registered but never called, orphaned template files.

- **en:** "Remove unused code"
- **es:** "Eliminar código sin uso"

#### Rule 16 — Inconsistent Naming Conventions
- WordPress convention: `snake_case` for functions and variables, prefixed to avoid collisions (e.g. `mytheme_get_featured_image()`).
- Flag unprefixed global functions or hooks that could conflict with core or plugins.

- **en:** "WordPress convention: prefix global functions/hooks to avoid conflicts (e.g. `mytheme_function_name()`)"
- **es:** "Convención de WordPress: prefijar funciones/hooks globales para evitar conflictos (ej. `mytheme_nombre_funcion()`)"

#### Rule 17 — Missing Test Coverage for New Code
- Flag new custom functions, AJAX handlers, or REST endpoints without corresponding tests.

- **en:** "New function — consider adding a test in the test suite"
- **es:** "Nueva función — considerar agregar un test en el suite de pruebas"

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
gh pr review $PR_NUMBER --approve --body "Everything looks good! Clean WordPress code following project standards.

**Acceptance criteria:** All criteria from $TICKET_ID are addressed in this PR.

_Lead review bot_"
```

**COMMENT_LANGUAGE=es:**
```bash
gh pr review $PR_NUMBER --approve --body "Todo se ve bien! Codigo WordPress limpio y siguiendo los estandares del proyecto.

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
