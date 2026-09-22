# dev-workflow Plugin

Standalone, all-in-one ticket-to-PR development workflow. One install gives you the full
`plan → implement → test → commit/PR → review` cycle with approval checkpoints, plus every
skill it orchestrates, bundled in a single plugin — no separate installs required.

Built for day-to-day ticket work: you already have a Jira ticket, you want a quick plan and a
reviewed PR. It does not write specs or design docs.

## How it flows

```mermaid
%%{init: {"theme": "base", "themeVariables": {"background": "#FAFAFA", "primaryColor": "#DDE8E6", "primaryTextColor": "#1A1A2E", "primaryBorderColor": "#5A9A90", "lineColor": "#5A9A90", "secondaryColor": "#EEF4F3", "clusterBkg": "#EEF4F3", "clusterBorder": "#8ABDB6", "titleColor": "#1A1A2E", "edgeLabelBackground": "#FAFAFA", "fontFamily": "Arial, Helvetica, sans-serif"}}}%%
flowchart TD
    plan["Plan<br/>plan-ticket"] --> implement["Implement"] --> test["Test"] --> pr["Commit / PR"] --> review["Review<br/>pr-cycle"]
```

`workflow` is the orchestrator that walks these phases with approval checkpoints; each phase
can also be run standalone via its own skill.

## Compatibility

| Field | Value |
|-------|-------|
| **Format** | `claude-plugin` |
| **Works with** | `claude-code` |
| **Scope** | Development |
| **Author** | Rhonalf Martinez |

## Skills

| Skill | Description |
|-------|--------------|
| `/dev-workflow:workflow` | The orchestrator — detects stack, loads project rules, walks phases 1-6 with checkpoints |
| `/dev-workflow:plan-ticket <ID>` | Reads a Jira ticket, explores the codebase, writes an implementation plan |
| `/dev-workflow:pr-cycle <PR> [TICKET] [suite]` | Full PR review — detects the stack automatically (Rails, Next.js, PHP Yii2, WordPress, Shopify) |
| `/dev-workflow:frontend-quality-rules` | React/JSX + CSS code quality rules, applied automatically for frontend JS stacks |
| `/dev-workflow:generate-agent-rules` | Turns this plugin's `pr-cycle` rules into `docs/agent-rules/<stack>.md` + a pointer in `CLAUDE.md`/`AGENTS.md` |


## What's not here

- **Spec or design docs.** No upfront spec, validation plan, or acceptance-criteria authoring — the ticket is the input.
- **Parallel multi-agent build.** Implementation is a single conversation, not dispatched sub-agent workers across worktrees.
- **Memory tooling.** Stack-agnostic and memory-agnostic; pairs with whatever memory system is installed, if any.

## Requirements

- `gh` CLI for GitHub operations
- `jira` CLI, or the Atlassian MCP server as a fallback, for Jira operations

## Installation

```bash
ln -s /path/to/claude-skills/pr-cycle ~/.claude/plugins/pr-cycle
```

Or load it when starting Claude Code:

```bash
claude --plugin-dir /path/to/claude-skills/pr-cycle
```

---

[All Plugins](../README.md)
