---
name: rails-lead-review
description: "PR code review for Ruby on Rails projects using team lead architectural opinions and Rails best practices. Use when reviewing Rails PRs."
argument-hint: "<PR_NUMBER>"
---

## Your Rails Architecture Review

You are reviewing this PR on behalf of the team lead, enforcing their architectural opinions and Rails code standards. Perform a comprehensive code review.

## Configuration

Set your preferred language for review comments:
- `COMMENT_LANGUAGE=en` (English - default)
- `COMMENT_LANGUAGE=es` (Spanish)

## Step 1: Inspect the PR

```bash
gh pr view $PR_NUMBER --json title,body,commits
```

## Step 2: Get the changed files

```bash
gh pr diff $PR_NUMBER
```

Identify what types of files are changed:
- `.rb` files → apply Rails backend rules
- `.html.erb` files → apply **both** ERB/View rules and frontend quality rules from [quality-rules.md](quality-rules.md)
- `db/migrate/*.rb` → apply migration rules (indexes, constraints)
- `spec/` or `test/` → apply testing rules
- `app/jobs/` → apply background job rules
- `app/mailers/` → apply mailer rules

## Step 3: Read quality rules

Read [quality-rules.md](quality-rules.md) — these rules supplement the review patterns below. Apply both sets when reviewing code.

## Step 4: Review and apply rules

---

### PR METADATA (Always check first)

#### 0. PR Title & Commit Messages
- **PR title MUST include the ticket number** and a meaningful description of what the PR does
- **Commit messages MUST also include the ticket number** and describe the actual change
- Reject vague or lazy titles like "initial commit", "update", "fix", "changes", "WIP", etc.
- This is an established project — there is no "initial commit". The title should reflect what was actually built or changed
- **Expected format:** `[TICKET-ID] Brief description of what changed`
- This is checked BEFORE reviewing any code. If the title and commits are wrong, comment immediately

---

### HIGH PRIORITY (Always comment)

#### 1. N+1 Queries (most common Rails issue)
- Flag association access inside loops without `.includes`, `.preload`, or `.eager_load`
- Example: loading `post.author` inside each iteration when posts were fetched without `includes(:author)`
- Check serializers and views too — N+1 can happen in ERB or JSON builders
- **Comment (en):** "N+1 query — add `.includes(:association)` when fetching `#{model}`"
- **Comment (es):** "N+1 query — agregá `.includes(:association)` al traer `#{model}`"

#### 2. SQL Injection via String Interpolation
- Flag `where("name = '#{params[:name]}'")`  or `.sum("#{params[:col]}")`
- Flag any raw SQL with user input interpolated directly
- **Comment (en):** "SQL injection risk — use parameterized query: `.where(name: params[:name])`"
- **Comment (es):** "Riesgo de SQL injection — usá query parametrizada: `.where(name: params[:name])`"

#### 3. Missing Strong Parameters / Mass Assignment
- Flag `params.permit!` (allows all attributes)
- Flag `update(params)` or `create(params)` without whitelisting
- Flag permitting sensitive attributes like `role`, `admin`, `deleted_at`
- **Comment (en):** "Missing strong params — whitelist only the attributes this action needs"
- **Comment (es):** "Faltan strong params — permitir solo los atributos que esta acción necesita"

#### 4. Missing Database Index
- Flag new foreign key columns in migrations without a corresponding `add_index`
- Flag uniqueness validations (`validates :email, uniqueness: true`) without a unique index in the migration
- **Comment (en):** "Missing index on `column_name` — add `add_index :table, :column_name` to this migration"
- **Comment (es):** "Falta índice en `column_name` — agregar `add_index :table, :column_name` en esta migración"

#### 5. Forgotten Debug Statements
- Flag `binding.pry`, `byebug`, `debugger`, `puts`, `p `, `pp ` left in production code
- **Comment (en):** "Leftover debug statement"
- **Comment (es):** "Se quedó un debug"

#### 6. Missing `null: false` Constraint
- Flag `validates :field, presence: true` in the model when the corresponding migration column lacks `null: false`
- Validations can be bypassed (`update_column`, direct DB writes) — the constraint must also be at DB level
- **Comment (en):** "Add `null: false` to the migration column — validations can be bypassed at DB level"
- **Comment (es):** "Agregá `null: false` a la migración — las validaciones se pueden bypassear a nivel DB"

---

### MEDIUM PRIORITY (Comment if obvious)

#### 7. Callback with Side Effects
- Flag `after_create`, `after_save`, etc. that send emails, make HTTP requests, or enqueue jobs
- These should live in a service object or be explicit in the controller
- **Comment (en):** "Move this side effect out of the callback — use a service object or explicit call in the controller"
- **Comment (es):** "Mover este side effect fuera del callback — usar un service object o llamada explícita en el controller"

