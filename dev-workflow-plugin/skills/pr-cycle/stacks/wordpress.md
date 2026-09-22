# WordPress

## File → Ruleset Map

- `functions.php`, `inc/`, `includes/` → apply hooks, enqueue, and general PHP rules
- `template-parts/`, `templates/`, `*.php` theme templates → apply template, output escaping, and frontend (HTML/CSS/JS) rules
- `*.php` plugin files → apply plugin-specific rules (activation hooks, options API, REST endpoints)
- `assets/js/`, `assets/css/` → apply JavaScript/AJAX rules and frontend (HTML/CSS/JS) rules
- `acf-json/` → apply ACF field group rules

## Diff Example

```diff
@@ -15,5 +15,8 @@ function my_theme_setup() {
  function my_custom_query() {
-   $posts = get_posts(['post_type' => 'event']);
+   global $wpdb;                                         <- This is line 18
+   $type = $_GET['type'];                                <- This is line 19
+   $posts = $wpdb->get_results("SELECT * FROM wp_posts WHERE post_type = '$type'"); <- line 20 (injection)
  }
```

## Code-Fence Language

`php`

## Stack Label (en)

WordPress

## Stack Label (es)

WordPress

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

- **en:** "SQL injection risk, use `$wpdb->prepare()` for all queries with dynamic values"
- **es:** "Riesgo de SQL injection, usar `$wpdb->prepare()` para todas las queries con valores dinámicos"

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

- **en:** "XSS risk, escape output with `esc_html()`, `esc_attr()`, `esc_url()`, or `wp_kses_post()` depending on context"
- **es:** "Riesgo de XSS, escapar salida con `esc_html()`, `esc_attr()`, `esc_url()`, o `wp_kses_post()` según el contexto"

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

- **en:** "Missing sanitization, use `sanitize_text_field()`, `absint()`, `sanitize_email()`, etc. before processing user input"
- **es:** "Falta sanitización, usar `sanitize_text_field()`, `absint()`, `sanitize_email()`, etc. antes de procesar input del usuario"

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

- **en:** "Missing nonce verification, add `check_ajax_referer()` or `wp_verify_nonce()` before processing the request"
- **es:** "Falta verificación de nonce, agregar `check_ajax_referer()` o `wp_verify_nonce()` antes de procesar la request"

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

- **en:** "Never hardcode `<script>` or `<link>` tags, use `wp_enqueue_script()` / `wp_enqueue_style()`"
- **es:** "No hardcodear tags `<script>` o `<link>`, usar `wp_enqueue_script()` / `wp_enqueue_style()`"

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

- **en:** "Missing capability check, verify with `current_user_can()` before performing privileged operations"
- **es:** "Falta verificación de capacidad, verificar con `current_user_can()` antes de realizar operaciones privilegiadas"

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

- **en:** "Not translation ready, wrap user-facing strings with `__()`, `_e()`, or `esc_html__()`"
- **es:** "No está listo para traducción, envolver strings de usuario con `__()`, `_e()`, o `esc_html__()`"

#### Rule 10 — Logic in Templates
- Flag complex PHP logic, queries, or business rules inside template files (`template-parts/`, `*.php` templates).
- Templates should receive pre-prepared data via the template loader or global variables set in `functions.php`.

- **en:** "Avoid queries/logic in templates, move to `functions.php`, a custom class, or a template controller"
- **es:** "Evitar queries/lógica en templates, mover a `functions.php`, una clase personalizada, o un template controller"

#### Rule 11 — Missing `wp_unslash()` Before Sanitizing
- Flag code that sanitizes `$_POST`/`$_GET` without first calling `wp_unslash()`.
- WordPress adds slashes to incoming data; skipping `wp_unslash()` leads to corrupted stored values.

```php
// Bad
$value = sanitize_text_field($_POST['value']);

// Good
$value = sanitize_text_field(wp_unslash($_POST['value']));
```

- **en:** "Missing `wp_unslash()`, call it before sanitizing `$_POST`/`$_GET` to avoid double-slashing"
- **es:** "Falta `wp_unslash()`, llamarlo antes de sanitizar `$_POST`/`$_GET` para evitar doble escape"

#### Rule 12 — Repetitive Template Markup
- When 3+ template blocks are identical and differ only in data, extract to a `get_template_part()` call.

```php
// Bad — repeated block for each card
// <div class="card">...</div> × 3

// Good
get_template_part('template-parts/card', null, ['post' => $post]);
```

- **en:** "Repetitive markup, extract to a template part: `get_template_part('template-parts/card', null, ['post' => $post])`"
- **es:** "Markup repetitivo, extraer a un template part: `get_template_part('template-parts/card', null, ['post' => $post])`"

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

- **en:** "REST endpoint has no real permission check, replace `__return_true` with an actual capability check"
- **es:** "El endpoint REST no tiene verificación de permisos real, reemplazar `__return_true` con una verificación de capacidad"

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

- **en:** "New function, consider adding a test in the test suite"
- **es:** "Nueva función, considerar agregar un test en el suite de pruebas"

---

### FRONTEND (HTML/CSS/JS) — apply when the theme/plugin also renders frontend markup

These apply to template files (`*.php` output, `template-parts/`) and enqueued assets (`assets/js/`, `assets/css/`).

