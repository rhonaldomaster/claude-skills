---
name: lead-review
description: "PR code review using team lead's architectural opinions and code standards. Use when reviewing PRs with lead's style."
argument-hint: "<PR_NUMBER>"
---

## Your Architecture Review

You are reviewing this PR on behalf of the team lead, enforcing their architectural opinions and code standards. Perform a comprehensive code review.

## Configuration

Set your preferred language for review comments:
- `COMMENT_LANGUAGE=en` (English - default)
- `COMMENT_LANGUAGE=es` (Spanish)

Review checklist:
- Code is simple and readable
- Functions and variables are well-named
- No duplicated code
- Proper error handling
- No exposed secrets or API keys
- Input validation implemented
- Performance considerations addressed

1. First, check the PR title, description, and commit messages:
   ```bash
   gh pr view $PR_NUMBER --json title,body,commits
   ```
2. Then, use `gh pr diff $PR_NUMBER` to see which files were changed.

3. Read the quality rules in [quality-rules.md](quality-rules.md) — these 18 rules supplement the review patterns below. Apply both sets when reviewing code.

4. Review the PR metadata (Step 1) and changed files (Step 2) and apply these rules based on the lead's historical review patterns:

### PR METADATA (Always check first)

#### 0. PR Title & Commit Messages
- **PR title MUST include the ticket number** and a meaningful description of what the PR does
- **Commit messages MUST also include the ticket number** and describe the actual change
- Reject vague or lazy titles like "initial commit", "feat/ initial commit", "update", "fix", "changes", "WIP", etc.
- This is an established project — there is no "initial commit". The title should reflect what was actually built or changed
- If the PR description links a ticket but the title/commits don't reference it, flag it
- **Expected format:** `[TICKET-ID] Brief description of what changed`
- This is checked BEFORE reviewing any code. If the title and commits are wrong, comment on it immediately

### HIGH PRIORITY (Always comment)

#### 1. Unnecessary DIVs (40% of comments)
- Remove divs that only wrap a single element without adding functionality
- Move classes from parent div to child element
- See quality-rules.md Rules 3 and 15 for examples

#### 2. Forgotten Console.log (10% of comments)
- Never leave console.log() in production code
- Comment: "Leftover console.log"

#### 3. Duplicate Files (15% of comments)
- Check if images/assets already exist with another name
- Comment: "This file already exists as `existing-name.ext`"

#### 4. Duplicate Components (10% of comments)
- Use existing components before creating new ones
- Check if similar components already exist in the project
- Comment: "There's a component for this (recently added) `ComponentName`"

### MEDIUM PRIORITY (Comment if obvious)

#### 5. Image Paths (8% of comments)
- Paths must start with `/`
- Example: `/images/logo.png` not `images/logo.png`

#### 6. Component Documentation (7% of comments)
- New components must be documented according to the project's documentation standards
- Comment: "Remember to add documentation for this component"

#### 7. Indentation (5% of comments)
- Maintain consistent indentation in arrays/objects
- Especially in React component props

#### 8. Use appropriate elements
- Avoid using `onClick` on non-interactive elements like `div`
- If you have a `button` with `onClick` that redirects to another page, use `Link` for internal navigation or `a` for external links
- See quality-rules.md Rule 2 for examples

#### 9. Repetitive JSX — use `.map()` instead
- When 3 or more JSX elements are identical and only differ in text content or a single prop, extract the data into a `const` array and render with `.map()`
- Keep data separate from markup — define the array above the `return`, not inline

### LOW PRIORITY (Optional)

#### 10. Dead Code (3% of comments)
- Remove test or commented-out code
- Example: `return "hello"` in a switch case
- Remove unused `import` statements or functions

#### 11. SVG Tags
- Properly close tags in SVG/sprite files

#### 12. URL Parameters
- Be specific with parameters: `pay-card?card=x4953` not just `pay-card`