#### 8. Logic in Views / ERB Files
- Flag database queries inside `.html.erb` files
- Flag complex Ruby conditionals or loops in ERB
- Suggest moving logic to helpers, presenters, or the controller
- **Comment (en):** "Avoid queries/logic in views — move to a helper or presenter"
- **Comment (es):** "Evitar queries/lógica en las vistas — mover a un helper o presenter"

#### 9. Fat Controller
- Flag controllers with business logic: calculations, data transformation, multi-model operations
- Suggest service objects
- **Comment (en):** "Business logic in controller — extract to a service object"
- **Comment (es):** "Lógica de negocio en el controller — extraer a un service object"

#### 10. `deliver_now` in Mailers
- Flag `UserMailer.welcome.deliver_now` — should use `deliver_later` to avoid blocking the request
- **Comment (en):** "Use `deliver_later` to avoid blocking the request thread"
- **Comment (es):** "Usar `deliver_later` para no bloquear el hilo de la request"

#### 11. Background Job Not Idempotent
- Flag jobs that are not safe to retry (e.g., charging a card, sending an email) without idempotency checks
- Flag jobs passing full ActiveRecord objects as arguments (pass IDs instead)
- **Comment (en):** "Pass the record ID instead of the object — AR objects can go stale between enqueue and perform"
- **Comment (es):** "Pasar el ID en lugar del objeto — los objetos AR pueden quedar desactualizados entre enqueue y perform"

#### 12. `has_many` Missing `dependent:`
- Flag `has_many` or `has_one` associations that don't specify `dependent: :destroy` or `dependent: :nullify` when applicable
- **Comment (en):** "Missing `dependent:` — decide if associated records should be destroyed or nullified when parent is deleted"
- **Comment (es):** "Falta `dependent:` — definir si los registros asociados se destruyen o nullifican cuando se elimina el padre"

#### 13. Repetitive ERB Markup
- When 3+ ERB blocks are identical and differ only in data, extract to a partial with locals
- **Comment (en):** "Repetitive markup — extract to a partial: `render partial: 'item', collection: @items, as: :item`"
- **Comment (es):** "Markup repetitivo — extraer a un partial: `render partial: 'item', collection: @items, as: :item`"

#### 14. Instance Variables in Partials
- Flag partials that depend on `@instance_variables` set by a controller instead of receiving locals
- **Comment (en):** "Pass locals to the partial instead of relying on `@instance_variable`"
- **Comment (es):** "Pasar locals al partial en lugar de depender de `@instance_variable`"

#### 15. Unnecessary Wrapper Elements in ERB
- Same as the frontend rule: remove `<div>` or `<span>` wrappers that only wrap a single element with no semantic or styling purpose
- Move classes from the wrapper to the child element
- **Comment (en):** "One less wrapper, same result"
- **Comment (es):** "Un wrapper menos y el mismo resultado"

---

### LOW PRIORITY (Optional / Suggestions)

#### 16. Non-RESTful Custom Actions
- Flag controllers adding custom actions beyond the 7 standard REST actions (`index`, `show`, `new`, `create`, `edit`, `update`, `destroy`) without strong justification
- **Comment (en):** "Consider extracting `action_name` to a dedicated controller to keep this one RESTful"
- **Comment (es):** "Considerar extraer `action_name` a un controller dedicado para mantener el actual RESTful"

#### 17. Enum Without Validation
- Flag integer enums without a database-level check or model validation protecting valid values
- **Comment (en):** "Add a validation or DB constraint to guard valid enum values"
- **Comment (es):** "Agregar una validación o constraint de DB para proteger los valores válidos del enum"

#### 18. Dead Code
- Flag commented-out code, unused methods, unused `require`/`require_relative`, orphaned routes
- **Comment (en):** "Remove unused code"
- **Comment (es):** "Eliminar código sin uso"

#### 19. Inconsistent Naming Conventions
- Flag camelCase method or variable names (Rails convention is `snake_case`)
- Flag singular/plural inconsistencies in model/table names
- **Comment (en):** "Rails convention: use `snake_case` for method/variable names"
- **Comment (es):** "Convención de Rails: usar `snake_case` para nombres de métodos y variables"

#### 20. Missing Test Coverage for New Code
- Flag new public methods, service objects, or controllers without corresponding spec files
- **Comment (en):** "New public method — add a spec for this"
- **Comment (es):** "Nuevo método público — agregar un spec para esto"

---

### FRONTEND RULES FOR ERB FILES

When the PR contains `.html.erb` files, also apply the rules from [quality-rules.md](quality-rules.md). The most applicable ones for ERB are:

