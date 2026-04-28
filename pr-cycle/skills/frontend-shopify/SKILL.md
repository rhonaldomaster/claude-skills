---
name: frontend-shopify
description: |
  Full PR cycle review for Shopify theme PRs (Liquid, JSON templates, JS, CSS). Reviews code quality against Shopify theme standards AND cross-references the linked Jira ticket's acceptance criteria. Leaves inline GitHub comments and optionally moves the Jira ticket to QA when the PR is approved.

  Invoke with a PR number (required), optional Jira ticket ID, and optional Tambora suite name.
  Examples:
  - `frontend-shopify 42`
  - `frontend-shopify 42 MPP-221`
  - `frontend-shopify 42 MPP-221 "MPP-150 Memories list view"`
user-invocable: true
argument-hint: '<PR_NUMBER> [JIRA_TICKET_ID?] [tambora-suite-name?]'
allowed-tools: Bash, Read, Glob, Grep, Agent
---

# Frontend Shopify PR Cycle Review

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

- `sections/*.liquid` → apply section rules (schema, blocks, settings)
- `snippets/*.liquid` → apply snippet/partial rules
- `templates/*.json`, `templates/*.liquid` → apply template rules
- `layout/*.liquid` → apply layout rules (global impact — review carefully)
- `assets/*.js` → apply JavaScript rules
- `assets/*.css` → apply CSS rules
- `config/settings_schema.json` → apply theme settings rules
- `locales/*.json` → apply translation rules

For each changed file, also determine which acceptance criteria (if any) the change maps to.

**Reading diff line numbers:**

```diff
@@ -10,5 +10,8 @@ {% schema %}
  {
    "name": "Hero",
-   "settings": []
+   "settings": [                          <- This is line 13
+     { "type": "text", "id": "title" }   <- This is line 14
+   ],
+   "blocks": []                           <- This is line 15
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

#### Rule 1 — Raw Output Without Escaping (`| raw`)
- Liquid auto-escapes by default. Flag any use of `| raw` on user-controlled or metafield content.
- Only acceptable for trusted, developer-controlled HTML (e.g. SVG icons hardcoded in the theme).

```liquid
{%- comment -%} Bad — user-controlled content rendered raw {%- endcomment -%}
{{ product.description | raw }}

{%- comment -%} Good {%- endcomment -%}
{{ product.description }}
```

- **en:** "Avoid `| raw` on user-controlled content — Liquid auto-escapes by default; `raw` bypasses XSS protection"
- **es:** "Evitar `| raw` en contenido controlado por el usuario — Liquid escapa automáticamente; `raw` bypasea la protección XSS"

#### Rule 2 — Hardcoded Strings (Not Using Translations)
- Flag user-facing strings hardcoded in Liquid instead of using `{{ 'key' | t }}`.

```liquid
{%- comment -%} Bad {%- endcomment -%}
<button>Add to cart</button>

{%- comment -%} Good {%- endcomment -%}
<button>{{ 'products.product.add_to_cart' | t }}</button>
```

- **en:** "Hardcoded string — use `{{ 'key' | t }}` and add the key to `locales/en.default.json`"
- **es:** "String hardcodeado — usar `{{ 'key' | t }}` y agregar la clave en `locales/en.default.json`"

#### Rule 3 — Images Without `image_url` Filter and `srcset`
- Flag `<img>` tags using raw CDN URLs or `| img_url` (deprecated) instead of `| image_url` with size params and `srcset`.

```liquid
{%- comment -%} Bad {%- endcomment -%}
<img src="{{ product.featured_image | img_url: '800x' }}">

{%- comment -%} Good {%- endcomment -%}
<img
  src="{{ product.featured_image | image_url: width: 800 }}"
  srcset="{{ product.featured_image | image_url: width: 400 }} 400w,
          {{ product.featured_image | image_url: width: 800 }} 800w"
  width="{{ product.featured_image.width }}"
  height="{{ product.featured_image.height }}"
  alt="{{ product.featured_image.alt | escape }}"
  loading="lazy">
```

- **en:** "Use `| image_url` (not the deprecated `| img_url`) with `srcset` for responsive images"
- **es:** "Usar `| image_url` (no el deprecado `| img_url`) con `srcset` para imágenes responsivas"

#### Rule 4 — Missing `loading="lazy"` on Below-the-Fold Images
- Flag `<img>` tags below the fold without `loading="lazy"`.
- Hero/above-the-fold images should use `loading="eager"` or omit the attribute.

- **en:** "Add `loading=\"lazy\"` to images below the fold to improve page performance"
- **es:** "Agregar `loading=\"lazy\"` a imágenes below the fold para mejorar el rendimiento"

#### Rule 5 — Invalid or Missing Section Schema
- Flag sections without a `{% schema %}` block.
- Flag schema JSON that is malformed or missing required fields (`name`, `settings`, `presets` where applicable).
- Flag settings without `id`, `type`, or `label`.

- **en:** "Missing or invalid section schema — every section needs a `{% schema %}` block with valid JSON"
- **es:** "Falta o es inválido el schema de la sección — cada sección necesita un bloque `{% schema %}` con JSON válido"

#### Rule 6 — Forgotten Debug Output
- Flag `{{ variable | json }}` or Liquid `{% comment %}debug{% endcomment %}` dumps left in production code.

- **en:** "Leftover debug output"
- **es:** "Se quedó un debug"

---

### MEDIUM PRIORITY (Comment if obvious)

#### Rule 7 — Unnecessary DOM Wrappers
- Remove `<div>` or `<span>` that only wrap a single child element with no semantic or styling purpose.
- Move classes from the wrapper to the child.

