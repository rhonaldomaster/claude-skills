---
name: ask-fable
description: Ask Fable for a second opinion on the current task. Use when the user wants a different model's take on an approach, a decision, or something the current session got stuck on.
---

Invoke via the Agent tool with `model: "fable"` and without `subagent_type: "fork"`, because a fork always runs on the session's own model. A non-fork agent does not see this conversation, so the prompt must carry the context.

Prompt template:

```
Second opinion requested.
Context: {the task, what was tried, constraints}
Question: {user's question}

Answer directly, plain text, no preamble. If you disagree with an approach
already taken in this conversation, say so and why.
```

After the agent returns, report its answer back to the user attributed as "Fable says:" (trim only if very long). Do not act on the opinion automatically — the user decides what to do with it.

If the current session is already running on Fable, tell the user this call would be redundant (same model consulting itself) before running it.
