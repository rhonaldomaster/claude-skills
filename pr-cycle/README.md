# pr-cycle

A Claude Code plugin for full PR cycle reviews across multiple stacks. Each skill combines code quality review (team lead standards) with Jira ticket acceptance criteria coverage, inline GitHub comments, post-approval ticket move to QA, and optional Tambora test case recording.

## Compatibility

- **Format**: claude-plugin
- **Works with**: claude-code
- **Scope**: Development, QA
- **Author**: Rhonalf Martinez

## Skills

| Skill | Invocation | Stack |
|-------|-----------|-------|
| frontend-nextjs | `/pr-cycle:frontend-nextjs <PR> [TICKET?] [suite?]` | Next.js 16 / React 19 / TypeScript / Tailwind |
| backend-rails | `/pr-cycle:backend-rails <PR> [TICKET?] [suite?]` | Ruby on Rails |
| backend-yii2 | `/pr-cycle:backend-yii2 <PR> [TICKET?] [suite?]` | PHP Yii2 |
| backend-wordpress | `/pr-cycle:backend-wordpress <PR> [TICKET?] [suite?]` | WordPress (themes & plugins) |
| frontend-shopify | `/pr-cycle:frontend-shopify <PR> [TICKET?] [suite?]` | Shopify (Liquid / JSON templates) |

## Requirements

### GitHub CLI (`gh`)

Used for all GitHub operations: reading PR diffs, leaving inline review comments, and submitting the final review decision.

Install: https://cli.github.com/

```bash
brew install gh
gh auth login
```

### Jira CLI (`jira`)

Used to fetch ticket details and optionally move tickets to QA and post comments.

Install: https://github.com/ankitpokhrel/jira-cli

```bash
brew tap ankitpokhrel/jira-cli
brew install jira-cli
jira init
```

> If the Jira CLI is not available, the Atlassian MCP server is used as a fallback for ticket reads only.

## Installation

```bash
ln -s /path/to/claude-skills/pr-cycle ~/.claude/plugins/pr-cycle
```

Or load it when starting Claude Code:

```bash
claude --plugin-dir /path/to/claude-skills/pr-cycle
```

## Usage

```
/pr-cycle:<skill> <PR_NUMBER> [JIRA_TICKET_ID] [tambora-suite-name]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `PR_NUMBER` | Yes | GitHub PR number to review |
| `JIRA_TICKET_ID` | No | Jira ticket ID (e.g. `MPP-221`). Enables AC coverage check and post-approval ticket move. |
| `tambora-suite-name` | No | Tambora test suite name. Enables test case coverage and optional result recording. |

### Examples

```bash
# Code review only
/pr-cycle:frontend-nextjs 42
/pr-cycle:backend-rails 42
/pr-cycle:backend-yii2 42
/pr-cycle:backend-wordpress 42
/pr-cycle:frontend-shopify 42

# Code review + Jira AC coverage
/pr-cycle:backend-rails 42 MPP-221

# Full cycle: code review + AC coverage + Tambora
/pr-cycle:frontend-nextjs 42 MPP-221 "MPP-150 Memories list view"
```

## What each skill does

1. **Reads existing PR comments** — skips issues already flagged by Copilot or other reviewers.
2. **Fetches the Jira ticket** (if provided) — extracts acceptance criteria and subtask statuses.
3. **Reviews the PR diff** — applies stack-specific code quality rules (see below).
4. **Maps the diff to acceptance criteria** — reports which ACs are implemented, partial, or missing.
5. **Leaves inline GitHub comments** — on the exact lines where issues occur, with one-click suggestion blocks.
6. **Posts a summary review** — request-changes or approve, with AC coverage summary.
7. **Offers to move the Jira ticket to QA** — after approval, uses `jira issue move` + `jira issue comment add`.
8. **Tambora test case coverage** — shows coverage status per test case and optionally records run results.

## Stack-specific rules

### frontend-nextjs
- Unnecessary DIVs / wrapper elements
- Forgotten `console.log`
- Duplicate files or components
- Image paths, component documentation, indentation
- Inappropriate elements (`onClick` on divs, router.push instead of `<Link>`)
- Repetitive JSX → `.map()`
- Dead code, SVG tags, inconsistent indentation
- 10+ additional code quality rules (DRY classes, no derived state, condensed conditionals, destructuring, etc.)

### backend-rails
- N+1 queries (missing `.includes`)
- SQL injection via string interpolation
- Missing strong parameters / mass assignment
- Missing database indexes
- Forgotten debug statements (`binding.pry`, `byebug`, `puts`)
- Missing `null: false` constraints
- Callbacks with side effects
- Logic in views / fat controllers
- `deliver_now` in mailers
- Non-idempotent background jobs
- Missing `dependent:` on associations
- Repetitive ERB markup
- Instance variables in partials
- ERB-specific frontend rules

### backend-yii2
- SQL injection (parameterized queries / ActiveRecord)
- XSS via unescaped output (`Html::encode()`)
- Missing input validation (`rules()`, `load()`, `validate()`)
- Missing CSRF protection
- N+1 queries (missing `with()`)
- Missing database indexes (`createIndex()`)
- Missing `->notNull()` in migrations
- Missing access control (RBAC, `current_user_can`)
- Queue jobs passing full AR objects
- Logic in views / fat controllers
- Soft delete guard (missing default scope)

### backend-wordpress
- SQL injection via `$wpdb` (missing `$wpdb->prepare()`)
- XSS via unescaped output (`esc_html()`, `esc_url()`, `wp_kses_post()`)
- Missing input sanitization (`sanitize_text_field()`, `wp_unslash()`)
- Missing nonce verification (`check_ajax_referer()`, `wp_verify_nonce()`)
- Hardcoded `<script>`/`<link>` tags (must use `wp_enqueue_*`)
- Missing capability checks (`current_user_can()`)
- REST API endpoints with `__return_true` permission callback
- Not translation ready (missing `__()`, `_e()`)
- Logic in templates
- Direct `$wpdb` queries instead of WP APIs

### frontend-shopify
- Raw output without escaping (`| raw`)
- Hardcoded strings (missing `{{ 'key' | t }}`)
- Images without `image_url` filter and `srcset`
- Missing `loading="lazy"` on below-the-fold images
- Invalid or missing section schema
- Forgotten debug output
- Unnecessary DOM wrappers
- Repetitive Liquid markup (missing `{% render %}`)
- Missing accessibility attributes
- Missing responsive behavior
- Theme settings without `default` values
- Scripts without `defer`/`async`
- Deprecated Liquid filters (`| img_url`)
- Missing `presets` in new sections

## Inline comment approach

All skills post comments using the GitHub API with file line numbers (right side of the diff):

```bash
gh api repos/OWNER/REPO/pulls/PR/comments \
  -f body="Comment text

\`\`\`suggestion
corrected code here
\`\`\`" \
  -f commit_id="COMMIT_SHA" \
  -f path="path/to/file" \
  -F line=42 \
  -f side="RIGHT"
```

Multi-line comments use `-F start_line=START -F line=END`.

## Language

Set `COMMENT_LANGUAGE=es` in your session for Spanish review comments. Default is English (`en`).