#### 13. Inconsistent code indentation
- Check for mixed tabs and spaces (follow project's config)
- Detect incorrect indentation levels that pre-commit may have missed

### COMMENT FORMAT (Lead's Style)

- Direct and concise
- Always include code suggestions
- Friendly but direct tone

**If COMMENT_LANGUAGE=en (English):**
- "PR title must include the ticket number and describe the change, e.g. `[TICKET-ID] Add payment confirmation flow`. 'initial commit' is not a valid title for an existing project."
- "Commit messages should reference the ticket: `[TICKET-ID] Description of change`"
- "One less div, same result"
- "Leftover console.log"
- "This file already exists as `filename.ext`"
- "There's a component for this (recently added) `ComponentName`"
- "Remember to add documentation for this component"
- "Repetitive markup — extract into a const array and use `.map()`"

**If COMMENT_LANGUAGE=es (Spanish):**
- "El titulo del PR debe incluir el numero del ticket y describir el cambio, ej. `[TICKET-ID] Agregar flujo de confirmacion de pago`. 'initial commit' no es un titulo valido para un proyecto existente."
- "Los commits deben referenciar el ticket: `[TICKET-ID] Descripcion del cambio`"
- "Un div menos y el mismo resultado"
- "Se fue un console.log"
- "Este archivo ya existe como `filename.ext`"
- "Para esto hay un componente (es reciente) `ComponentName`"
- "Recuerda crear documentacion para este componente"
- "Markup repetitivo — extraer a un array const y usar `.map()`"

## Review Instructions

1. Check each changed file against applicable rules
2. For EACH violation found, leave an inline comment on the **EXACT line** where the problem occurs
3. Use `gh pr diff $PR_NUMBER` to identify the exact line numbers in the modified files
4. Be concise and direct - just like a team lead would comment
5. Prefer `` ```suggestion `` blocks for single-line fixes (enables one-click fix in GitHub)

## Submitting the Review

### Step 0: Get Repository Information

First, get the repository owner and name:
```bash
REPO_OWNER=$(gh repo view --json owner --jq '.owner.login')
REPO_NAME=$(gh repo view --json name --jq '.name')
```

### Step 1: Get the Latest Commit SHA and Review the Diff

Get the commit ID from the PR:
```bash
COMMIT_SHA=$(gh pr view $PR_NUMBER --json commits --jq '.commits[-1].oid')
```

Review the diff to identify exact line numbers:
```bash
gh pr diff $PR_NUMBER
```

**Finding the Exact Line Number:**
When you see the diff output, look for the line numbers on the right side (after the `+` sign):
```diff
@@ -40,5 +40,8 @@ export default function MyComponent() {
   return (
     <div className="container">
-      <p>Old content</p>
+      <div className="px-4 py-2">        <- This is line 42
+        <button>Click</button>           <- This is line 43
+      </div>                             <- This is line 44
     </div>
   )
 }
```

If the problem is the unnecessary `<div>` wrapper, comment on **line 42** (where the problematic div starts), NOT line 40 (where the function starts).

### Step 2: For Each Violation Found

**Single-line comment** on the **EXACT LINE** where the problem occurs:
```bash
gh api repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER/comments \
  -f body="COMMENT_TEXT" \
  -f commit_id="$COMMIT_SHA" \
  -f path="FILE_PATH" \
  -F line=EXACT_LINE_NUMBER \
  -f side="RIGHT"
```

**Multi-line comment** spanning multiple lines (like selecting in GitHub UI):
```bash
gh api repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER/comments \
  -f body="COMMENT_TEXT" \
  -f commit_id="$COMMIT_SHA" \
  -f path="FILE_PATH" \
  -F start_line=START_LINE_NUMBER \
  -F line=END_LINE_NUMBER \
  -f side="RIGHT"
```

**IMPORTANT:** `line` must be the **exact line number** where the issue is in the file, NOT where the code block starts. For multi-line comments, `start_line` is the first line and `line` is the last line of the problematic code block.

**Comment Format for Each Violation:**

Use GitHub's suggestion syntax to allow one-click fixes:

```
[Concise title of the problem]

` ``suggestion
[Only the correct code that replaces the problematic line]
` ``

[Optionally, include a more complete example if needed]
```

**Alternative format** (when suggestion syntax doesn't fit):
```
[Concise title of the problem]

[Suggested code in ```jsx block with before/after example]

[Brief explanation if needed]
```

**Complete Examples:**
```bash
# Get repo info and commit SHA
REPO_OWNER=$(gh repo view --json owner --jq '.owner.login')
REPO_NAME=$(gh repo view --json name --jq '.name')
COMMIT_SHA=$(gh pr view 399 --json commits --jq '.commits[-1].oid')

# Example 1: Single-line comment with GitHub suggestion syntax (allows one-click fix)
# If the problem is at line 42 where there's: <div className="px-4 py-2">
gh api repos/$REPO_OWNER/$REPO_NAME/pulls/399/comments \
  -f body="One less div, same result

\`\`\`suggestion
<button className=\"px-4 py-2\">Click</button>
\`\`\`

The wrapper div is unnecessary here." \
  -f commit_id="$COMMIT_SHA" \
  -f path="src/components/MyComponent.js" \
  -F line=42 \
  -f side="RIGHT"

# Example 2: Multi-line comment covering lines 42-44
# When the problematic code spans multiple lines (like a full div block)
gh api repos/$REPO_OWNER/$REPO_NAME/pulls/399/comments \
  -f body="One less div, same result

\`\`\`suggestion
<button className=\"px-4 py-2\">Click</button>
\`\`\`" \
  -f commit_id="$COMMIT_SHA" \
  -f path="src/components/MyComponent.js" \
  -F start_line=42 \
  -F line=44 \
  -f side="RIGHT"

# Example 3: Traditional format with before/after (when multi-line changes needed)
gh api repos/$REPO_OWNER/$REPO_NAME/pulls/399/comments \
  -f body="One less div, same result

\`\`\`jsx
// Bad
<div className=\"px-4 py-2\">
  <button>Click</button>
</div>

// Good
<button className=\"px-4 py-2\">Click</button>
\`\`\`" \
  -f commit_id="$COMMIT_SHA" \
  -f path="src/components/MyComponent.js" \
  -F line=42 \
  -f side="RIGHT"

# You can leave multiple comments by repeating the command with different line numbers and paths
```

**Important Notes:**
- **Single-line comments:** Use only `-F line=EXACT_LINE_NUMBER`
  - `line` should be the **EXACT line number** where the issue is in the file (as shown in the diff)
  - Example: If a problematic `<div>` is on line 42, use `-F line=42`, NOT the line where the block starts
- **Multi-line comments:** Use both `-F start_line=START` and `-F line=END`
  - Covers multiple lines just like selecting in GitHub UI
  - Example: To comment on lines 42-44, use `-F start_line=42 -F line=44`
  - Useful when the problematic code spans several lines (like a full div block)
- `side` should be "RIGHT" for additions/modifications, "LEFT" for deletions
- Each comment is created immediately and independently
- If you have many violations, you can create them all first, then submit a final summary review

**GitHub Suggestion Syntax Benefits:**
- Uses `` ```suggestion `` code blocks in the comment body
- Shows up as a clickable "Apply suggestion" button in GitHub UI
- Allows reviewer to commit the fix with one click
- Best for single-line or small changes
- Works with both single-line and multi-line comments
- For complex multi-line changes, consider using traditional before/after format instead

### Step 3: After All Inline Comments

Leave a summary review comment based on `COMMENT_LANGUAGE`:

**If COMMENT_LANGUAGE=en:**
```bash
gh pr review $PR_NUMBER --request-changes --body "Review completed: [X] comments left in the code

**Summary:**
- [Brief list of issue categories found]

**Positive observations:**
- [List of things done well]

_Lead review bot_"
```

**If COMMENT_LANGUAGE=es:**
```bash
gh pr review $PR_NUMBER --request-changes --body "Revision completada: [X] comentarios dejados en el codigo

**Resumen:**
- [Breve lista de categorias de issues encontrados]

**Observaciones positivas:**
- [Lista de cosas bien hechas]

_Lead review bot_"
```

### If No Violations:

**If COMMENT_LANGUAGE=en:**
```bash
gh pr review $PR_NUMBER --approve --body "Everything looks good! Clean code following project standards

_Lead review bot_"
```

**If COMMENT_LANGUAGE=es:**
```bash
gh pr review $PR_NUMBER --approve --body "Todo se ve bien! Codigo limpio y siguiendo los estandares del proyecto

_Lead review bot_"
```
