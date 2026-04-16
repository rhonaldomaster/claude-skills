# Frontend Code Quality Rules

Follow these 18 rules strictly when writing or reviewing frontend code.

## Rule 1: No Leading/Trailing Whitespace in Attributes

Remove unnecessary whitespace in className, href, and other attributes.

```jsx
// Bad
<div className=" flex items-center " />

// Good
<div className="flex items-center" />
```

## Rule 2: Always Use Framework Router for Internal Navigation

Use the framework's navigation component (e.g., `<Link>`) instead of programmatic navigation for simple links.

```jsx
// Bad
<button onClick={() => router.push('/page')}>Go</button>

// Good
<Link href="/page">Go</Link>
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
const url = buildUrl(persona, platform, 'page');

// Good
const url = `/${persona}/${platform}/page`;
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
<Link href={`/${props.persona}/${props.platform}/page`}>

// Good
const { persona, platform } = props;
<Link href={`/${persona}/${platform}/page`}>
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

## Rule 16: Design Components Library-Ready

Use generic className props instead of platform-specific ones.

```jsx
// Bad
<Dialog androidButtonStyle="text-green-600" iosButtonStyle="text-blue-600" />

// Good
<Dialog customClassesButtons="text-green-600 font-medium" />
```

## Rule 17: Never Break Backward Compatibility

Make existing props smarter, don't create new ones.

```jsx
// Bad - Breaking change
const reverseClasses = newLayoutProp ? 'flex-row' : 'flex-col';

// Good - Backward compatible
const reverseClasses = oldProp && !customClasses ? 'flex flex-col flex-col-reverse' : '';
```

## Rule 18: Custom Classes Override Defaults

Use `customClasses || 'defaults'` pattern.

```jsx
// Bad - Hard to customize
<div className="px-4 py-2 bg-white rounded">

// Good - Flexible
<div className={customClassesModal || 'px-4 py-2 bg-white rounded'}>
```

## Quick Reference Checklist

When writing or reviewing code, check:

- [ ] No whitespace in className strings
- [ ] Using framework Link for internal navigation
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
- [ ] Components are library-ready
- [ ] Backward compatibility maintained
- [ ] customClasses pattern used
