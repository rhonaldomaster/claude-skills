---
name: frontend-quality-rules
description: Frontend code quality rules for writing and reviewing React/JSX code. This skill is automatically applied when writing React/JSX code, reviewing code, or when the user mentions code quality.
---

# Frontend Code Quality Rules

Follow these rules strictly when writing or reviewing frontend React/JSX code.

## Rule 1: No Leading/Trailing Whitespace in Attributes

Remove unnecessary whitespace in className, href, and other attributes.

```jsx
// Bad
<div className=" flex items-center " />

// Good
<div className="flex items-center" />
```

## Rule 2: Use Framework Link Components for Internal Navigation

Use the framework's Link component instead of programmatic navigation for simple internal links.

```jsx
// Bad
<button onClick={() => router.push('/page')}>Go</button>

// Good (Next.js)
<Link href="/page">Go</Link>

// Good (React Router)
<Link to="/page">Go</Link>
```

## Rule 3: Eliminate Unnecessary DOM Wrappers

Remove div elements that don't serve semantic or styling purposes.

```jsx
// Bad
<div><div className="content">Text</div></div>

// Good
<div className="content">Text</div>
```

## Rule 4: No Blank Lines Between HTML/JSX Siblings

Keep related JSX elements together without unnecessary blank lines.

```jsx
// Bad
<div>Content 1</div>

<div>Content 2</div>

// Good
<div>Content 1</div>
<div>Content 2</div>
```

## Rule 5: Simplify URLs and Remove Trivial Helpers

Use inline template literals instead of helper functions for simple URLs.

```jsx
// Bad
const url = buildUrl(section, 'page');

// Good
const url = `/${section}/page`;
```

## Rule 6: No Unnecessary Comments

Remove obvious or redundant comments. Code should be self-documenting.

```jsx
// Bad
// Set loading to true
setLoading(true);

// Good
setLoading(true);
```

## Rule 7: Apply DRY to Inheritable Classes

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

## Rule 8: No Unnecessary Variables

Don't create variables for single-use values.

```jsx
// Bad
const title = 'Page Title';
return <h1>{title}</h1>;

// Good
return <h1>Page Title</h1>;
```

## Rule 9: No Trivial Functions

Inline simple functions instead of creating named functions.

```jsx
// Bad
const handleClick = () => setOpen(true);
<button onClick={handleClick}>Open</button>

// Good
<button onClick={() => setOpen(true)}>Open</button>
```

## Rule 10: Prioritize the Least Amount of Code

Write concise code without sacrificing clarity.

## Rule 11: Use Destructuring When Beneficial

Destructure objects/arrays when multiple properties are used.

```jsx
// Bad (if using props.x multiple times)
<Link href={`/${props.section}/${props.id}/page`}>

// Good
const { section, id } = props;
<Link href={`/${section}/${id}/page`}>
```

## Rule 12: Use Clear and Consistent Naming

- Boolean variables: `isLoading`, `showModal`, `hasError`
- Functions: Use verbs (`handleClick`, `updateData`)
- Components: PascalCase (`UserProfile`)

## Rule 13: Do Not Duplicate Derived State in React

Avoid creating state for values that can be computed from existing state.

```jsx
// Bad
const [items, setItems] = useState([]);
const [itemCount, setItemCount] = useState(0);

// Good
const [items, setItems] = useState([]);
const itemCount = items.length;
```

## Rule 14: Condense Simple Conditionals

Use concise conditional patterns where appropriate.

```jsx
// Bad (for simple cases)
if (condition) {
  return <ComponentA />;
} else {
  return <ComponentB />;
}

// Good
return condition ? <ComponentA /> : <ComponentB />;
```

## Rule 15: Avoid Unnecessary HTML Elements

Eliminate redundant tags, especially `<p>` inside links and buttons.

```jsx
// Bad
<Link className="flex items-center p-4">
  <p className="text-black">My Link</p>
</Link>

// Good
<Link className="flex items-center p-4 text-black">
  My Link
</Link>

// Exception - Multiple semantic blocks
<Link className="flex flex-col p-4">
  <p className="text-lg font-bold">Title</p>
  <p className="text-sm text-gray-600">Description</p>
</Link>
```

## Rule 16: Custom Classes Should Override Defaults

When components accept custom styling, use a pattern where custom classes replace defaults entirely instead of merging unpredictably.

