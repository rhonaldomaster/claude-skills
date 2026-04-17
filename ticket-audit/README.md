# Ticket Audit Plugin

A Claude Code plugin for auditing Jira ticket implementation against your codebase. It fetches ticket details, audits existing code, identifies gaps, checks ticket quality, and optionally integrates with [Tambora](https://github.com/koombea/tambora) for QA test case management.

## Compatibility

- **Format**: claude-plugin
- **Works with**: claude-code
- **Scope**: Development, QA
- **Author**: Rhonalf Martinez

## Skills

| Skill | Invocation | Description |
|-------|-----------|-------------|
| review-ticket-frontend-nextjs | `/ticket-audit:review-ticket-frontend-nextjs <ticket-id> [suite?] [--qa?]` | Audit a Jira ticket against a Next.js/React frontend codebase |
| review-ticket-backend-rails | `/ticket-audit:review-ticket-backend-rails <ticket-id> [suite?] [--qa?]` | Audit a Jira ticket against a Rails backend codebase |

Both skills support two modes:

- **Normal mode** (default) — full implementation audit for developers
- **QA mode** (`--qa`) — testability check + Tambora test run recording for QA engineers

## Requirements

- **Jira CLI** — [`ankitpokhrel/jira-cli`](https://github.com/ankitpokhrel/jira-cli) must be installed and authenticated (`jira issue view` must work)
- **Tambora MCP** (optional) — required only if a Tambora suite name is provided

## Installation

**Org install** (shared across the team):

```bash
# Clone the workflows repo if not already cloned
git clone git@github.com:koombea/koombea-ai-workflows.git ~/koombea-ai-workflows

# Load the plugin when starting Claude Code
claude --plugin-dir ~/koombea-ai-workflows/plugins/ticket-audit
```

**Local install** (your machine only):

```bash
claude plugin install ~/koombea-ai-workflows/plugins/ticket-audit
```

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

# Backend audit + Tambora coverage
/ticket-audit:review-ticket-backend-rails MPP-221 "MPP-150 Memories list view"

# Backend QA mode
/ticket-audit:review-ticket-backend-rails MPP-221 "MPP-150 Memories list view" --qa
```

## Normal mode output

- **Summary** — what the ticket asks for
- **Status** — current Jira status and subtasks
- **Readiness check** — quick Yes/No/Partial per acceptance criterion
- **Implementation audit** — what exists with file paths and line numbers
- **Gap analysis** — what's missing
- **Ticket quality issues** — ambiguities, missing edge cases, open decisions
- **Recommendations** — actionable next steps
- **Tambora coverage** — test case coverage status (if suite provided)

## QA mode output

- **Summary** — what the ticket asks for
- **Status** — current Jira status
- **Readiness check** — Yes/No/Partial per acceptance criterion
- **Tambora test cases** — testability status per case
- **Test run recording** — interactive walk-through to record pass/fail/skip/broken per case

---

[All Plugins](../README.md)