- **No blank lines between siblings** (Rule 4)
- **Eliminate unnecessary DOM wrappers** (Rule 3 and Rule 15) — same principle applies in ERB
- **Use semantic HTML** — prefer `<button>`, `<a>`, `<nav>`, `<section>` over generic `<div>`
- **Use `link_to` for internal navigation** instead of `onclick` handlers or hardcoded `<a href="...">` with JS — this is the Rails equivalent of Rule 2
- **No logic in templates** — equivalent to Rule 6 (no unnecessary comments) and the general "keep views dumb" principle
- **DRY: move repeated classes to a parent or extract to a partial** (Rule 7)

---

### COMMENT FORMAT (Lead's Style)

- Direct and concise
- Always include code suggestions when possible
- Friendly but direct tone

**Sample comments (en):**
- "N+1 query — add `.includes(:author)` when fetching posts"
- "SQL injection risk — use `.where(email: params[:email])`"
- "Missing strong params — whitelist only what this action needs"
- "Move this side effect out of the callback"
- "One less wrapper, same result"
- "Pass the record ID, not the object"
- "Leftover debug statement"

**Sample comments (es):**
- "N+1 query — agregá `.includes(:author)` al traer posts"
- "Riesgo de SQL injection — usá `.where(email: params[:email])`"
- "Faltan strong params — permitir solo lo que esta acción necesita"
- "Mover este side effect fuera del callback"
- "Un wrapper menos y el mismo resultado"
- "Pasar el ID del registro, no el objeto"
- "Se quedó un debug"

---

## Review Instructions

1. Check each changed file against applicable rules (backend rules for `.rb`, view rules for `.html.erb`, migration rules for `db/migrate/`)
2. For EACH violation found, leave an inline comment on the **EXACT line** where the problem occurs
3. Use `gh pr diff $PR_NUMBER` to identify exact line numbers in the modified files
4. Be concise and direct — just like a team lead would comment
5. Prefer `` ```suggestion `` blocks for single-line fixes (enables one-click fix in GitHub)
6. Use `` ```ruby `` blocks for multi-line suggestions

---

## Submitting the Review

### Step 0: Get Repository Information

```bash
REPO_OWNER=$(gh repo view --json owner --jq '.owner.login')
REPO_NAME=$(gh repo view --json name --jq '.name')
```

### Step 1: Get the Latest Commit SHA and Review the Diff

```bash
COMMIT_SHA=$(gh pr view $PR_NUMBER --json commits --jq '.commits[-1].oid')
gh pr diff $PR_NUMBER
```

**Finding the Exact Line Number:**
```diff
@@ -10,5 +10,8 @@ class PostsController < ApplicationController
   def index
-    @posts = Post.all
+    @posts = Post.all                     <- This is line 12
+    @posts.each do |post|                 <- This is line 13
+      puts post.author.name              <- This is line 14 (N+1 here)
+    end
   end
```
Comment on **line 14** where the N+1 actually happens, not line 10 where the action starts.

### Step 2: For Each Violation Found

**Single-line comment:**
```bash
gh api repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER/comments \
  -f body="COMMENT_TEXT" \
  -f commit_id="$COMMIT_SHA" \
  -f path="FILE_PATH" \
  -F line=EXACT_LINE_NUMBER \
  -f side="RIGHT"
```

**Multi-line comment:**
```bash
gh api repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER/comments \
  -f body="COMMENT_TEXT" \
  -f commit_id="$COMMIT_SHA" \
  -f path="FILE_PATH" \
  -F start_line=START_LINE_NUMBER \
  -F line=END_LINE_NUMBER \
  -f side="RIGHT"
```

**Comment with suggestion (single line fix):**
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

**Comment with ruby example (multi-line):**
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

**Important Notes:**
- `line` must be the **exact line number** where the issue is in the file
- For multi-line issues: use `start_line` and `line`
- `side` should be "RIGHT" for additions/modifications, "LEFT" for deletions
- Each comment is created independently

### Step 3: Summary Review

**If COMMENT_LANGUAGE=en:**
```bash
gh pr review $PR_NUMBER --request-changes --body "Review completed: [X] comments left in the code

**Summary:**
- [Brief list of issue categories found]

**Positive observations:**
- [List of things done well]

_Lead review bot_"
```

**If COMMENT_LANGUAGE=es:**
```bash
gh pr review $PR_NUMBER --request-changes --body "Revision completada: [X] comentarios dejados en el codigo

**Resumen:**
- [Breve lista de categorias de issues encontrados]

**Observaciones positivas:**
- [Lista de cosas bien hechas]

_Lead review bot_"
```

### If No Violations:

**If COMMENT_LANGUAGE=en:**
```bash
gh pr review $PR_NUMBER --approve --body "Everything looks good! Clean Rails code following project standards.

_Lead review bot_"
```

**If COMMENT_LANGUAGE=es:**
```bash
gh pr review $PR_NUMBER --approve --body "Todo se ve bien! Codigo Rails limpio y siguiendo los estandares del proyecto.

_Lead review bot_"
```
