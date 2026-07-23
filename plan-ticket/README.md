## plan-ticket

Read a Jira ticket and generate a structured implementation plan. Detects the project stack (Rails, Next.js, PHP Yii2, WordPress, or Shopify) and applies stack-specific exploration and plan sections. This skill only creates a plan file — it does not implement anything.

## Requirements

### Jira CLI (`jira`)

Used to fetch ticket details (description, comments, attachments).

Install: https://github.com/ankitpokhrel/jira-cli

```bash
brew tap ankitpokhrel/jira-cli
brew install jira-cli
jira init
```

The skill uses:
- `jira issue view <TICKET_ID> --plain` — fetch ticket details
- `jira issue view <TICKET_ID> --comments 10 --plain` — fetch comments for extra context
- `jira issue view <TICKET_ID> --raw` — fetch attachment metadata

## Usage

```
/plan-ticket <TICKET_ID>
```

| Argument | Required | Description |
|----------|----------|--------------|
| `TICKET_ID` | Yes | Jira ticket key (e.g. `MPP-650`). Must include the project prefix. |

## What it does

1. **Reads the Jira ticket** — summary, description, acceptance criteria, labels, linked issues, and image attachments.
2. **Detects the project stack** by checking for `Gemfile`, `package.json`, `composer.json`, theme files, etc.
3. **Explores the codebase** — launches parallel Explore agents based on the stack-specific rules file.
4. **Generates a plan** at `.docs/plans/<ticket-id-lowercase>/plan.md` covering files to modify/create, reusable code, stack-specific sections, implementation steps, and verification.
5. **Asks the user** about any ambiguities found during exploration before finalizing.

## Supported stacks

Stack rules live under `stacks/`:

- `stacks/rails.md`
- `stacks/nextjs.md`
- `stacks/php-yii2.md`
- `stacks/wordpress.md`
- `stacks/shopify.md`

If the stack can't be detected, the skill asks which one to use.