#### Rule 18 — Forgotten `console.log` (HIGH PRIORITY)
- Never leave `console.log()` in enqueued JavaScript.

- **en:** "Leftover console.log"
- **es:** "Se fue un console.log"

#### Rule 19 — Appropriate Elements (MEDIUM PRIORITY)
- Avoid click handlers on non-interactive elements like `<div>` or `<span>`.
- Use `<a href="...">` for navigation instead of a `<div>`/`<span>` with a JS click handler that changes `location.href`.

```html
<!-- Bad -->
<div class="card" onclick="location.href='/page'">...</div>

<!-- Good -->
<a href="/page" class="card">...</a>
```

- **en:** "Use a real `<a>` link for navigation instead of a click handler on a non-interactive element"
- **es:** "Usar un `<a>` real para navegación en vez de un handler de click sobre un elemento no interactivo"

#### Rule 20 — Image Paths (MEDIUM PRIORITY)
- Enqueued/template image paths should resolve via `get_template_directory_uri()`, `get_stylesheet_directory_uri()`, or theme functions, not hardcoded relative paths.

```php
// Bad
<img src="images/logo.png">

// Good
<img src="<?php echo esc_url(get_template_directory_uri() . '/images/logo.png'); ?>">
```

- **en:** "Image path should resolve via `get_template_directory_uri()` instead of a hardcoded relative path"
- **es:** "La ruta de la imagen debe resolverse con `get_template_directory_uri()` en vez de una ruta relativa fija"

#### Rule 21 — Indentation and Whitespace Consistency (LOW PRIORITY)
- Consistent indentation in HTML markup, JS, and CSS. No mixed tabs/spaces.
- No leading/trailing whitespace inside `class` attributes.

```html
<!-- Bad -->
<div class=" flex items-center " >

<!-- Good -->
<div class="flex items-center">
```

- **en:** "Inconsistent indentation or extra whitespace in the attribute"
- **es:** "Indentación inconsistente o espacio extra en el atributo"

#### Rule 22 — SVG Tags Not Properly Closed (LOW PRIORITY)
- Flag unclosed or malformed tags in inline SVG or sprite files.

- **en:** "Unclosed SVG tag"
- **es:** "Tag de SVG sin cerrar"

#### Rule 23 — Vague URL Parameters (LOW PRIORITY)
- Be specific with query params passed in links/AJAX calls, e.g. `?post_id=42` not just `?id`.

- **en:** "Be specific with the URL parameter name"
- **es:** "Ser específico con el nombre del parámetro de la URL"

#### Rule 24 — Dead Frontend Code (LOW PRIORITY)
- Flag commented-out markup/JS, unused CSS classes, orphaned enqueued assets no longer referenced.

- **en:** "Remove unused frontend code"
- **es:** "Eliminar código de frontend sin uso"

---

### CSS RULES

Check for `tailwind.config.*` to know whether the Tailwind rules apply; check for `assets/css/*.css`/`.scss` to know whether the traditional CSS rules apply. Many themes use both (Tailwind for new components, legacy Sass for the rest).

#### Rule 25 — Consistent Utility Class Order (Tailwind, MEDIUM PRIORITY)
- Group utility classes in a consistent order: layout → spacing → sizing → typography → color → state.

- **en:** "Keep utility class order consistent: layout, spacing, sizing, typography, color, state"
- **es:** "Mantener orden consistente en las utility classes: layout, spacing, sizing, typography, color, state"

#### Rule 26 — `!important` Without Justification (HIGH PRIORITY)
- Flag `!important` in enqueued CSS/Sass, or Tailwind's `!` modifier, without a comment explaining why. WordPress themes are especially prone to `!important` wars against core/plugin styles — fix specificity instead.

```css
/* Bad */
.entry-title { color: red !important; }

/* Good */
.entry-title--error { color: red; }
```

- **en:** "Avoid `!important`, fix the specificity/source order instead"
- **es:** "Evitar `!important`, arreglar la especificidad u orden en vez de eso"

#### Rule 27 — Deep Selector Nesting (Sass, MEDIUM PRIORITY)
- Flag nesting deeper than 3 levels in `.scss` partials — it increases specificity and couples styles to markup structure.

- **en:** "Nesting too deep, flatten with a BEM-style class instead"
- **es:** "Anidamiento muy profundo, aplanar con una clase estilo BEM"

#### Rule 28 — Hardcoded Values Instead of Variables (LOW PRIORITY)
- Flag colors, spacing, or breakpoints repeated across stylesheets instead of coming from a Sass variable or CSS custom property.

- **en:** "Repeated hardcoded value, use a variable or custom property"
- **es:** "Valor hardcodeado repetido, usar una variable o custom property"

#### Rule 29 — Enqueued Stylesheet Not Scoped (MEDIUM PRIORITY)
- Flag global selectors (`h1`, `.container`, `a`) in a plugin's enqueued stylesheet that can leak into the parent theme or other plugins. Prefix or scope plugin styles.

```css
/* Bad — plugin stylesheet affecting every h1 on the site */
h1 { margin-bottom: 20px; }

/* Good */
.my-plugin h1 { margin-bottom: 20px; }
```

- **en:** "Scope this selector to the plugin/theme namespace to avoid leaking into other styles"
- **es:** "Delimitar este selector al namespace del plugin/theme para no afectar otros estilos"
