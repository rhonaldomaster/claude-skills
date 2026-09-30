# Rails

## File → Ruleset Map

- `.rb` files → apply Rails backend rules (Code Quality Rules below)
- `.html.erb` files → apply **both** ERB/view rules and frontend rules for ERB (ERB section below)
- `db/migrate/*.rb` → pay extra attention to migration rules (indexes, constraints)
- `spec/` or `test/` → apply testing rules
- `app/jobs/` → apply background job rules
- `app/mailers/` → apply mailer rules

## Diff Example

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

## Code-Fence Language

`ruby`

## Stack Label (en)

Rails

## Stack Label (es)

Rails

## Tambora Orientation

backend

## Code Quality Rules

### PR Metadata (check first)

#### Rule 0 — PR Title & Commit Messages (only if `TICKET_ID` is set)
- Skip this rule entirely if no Jira ticket ID was provided or inferred — code-only reviews have no ticket to reference.
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

- **en:** "N+1 query, add `.includes(:association)` when fetching `Model`"
- **es:** "N+1 query, agregá `.includes(:association)` al traer `Model`"

#### Rule 2 — SQL Injection via String Interpolation
- Flag `where("name = '#{params[:name]}'")`  or `.sum("#{params[:col]}")`.
- Flag any raw SQL with user input interpolated directly.

```ruby
# Bad
User.where("email = '#{params[:email]}'")

# Good
User.where(email: params[:email])
```

- **en:** "SQL injection risk, use parameterized query: `.where(name: params[:name])`"
- **es:** "Riesgo de SQL injection, usá query parametrizada: `.where(name: params[:name])`"

#### Rule 3 — Missing Strong Parameters / Mass Assignment
- Flag `params.permit!` (allows all attributes).
- Flag `update(params)` or `create(params)` without whitelisting.
- Flag permitting sensitive attributes like `role`, `admin`, `deleted_at`.

- **en:** "Missing strong params, whitelist only the attributes this action needs"
- **es:** "Faltan strong params, permitir solo los atributos que esta acción necesita"

#### Rule 4 — Missing Database Index
- Flag new foreign key columns in migrations without a corresponding `add_index`.
- Flag uniqueness validations (`validates :email, uniqueness: true`) without a unique index in the migration.

- **en:** "Missing index on `column_name`, add `add_index :table, :column_name` to this migration"
- **es:** "Falta índice en `column_name`, agregar `add_index :table, :column_name` en esta migración"

#### Rule 5 — Forgotten Debug Statements
- Flag `binding.pry`, `byebug`, `debugger`, `puts`, `p `, `pp ` left in production code.

- **en:** "Leftover debug statement"
- **es:** "Se quedó un debug"

#### Rule 6 — Missing `null: false` Constraint
- Flag `validates :field, presence: true` in the model when the corresponding migration column lacks `null: false`.
- Validations can be bypassed via `update_column` or direct DB writes — the constraint must also exist at DB level.

- **en:** "Add `null: false` to the migration column (validations can be bypassed at DB level)"
- **es:** "Agregá `null: false` a la migración (las validaciones se pueden bypassear a nivel DB)"

---

### MEDIUM PRIORITY (Comment if obvious)

#### Rule 7 — Callback with Side Effects
- Flag `after_create`, `after_save`, etc. that send emails, make HTTP requests, or enqueue jobs.
- These should live in a service object or be explicit in the controller.

- **en:** "Move this side effect out of the callback, use a service object or explicit call in the controller"
- **es:** "Mover este side effect fuera del callback, usar un service object o llamada explícita en el controller"

#### Rule 8 — Logic in Views / ERB Files
- Flag database queries inside `.html.erb` files.
- Flag complex Ruby conditionals or loops in ERB.
- Suggest moving logic to helpers, presenters, or the controller.

- **en:** "Avoid queries/logic in views, move to a helper or presenter"
- **es:** "Evitar queries/lógica en las vistas, mover a un helper o presenter"

#### Rule 9 — Fat Controller
- Flag controllers with business logic: calculations, data transformation, multi-model operations.

- **en:** "Business logic in controller, extract to a service object"
- **es:** "Lógica de negocio en el controller, extraer a un service object"

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

- **en:** "Pass the record ID instead of the object (AR objects can go stale between enqueue and perform)"
- **es:** "Pasar el ID en lugar del objeto (los objetos AR pueden quedar desactualizados entre enqueue y perform)"

#### Rule 12 — `has_many` Missing `dependent:`
- Flag `has_many` or `has_one` associations that don't specify `dependent: :destroy` or `dependent: :nullify` when applicable.

- **en:** "Missing `dependent:`, decide if associated records should be destroyed or nullified when parent is deleted"
- **es:** "Falta `dependent:`, definir si los registros asociados se destruyen o nullifican cuando se elimina el padre"

#### Rule 13 — Repetitive ERB Markup
- When 3+ ERB blocks are identical and differ only in data, extract to a partial with locals.

- **en:** "Repetitive markup, extract to a partial: `render partial: 'item', collection: @items, as: :item`"
- **es:** "Markup repetitivo, extraer a un partial: `render partial: 'item', collection: @items, as: :item`"

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

- **en:** "New public method, add a spec for this"
- **es:** "Nuevo método público, agregar un spec para esto"

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

### CSS RULES

When the PR contains stylesheet changes, check for `tailwind.config.*` to know whether the Tailwind rules apply, and for `.scss`/`.css` files under `app/assets/stylesheets/` to know whether the traditional CSS rules apply. Both can apply in the same project.

#### Rule 26 — Consistent Utility Class Order (Tailwind, MEDIUM PRIORITY)
- Group utility classes in a consistent order: layout → spacing → sizing → typography → color → state.

- **en:** "Keep utility class order consistent: layout, spacing, sizing, typography, color, state"
- **es:** "Mantener orden consistente en las utility classes: layout, spacing, sizing, typography, color, state"

#### Rule 27 — `!important` Without Justification (HIGH PRIORITY)
- Flag `!important` in CSS/Sass or Tailwind's `!` modifier without a comment explaining why. Fix specificity or source order instead.

```scss
// Bad
.card { color: red !important; }

// Good
.card--error { color: red; }
```

- **en:** "Avoid `!important`, fix the specificity/source order instead"
- **es:** "Evitar `!important`, arreglar la especificidad u orden en vez de eso"

#### Rule 28 — Deep Selector Nesting (Sass, MEDIUM PRIORITY)
- Flag nesting deeper than 3 levels in `.scss` partials — it increases specificity and couples styles to markup structure.

```scss
// Bad
.card { .header { .title { .icon { color: red; } } } }

// Good
.card__icon { color: red; }
```

- **en:** "Nesting too deep, flatten with a BEM-style class instead"
- **es:** "Anidamiento muy profundo, aplanar con una clase estilo BEM"

#### Rule 29 — Hardcoded Values Instead of Variables (Sass, LOW PRIORITY)
- Flag colors, spacing, or breakpoints repeated across `.scss` partials instead of coming from a Sass variable or CSS custom property.

- **en:** "Repeated hardcoded value, use a Sass variable or custom property"
- **es:** "Valor hardcodeado repetido, usar una variable de Sass o custom property"

#### Rule 30 — Inconsistent Naming Convention (Sass, LOW PRIORITY)
- Flag mixed naming conventions (e.g. BEM mixed with plain descendant selectors) within the same stylesheet.

- **en:** "Naming inconsistency, stick to one convention (e.g. BEM) across the stylesheet"
- **es:** "Inconsistencia de nombres, mantener una sola convención (ej. BEM) en toda la hoja de estilos"
