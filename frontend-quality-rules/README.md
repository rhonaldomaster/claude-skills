## frontend-quality-rules

Frontend code quality rules for writing and reviewing React/JSX code. Applied automatically when writing React/JSX code, reviewing code, or when code quality is mentioned — not a Jira/GitHub-integrated workflow, just a reference ruleset.

## Usage

This skill has no arguments and is not invoked with a slash command — it activates automatically based on its description whenever React/JSX code is being written or reviewed.

## Rules covered

16 rules, including:
- No leading/trailing whitespace in attributes
- Use framework `Link` components for internal navigation instead of `onClick` + `router.push`
- Eliminate unnecessary DOM wrappers
- No blank lines between JSX siblings
- No unnecessary variables, trivial functions, or comments
- DRY on inheritable classes
- No duplicated derived state
- Condense simple conditionals
- Use destructuring when beneficial
- Custom classes override defaults instead of merging

See `SKILL.md` for the full list with before/after examples and a quick-reference checklist.
