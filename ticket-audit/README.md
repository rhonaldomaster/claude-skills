# ticket-audit

A Claude Code plugin for auditing Jira ticket implementation against your codebase. It fetches ticket details, audits existing code, identifies gaps, checks ticket quality, and optionally integrates with [Tambora](https://github.com/koombea/tambora) for QA test case management.

## Skills included

| Skill | Description |
|-------|-------------|
| `review-ticket-frontend-nextjs` | Audits a Jira ticket against a Next.js/React frontend codebase |
| `review-ticket-backend-rails` | Audits a Jira ticket against a Rails backend codebase |

Both skills support two modes:

- **Normal mode** (default) — full implementation audit for developers
- **QA mode** (`--qa`) — testability check + Tambora test run recording for QA engineers

## Usage

```bash
# Frontend audit
/ticket-audit:review-ticket-frontend-nextjs MPP-221

# Frontend audit + Tambora coverage
/ticket-audit:review-ticket-frontend-nextjs MPP-221 "MPP-150 Memories list view"

# Frontend QA mode
/ticket-audit:review-ticket-frontend-nextjs MPP-221 "MPP-150 Memories list view" --qa

# Backend audit
/ticket-audit:review-ticket-backend-rails MPP-221
```

## Requirements

- **Jira CLI** — `jira` must be installed and authenticated
- **Tambora MCP** (optional) — required only if a Tambora suite name is provided

## License

MIT
