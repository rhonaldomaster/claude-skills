# Shopify

## File → Ruleset Map

- `sections/*.liquid` → apply section rules (schema, blocks, settings)
- `snippets/*.liquid` → apply snippet/partial rules
- `templates/*.json`, `templates/*.liquid` → apply template rules
- `layout/*.liquid` → apply layout rules (global impact — review carefully)
- `assets/*.js` → apply JavaScript rules
- `assets/*.css` → apply CSS rules
- `config/settings_schema.json` → apply theme settings rules
- `locales/*.json` → apply translation rules

## Diff Example

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

## Code-Fence Language

`liquid`

## Stack Label (en)

Shopify theme

## Stack Label (es)

de tema Shopify

Note: this label reads as "El codigo **de tema Shopify** sigue los estandares..." — it is not a
literal translation of the (en) label, it fits a different grammatical slot in the Spanish
sentence. Substitute it verbatim into the template's `{LABEL}` position; do not translate
`Shopify theme` directly.

## Tambora Orientation

frontend

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

#### Rule 1 — Raw Output Without Escaping (`| raw`)
- Liquid auto-escapes by default. Flag any use of `| raw` on user-controlled or metafield content.
- Only acceptable for trusted, developer-controlled HTML (e.g. SVG icons hardcoded in the theme).

```liquid
{%- comment -%} Bad — user-controlled content rendered raw {%- endcomment -%}
{{ product.description | raw }}

{%- comment -%} Good {%- endcomment -%}
{{ product.description }}
```

- **en:** "Avoid `| raw` on user-controlled content (Liquid auto-escapes by default; `raw` bypasses XSS protection)"
- **es:** "Evitar `| raw` en contenido controlado por el usuario (Liquid escapa automáticamente; `raw` bypasea la protección XSS)"

#### Rule 2 — Hardcoded Strings (Not Using Translations)
- Flag user-facing strings hardcoded in Liquid instead of using `{{ 'key' | t }}`.

```liquid
{%- comment -%} Bad {%- endcomment -%}
<button>Add to cart</button>

{%- comment -%} Good {%- endcomment -%}
<button>{{ 'products.product.add_to_cart' | t }}</button>
```

- **en:** "Hardcoded string, use `{{ 'key' | t }}` and add the key to `locales/en.default.json`"
- **es:** "String hardcodeado, usar `{{ 'key' | t }}` y agregar la clave en `locales/en.default.json`"

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

- **en:** "Missing or invalid section schema, every section needs a `{% schema %}` block with valid JSON"
- **es:** "Falta o es inválido el schema de la sección, cada sección necesita un bloque `{% schema %}` con JSON válido"

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

- **en:** "Repetitive markup, extract to a snippet: `{% render 'snippet-name', param: value %}`"
- **es:** "Markup repetitivo, extraer a un snippet: `{% render 'snippet-name', param: value %}`"

#### Rule 9 — Missing Accessibility Attributes
- Flag interactive elements (`<button>`, `<a>`) without `aria-label` when they have no visible text.
- Flag missing `alt` on `<img>` tags (use `alt=""` for decorative images).
- Flag missing `role` on custom interactive elements built from `<div>`.

- **en:** "Missing accessibility attribute, add `aria-label` or `alt` for screen reader support"
- **es:** "Falta atributo de accesibilidad, agregar `aria-label` o `alt` para soporte de lectores de pantalla"

#### Rule 10 — Missing Responsive Behavior
- Flag sections or components with fixed pixel widths instead of fluid/responsive units.
- Flag missing breakpoint handling in CSS for new components.

- **en:** "Check responsive behavior, verify this renders correctly on mobile (375px) and tablet (768px)"
- **es:** "Verificar comportamiento responsivo, asegurarse que se vea correctamente en mobile (375px) y tablet (768px)"

#### Rule 11 — Theme Settings Added Without Defaults
- Flag new settings in `settings_schema.json` or section schemas without a `default` value.
- Missing defaults can cause the theme to break on fresh installs or preview.

