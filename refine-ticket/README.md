## refine-ticket

Analyze a Jira ticket and produce an improved version with clear motivation, scope, and acceptance criteria. This skill drafts improvements and asks for confirmation before updating Jira. Uses project code as context to:
- Understand which modules or layers the ticket touches
- Infer technical implications the ticket author may have left implicit
- Tailor acceptance criteria to match project conventions (e.g., migration commands, test commands, config file locations)

## Requirements

### Jira CLI (`jira`)

Used to fetch ticket details (acceptance criteria, subtasks) and optionally move tickets to a QA status column and post comments.

Install: https://github.com/ankitpokhrel/jira-cli

```bash
brew tap ankitpokhrel/jira-cli
brew install jira-cli
jira init
```

The skill uses:
- `jira issue view <TICKET_ID> --plain` — fetch ticket details
- `jira issue move <TICKET_ID> <STATUS>` — move ticket to QA column
- `jira issue comment add <TICKET_ID>` — post a comment on the ticket

> If the Jira CLI is not available or not authenticated, the Atlassian MCP server is used as a fallback for ticket reads only.

## Usage

```
/refine-ticket [JIRA_TICKET_ID]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `JIRA_TICKET_ID` | Yes | Jira ticket key (e.g., 'PST-154'). Must include the project prefix. |