```jsx
// Bad - Hard to customize, merged classes may conflict
<div className={`px-4 py-2 bg-white rounded ${className}`}>

// Good - Custom classes fully replace defaults
<div className={customClasses || 'px-4 py-2 bg-white rounded'}>
```

## CSS Rules

Apply the rules below that match how the project styles components. Check for `tailwind.config.*` to know whether Tailwind rules apply; check for `.css`/`.module.css`/`.scss` files to know whether traditional CSS rules apply. Both can apply in the same project.

### Rule 17: Consistent Utility Class Order (Tailwind)

Group utility classes in a consistent order: layout → spacing → sizing → typography → color → state (`hover:`, `focus:`, etc.).

```jsx
// Bad
<div className="text-white flex bg-blue-500 p-4 items-center rounded" />

// Good
<div className="flex items-center p-4 rounded bg-blue-500 text-white" />
```

### Rule 18: No Arbitrary Values When a Token Exists (Tailwind)

Use theme tokens (`spacing`, `colors`, `fontSize`) instead of arbitrary values when an equivalent token is already defined in the Tailwind config.

```jsx
// Bad (if theme already defines spacing[5] = 1.25rem)
<div className="p-[1.25rem]" />

// Good
<div className="p-5" />
```

### Rule 19: No `!important` Without Justification

Avoid `!important` (Tailwind's `!` modifier or plain CSS). If a style truly must win, comment why — otherwise fix the specificity or source order instead.

```css
/* Bad */
.card { color: red !important; }

/* Good */
.card--error { color: red; }
```

### Rule 20: Extract Repeated Utility Blocks

3+ elements sharing the same long utility class string → extract to a component, or a single class via `@apply`, instead of repeating the string.

```jsx
// Bad
<span className="inline-flex items-center rounded-full px-3 py-1 text-sm font-medium bg-gray-100">A</span>
<span className="inline-flex items-center rounded-full px-3 py-1 text-sm font-medium bg-gray-100">B</span>

// Good
<Badge>A</Badge>
<Badge>B</Badge>
```

### Rule 21: Avoid Deep Selector Nesting (Sass/CSS)

Keep nesting to 3 levels or less. Deep nesting increases specificity and couples styles to markup structure.

```scss
// Bad
.card { .header { .title { .icon { color: red; } } } }

// Good
.card__icon { color: red; }
```

### Rule 22: Use Variables/Custom Properties Instead of Repeated Hardcoded Values (Sass/CSS)

Colors, spacing, and breakpoints repeated across the stylesheet should come from a variable or custom property, not be retyped.

```css
/* Bad */
.card { padding: 16px; color: #1a1a1a; }
.modal { padding: 16px; color: #1a1a1a; }

/* Good */
.card { padding: var(--spacing-md); color: var(--color-text); }
.modal { padding: var(--spacing-md); color: var(--color-text); }
```

### Rule 23: Consistent Naming Convention (Sass/CSS)

Follow the project's existing naming convention (e.g. BEM) consistently — don't mix conventions within the same stylesheet.

```css
/* Bad — mixed conventions */
.card-header { }
.cardFooter { }

/* Good — BEM */
.card__header { }
.card__footer { }
```

## Quick Reference Checklist

When writing or reviewing code, check:

- [ ] No whitespace in className strings
- [ ] Using Link components for internal navigation
- [ ] No unnecessary wrapper divs
- [ ] No blank lines between JSX siblings
- [ ] No trivial URL helper functions
- [ ] No obvious comments
- [ ] DRY applied to repeated classes
- [ ] No single-use variables
- [ ] No trivial named functions
- [ ] Code is concise
- [ ] Destructuring used appropriately
- [ ] Consistent naming conventions
- [ ] No duplicated derived state
- [ ] Ternary used for simple conditionals
- [ ] No redundant HTML elements
- [ ] Custom classes override defaults
- [ ] Consistent utility class order (Tailwind)
- [ ] No arbitrary values when a theme token exists (Tailwind)
- [ ] No `!important` without justification
- [ ] Repeated utility blocks extracted to a component or `@apply`
- [ ] No deep selector nesting (Sass/CSS)
- [ ] Variables/custom properties used instead of repeated hardcoded values (Sass/CSS)
- [ ] Consistent naming convention, not mixed (Sass/CSS)
