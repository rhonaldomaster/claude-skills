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
