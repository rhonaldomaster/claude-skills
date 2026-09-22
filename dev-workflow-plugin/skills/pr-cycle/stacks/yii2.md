# Yii2

## File → Ruleset Map

- `controllers/` → apply controller rules
- `models/` → apply model/ActiveRecord rules
- `views/` → apply view/template rules
- `migrations/` → pay extra attention to migration rules (indexes, constraints)
- `components/`, `widgets/` → apply reusable component rules
- `commands/` → apply console command rules
- `tests/` → apply testing rules
- `assets/` → apply asset rules

## Diff Example

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

## Code-Fence Language

`php`

## Stack Label (en)

Yii2

## Stack Label (es)

Yii2

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

- **en:** "SQL injection risk, use parameterized query or ActiveRecord instead of string interpolation"
- **es:** "Riesgo de SQL injection, usar query parametrizada o ActiveRecord en vez de interpolación de string"

#### Rule 2 — XSS via Unescaped Output
- Flag output that renders user-controlled data without escaping in views.
- Use `Html::encode()` for plain text, `HtmlPurifier::process()` for rich text.

```php
// Bad
<?= $model->comment ?>

// Good
<?= Html::encode($model->comment) ?>
```

- **en:** "XSS risk, escape user-controlled output with `Html::encode()`"
- **es:** "Riesgo de XSS, escapar salida controlada por el usuario con `Html::encode()`"

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

- **en:** "Missing validation, use `$model->load()` + `$model->validate()` before saving"
- **es:** "Falta validación, usar `$model->load()` + `$model->validate()` antes de guardar"

#### Rule 4 — Missing CSRF Protection
- Flag AJAX requests or form submissions that don't include the CSRF token.
- Flag actions decorated with `$this->enableCsrfValidation = false` without justification.

- **en:** "CSRF token missing (ensure forms include `<?= Html::hiddenInput(Yii::$app->request->csrfParam, Yii::$app->request->csrfToken) ?>` or use `ActiveForm`)"
- **es:** "Falta el CSRF token (verificar que el formulario incluya el token o usar `ActiveForm`)"

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

- **en:** "N+1 query, add eager loading: `->with('relation')`"
- **es:** "N+1 query, agregar eager loading: `->with('relation')`"

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

- **en:** "Missing index on `column_name`, add `createIndex()` to this migration"
- **es:** "Falta índice en `column_name`, agregar `createIndex()` en esta migración"

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

- **en:** "Avoid queries/logic in views, move to controller or model"
- **es:** "Evitar queries/lógica en las vistas, mover al controller o modelo"

#### Rule 9 — Fat Controller
- Flag controllers that contain business logic: calculations, complex data transformations, multi-model operations.
- Suggest extracting to a service class or model method.

- **en:** "Business logic in controller, extract to a service class or model method"
- **es:** "Lógica de negocio en el controller, extraer a una clase de servicio o método del modelo"

#### Rule 10 — `notNull()` Missing in Migration
- Flag `validates(['field'], 'required')` in the model when the migration column lacks `->notNull()`.
- Validations can be bypassed via direct DB writes.

```php
// Bad
$this->addColumn('{{%user}}', 'email', $this->string());

// Good
$this->addColumn('{{%user}}', 'email', $this->string()->notNull());
```

- **en:** "Add `->notNull()` to the migration column (required validations can be bypassed at DB level)"
- **es:** "Agregar `->notNull()` a la migración (las validaciones requeridas se pueden bypassear a nivel DB)"

#### Rule 11 — Missing Access Control
- Flag controller actions that don't check permissions via `behaviors()` with `AccessControl` or `VerbFilter`.
- Flag missing `Yii::$app->user->can()` checks for RBAC-protected operations.

- **en:** "Missing access control, add `AccessControl` behavior or `Yii::$app->user->can()` check"
- **es:** "Falta control de acceso, agregar behavior `AccessControl` o verificación `Yii::$app->user->can()`"

#### Rule 12 — Queue Job Passing Full ActiveRecord Object
- Flag jobs that serialize a full ActiveRecord object instead of passing its ID.
- AR objects can go stale between enqueue and execution.

```php
// Bad
Yii::$app->queue->push(new SendEmailJob(['user' => $user]));

// Good
Yii::$app->queue->push(new SendEmailJob(['userId' => $user->id]));
```

- **en:** "Pass the record ID instead of the object (AR objects can go stale between enqueue and execution)"
- **es:** "Pasar el ID en lugar del objeto (los objetos AR pueden quedar desactualizados entre enqueue y ejecución)"

#### Rule 13 — Repetitive View Markup
- When 3+ view blocks are identical and differ only in data, extract to a partial using `$this->render()` with params or a widget.

- **en:** "Repetitive markup, extract to a partial: `$this->render('_item', ['model' => $item])`"
- **es:** "Markup repetitivo, extraer a un partial: `$this->render('_item', ['model' => $item])`"

#### Rule 14 — Missing `defaultScope` / Soft Delete Guard
- Flag queries on models that implement soft delete (e.g. `deleted_at`) without a scope filtering deleted records.

- **en:** "Soft delete model, ensure queries filter out deleted records with a default scope or explicit condition"
- **es:** "Modelo con soft delete, asegurarse de filtrar registros eliminados con un scope por defecto o condición explícita"

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

- **en:** "Naming inconsistency (Yii2 convention: `camelCase` for methods, `snake_case` for DB columns)"
- **es:** "Inconsistencia de nombres (convención Yii2: `camelCase` para métodos, `snake_case` para columnas DB)"

#### Rule 18 — Missing Test Coverage for New Code
- Flag new public methods, services, or controllers without corresponding test files in `tests/`.

- **en:** "New public method, add a test for this in `tests/`"
- **es:** "Nuevo método público, agregar un test en `tests/`"

#### Rule 19 — Unnecessary View Wrappers
- Remove `<div>` or `<span>` wrappers in view files that only wrap a single child with no semantic or styling purpose.

- **en:** "One less wrapper, same result"
- **es:** "Un wrapper menos y el mismo resultado"
