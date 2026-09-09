---
name: ask-fable
description: Ask Fable for a second opinion on the current task, with full conversation context carried over. Use when the user wants a different model's take on an approach, a decision, or something the current session got stuck on.
---

Invoke via the Agent tool with `subagent_type: "fork"` and `model: "fable"`.

Forking carries the full conversation history into the consulted model automatically — do not write a manual summary of context.

Prompt template for the fork:

```
Second opinion requested. Question: {user's question}

Answer directly, plain text, no preamble. If you disagree with an approach
already taken in this conversation, say so and why.
```

After the fork returns, report its answer back to the user attributed as "Fable says:" (trim only if very long). Do not act on the opinion automatically — the user decides what to do with it.

If the current session is already running on Fable, tell the user this call would be redundant (same model consulting itself) before running it.