```json
// Bad
{ "type": "text", "id": "heading", "label": "Heading" }

// Good
{ "type": "text", "id": "heading", "label": "Heading", "default": "Welcome" }
```

- **en:** "Missing `default` for this setting, add one to prevent empty state on fresh installs"
- **es:** "Falta `default` para este setting, agregar uno para evitar estado vacío en instalaciones nuevas"

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

- **en:** "Deprecated filter, use `| image_url` instead of `| img_url`"
- **es:** "Filtro deprecado, usar `| image_url` en vez de `| img_url`"

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

- **en:** "Missing `presets` in section schema, merchants won't be able to add this section in the Theme Customizer"
- **es:** "Falta `presets` en el schema de la sección, los merchants no podrán agregar esta sección desde el Theme Customizer"

#### Rule 16 — Inconsistent Naming Conventions
- Flag section/snippet file names that don't follow the project's naming convention (typically `kebab-case`).
- Flag schema setting `id` values that don't use `snake_case`.

- **en:** "Naming inconsistency, use `kebab-case` for file names and `snake_case` for setting IDs"
- **es:** "Inconsistencia de nombres, usar `kebab-case` para nombres de archivos y `snake_case` para IDs de settings"

---

### CSS RULES

Check for `tailwind.config.*` to know whether the Tailwind rules apply (some themes compile Tailwind into `assets/*.css`); check `assets/*.css`/`.scss.liquid` to know whether the traditional CSS rules apply. Both can apply in the same theme.

#### Rule 17 — Consistent Utility Class Order (Tailwind, MEDIUM PRIORITY)
- Group utility classes in a consistent order: layout → spacing → sizing → typography → color → state.

- **en:** "Keep utility class order consistent: layout, spacing, sizing, typography, color, state"
- **es:** "Mantener orden consistente en las utility classes: layout, spacing, sizing, typography, color, state"

#### Rule 18 — `!important` Without Justification (HIGH PRIORITY)
- Flag `!important` in theme CSS, or Tailwind's `!` modifier, without a comment explaining why. Theme CSS often fights the Shopify checkout/cart drawer styles with `!important` — fix specificity or load order instead.

- **en:** "Avoid `!important`, fix the specificity/load order instead"
- **es:** "Evitar `!important`, arreglar la especificidad u orden de carga en vez de eso"

#### Rule 19 — Global Selectors in Section-Scoped CSS (MEDIUM PRIORITY)
- Flag bare tag selectors (`h2`, `button`, `.container`) inside a section's inline `{% style %}` block or a section-specific stylesheet — they leak into every other section on the page.

```liquid
{%- comment -%} Bad — leaks to every h2 on the page {%- endcomment -%}
{% style %}
  h2 { margin-bottom: 20px; }
{% endstyle %}

{%- comment -%} Good {%- endcomment -%}
{% style %}
  .hero-{{ section.id }} h2 { margin-bottom: 20px; }
{% endstyle %}
```

- **en:** "Scope this selector to the section (e.g. `.hero-{{ section.id }}`) to avoid affecting other sections"
- **es:** "Delimitar este selector a la sección (ej. `.hero-{{ section.id }}`) para no afectar otras secciones"

#### Rule 20 — Deep Selector Nesting (Sass, LOW PRIORITY)
- Flag nesting deeper than 3 levels in `.scss.liquid` — it increases specificity and couples styles to markup structure.

- **en:** "Nesting too deep, flatten with a BEM-style class instead"
- **es:** "Anidamiento muy profundo, aplanar con una clase estilo BEM"

#### Rule 21 — Hardcoded Values Instead of Variables (LOW PRIORITY)
- Flag colors, spacing, or breakpoints repeated across theme stylesheets instead of coming from a CSS custom property or theme setting.

- **en:** "Repeated hardcoded value, use a custom property or theme setting"
- **es:** "Valor hardcodeado repetido, usar una custom property o theme setting"
