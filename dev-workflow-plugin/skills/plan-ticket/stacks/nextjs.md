# Next.js Stack Rules

## Explore Agents

Launch up to 3 Explore agents in parallel:

### Agent 1: Pages, Routes & Components

- Based on the ticket description, find the pages, layouts, and components that need to be modified or created
- Check `app/` directory for existing route segments and layouts
- Review relevant page components and their data fetching patterns (server components, `use` hooks, etc.)
- Identify shared UI components in `components/` or `src/components/`
- Check for existing API routes in `app/api/` if applicable

### Agent 2: Hooks, Stores & Utilities

- Search for existing custom hooks that can be reused or extended
- Look for state management patterns (context, Zustand, Redux, etc.)
- Check for existing utility functions and helpers
- Review service/API client layers for data fetching patterns
- Note any existing validation schemas (Zod, Yup, etc.) on related forms

### Agent 3: Tests, Stories & Supporting Code

- Check for existing test files (`__tests__/`, `*.test.tsx`, `*.spec.tsx`) and their patterns
- Review Storybook stories (`__stories__/`, `*.stories.tsx`) for related components
- Check for existing mock data or test utilities
- Identify if new API routes or middleware are needed
- Review existing TypeScript types/interfaces in `types/` or co-located files

**Important**: If the ticket involves new pages or routes, verify the current route structure in the `app/` directory before proposing new segments.

## Stack-Specific Plan Sections

Include these sections in the plan between "Reusable Code" and "Implementation Steps":

### Component Structure

| Component       | Type            | Description                  |
| --------------- | --------------- | ---------------------------- |
| `ComponentName` | Server / Client | What it renders and its role |

> Specify whether each component is a Server Component or Client Component (`'use client'`).

### API Integration

<If applicable: endpoints consumed, request/response shapes, error handling.>
<If new API routes are needed, specify the route and handler.>

> If no API changes are needed, write "No API changes required."

### State Management

<If applicable: what state is needed, where it lives (local, context, store), and why.>

> If no new state management is needed, write "Uses existing patterns."

## Testing Sections

### Component Tests

- `__tests__/<component>.test.tsx` — render test + main interaction scenarios

### Hook / Utility Tests

- `__tests__/<hook>.test.ts` — input/output, edge cases

### Integration Tests

- If the feature involves multiple components or pages, describe integration test scenarios

> Include mock data or fixtures that need to be created.

## Quality Notes

- **Accessibility**: Semantic HTML, ARIA labels, keyboard navigation, focus-visible
- **Mobile-first**: Design for mobile breakpoints first, then scale up
- **Performance**: Prefer Server Components where possible, lazy load heavy client components
- **Type safety**: All props and API responses must be typed

## Verification Commands

```
- Run `pnpm build` — build succeeds with no errors
- Run `pnpm lint` — no lint errors
- Run `pnpm type-check` — no TypeScript errors
- Run `pnpm test:run` — all tests pass
```