```liquid
{%- comment -%} Bad {%- endcomment -%}
<div>
  <p class="text-lg">{{ section.settings.title }}</p>
</div>

{%- comment -%} Good {%- endcomment -%}
<p class="text-lg">{{ section.settings.title }}</p>
```

- **en:** "One less wrapper, same result"
- **es:** "Un wrapper menos y el mismo resultado"

#### Rule 8 — Repetitive Liquid Markup
- When 3+ Liquid blocks are identical and differ only in data, extract to a snippet with parameters.

```liquid
{%- comment -%} Bad — repeated card block × 3 {%- endcomment -%}

{%- comment -%} Good {%- endcomment -%}
{% render 'card-product', product: product, show_badge: true %}
```

- **en:** "Repetitive markup — extract to a snippet: `{% render 'snippet-name', param: value %}`"
- **es:** "Markup repetitivo — extraer a un snippet: `{% render 'snippet-name', param: value %}`"

#### Rule 9 — Missing Accessibility Attributes
- Flag interactive elements (`<button>`, `<a>`) without `aria-label` when they have no visible text.
- Flag missing `alt` on `<img>` tags (use `alt=""` for decorative images).
- Flag missing `role` on custom interactive elements built from `<div>`.

- **en:** "Missing accessibility attribute — add `aria-label` or `alt` for screen reader support"
- **es:** "Falta atributo de accesibilidad — agregar `aria-label` o `alt` para soporte de lectores de pantalla"

#### Rule 10 — Missing Responsive Behavior
- Flag sections or components with fixed pixel widths instead of fluid/responsive units.
- Flag missing breakpoint handling in CSS for new components.

- **en:** "Check responsive behavior — verify this renders correctly on mobile (375px) and tablet (768px)"
- **es:** "Verificar comportamiento responsivo — asegurarse que se vea correctamente en mobile (375px) y tablet (768px)"

#### Rule 11 — Theme Settings Added Without Defaults
- Flag new settings in `settings_schema.json` or section schemas without a `default` value.
- Missing defaults can cause the theme to break on fresh installs or preview.

```json
// Bad
{ "type": "text", "id": "heading", "label": "Heading" }

// Good
{ "type": "text", "id": "heading", "label": "Heading", "default": "Welcome" }
```

- **en:** "Missing `default` for this setting — add one to prevent empty state on fresh installs"
- **es:** "Falta `default` para este setting — agregar uno para evitar estado vacío en instalaciones nuevas"

#### Rule 12 — JS Added Without Deferring
- Flag `<script>` tags in Liquid files without `defer` or `async` that could block rendering.
- Prefer loading scripts through the asset pipeline with deferred loading.

```liquid
{%- comment -%} Bad {%- endcomment -%}
<script src="{{ 'my-script.js' | asset_url }}"></script>

{%- comment -%} Good {%- endcomment -%}
<script src="{{ 'my-script.js' | asset_url }}" defer></script>
```

- **en:** "Add `defer` or `async` to this script tag to avoid blocking page render"
- **es:** "Agregar `defer` o `async` a este script tag para no bloquear el render de la página"

---

### LOW PRIORITY (Optional / Suggestions)

#### Rule 13 — Deprecated Liquid Filters
- Flag use of deprecated filters: `| img_url`, `| money_with_currency` used incorrectly, `| json` in output contexts.
- Check the [Shopify Liquid changelog](https://shopify.dev/docs/api/liquid) for current equivalents.

- **en:** "Deprecated filter — use `| image_url` instead of `| img_url`"
- **es:** "Filtro deprecado — usar `| image_url` en vez de `| img_url`"

#### Rule 14 — Dead Code
- Flag commented-out Liquid blocks, unused snippet `render` calls, settings defined in schema but never referenced in the template.

- **en:** "Remove unused code"
- **es:** "Eliminar código sin uso"

#### Rule 15 — Missing Presets in New Sections
- Flag new sections without a `presets` array in the schema — prevents merchants from adding them via the Theme Customizer.

```json
// Bad — no presets
{ "name": "FAQ", "settings": [...] }

// Good
{ "name": "FAQ", "settings": [...], "presets": [{ "name": "FAQ" }] }
```

- **en:** "Missing `presets` in section schema — merchants won't be able to add this section in the Theme Customizer"
- **es:** "Falta `presets` en el schema de la sección — los merchants no podrán agregar esta sección desde el Theme Customizer"

#### Rule 16 — Inconsistent Naming Conventions
- Flag section/snippet file names that don't follow the project's naming convention (typically `kebab-case`).
- Flag schema setting `id` values that don't use `snake_case`.

- **en:** "Naming inconsistency — use `kebab-case` for file names and `snake_case` for setting IDs"
- **es:** "Inconsistencia de nombres — usar `kebab-case` para nombres de archivos y `snake_case` para IDs de settings"

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
- Use ` ```liquid ` blocks for multi-line Liquid suggestions

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
gh pr review $PR_NUMBER --approve --body "Everything looks good! Clean Shopify theme code following project standards.

**Acceptance criteria:** All criteria from $TICKET_ID are addressed in this PR.

_Lead review bot_"
```

**COMMENT_LANGUAGE=es:**
```bash
gh pr review $PR_NUMBER --approve --body "Todo se ve bien! Codigo de tema Shopify limpio y siguiendo los estandares del proyecto.

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
| ...  | ...   | Fully covered / UI exists, no test / Partial / Not implemented / Backend only | ... |

4. Highlight test cases that reveal missing frontend features not already flagged in Step 4.

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
