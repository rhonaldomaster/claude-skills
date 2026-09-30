# Next.js

## File → Ruleset Map

N/A — for each changed file, determine what functionality was added or modified and which acceptance criteria it maps to.

## Diff Example

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

## Code-Fence Language

`jsx`

## Stack Label (en)

## Stack Label (es)

## Tambora Orientation

frontend

## Example Phrasings

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

## Code Quality Rules

### PR Metadata (check first)

#### Rule 0 — PR Title & Commit Messages (only if `TICKET_ID` is set)
- Skip this rule entirely if no Jira ticket ID was provided or inferred — code-only reviews have no ticket to reference.
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

### CSS RULES

Check for `tailwind.config.*` to know whether the Tailwind rules apply; check for `.css`/`.module.css`/`.scss` files to know whether the traditional CSS rules apply. Both can apply in the same project.

#### Rule 24 — Consistent Utility Class Order (Tailwind, MEDIUM PRIORITY)
- Group utility classes in a consistent order: layout → spacing → sizing → typography → color → state.

```jsx
// Bad
<div className="text-white flex bg-blue-500 p-4 items-center rounded" />

// Good
<div className="flex items-center p-4 rounded bg-blue-500 text-white" />
```

- **en:** "Keep utility class order consistent: layout, spacing, sizing, typography, color, state"
- **es:** "Mantener orden consistente en las utility classes: layout, spacing, sizing, typography, color, state"

#### Rule 25 — Arbitrary Values Instead of Theme Tokens (Tailwind, MEDIUM PRIORITY)
- Flag arbitrary values (`w-[123px]`, `text-[#1a1a1a]`) when an equivalent token already exists in the Tailwind theme config.

```jsx
// Bad (theme already defines spacing[5] = 1.25rem)
<div className="p-[1.25rem]" />

// Good
<div className="p-5" />
```

- **en:** "Use the theme token instead of an arbitrary value, e.g. `p-5` instead of `p-[1.25rem]`"
- **es:** "Usar el token del theme en vez de un valor arbitrario, ej. `p-5` en vez de `p-[1.25rem]`"

#### Rule 26 — `!important` Without Justification (HIGH PRIORITY)
- Flag `!important` in CSS or Tailwind's `!` modifier without a comment explaining why it's needed. Fix specificity or source order instead.

```css
/* Bad */
.card { color: red !important; }

/* Good */
.card--error { color: red; }
```

- **en:** "Avoid `!important`, fix the specificity/source order instead"
- **es:** "Evitar `!important`, arreglar la especificidad u orden en vez de eso"

#### Rule 27 — Repeated Utility Blocks Not Extracted (Tailwind, MEDIUM PRIORITY)
- 3+ elements sharing the same long utility class string → extract to a component or a shared class via `@apply`.

```jsx
// Bad
<span className="inline-flex items-center rounded-full px-3 py-1 text-sm font-medium bg-gray-100">A</span>
<span className="inline-flex items-center rounded-full px-3 py-1 text-sm font-medium bg-gray-100">B</span>

// Good
<Badge>A</Badge>
<Badge>B</Badge>
```

- **en:** "Repeated utility classes, extract to a component or `@apply`"
- **es:** "Utility classes repetidas, extraer a un componente o `@apply`"

#### Rule 28 — Deep Selector Nesting (Sass/CSS, LOW PRIORITY)
- Flag nesting deeper than 3 levels in Sass/CSS Modules — it increases specificity and couples styles to markup structure.

```scss
// Bad
.card { .header { .title { .icon { color: red; } } } }

// Good
.card__icon { color: red; }
```

- **en:** "Nesting too deep, flatten with a BEM-style class instead"
- **es:** "Anidamiento muy profundo, aplanar con una clase estilo BEM"

#### Rule 29 — Hardcoded Values Instead of Variables (Sass/CSS, LOW PRIORITY)
- Flag colors, spacing, or breakpoints repeated across stylesheets instead of coming from a CSS custom property or Sass variable.

```css
/* Bad */
.card { padding: 16px; color: #1a1a1a; }
.modal { padding: 16px; color: #1a1a1a; }

/* Good */
.card { padding: var(--spacing-md); color: var(--color-text); }
.modal { padding: var(--spacing-md); color: var(--color-text); }
```

- **en:** "Repeated hardcoded value, use a variable/custom property"
- **es:** "Valor hardcodeado repetido, usar una variable/custom property"
