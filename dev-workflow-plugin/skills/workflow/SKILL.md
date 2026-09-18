---
name: workflow
description: Full ticket-to-PR development workflow reference. Detects the project's stack and rules, then guides plan -> implement -> test -> commit/PR -> review with explicit approval checkpoints. Use when the user asks about the dev process, wants to work a ticket end-to-end, or asks "what's the workflow here".
---

# Dev Workflow

Stack-agnostic ticket-to-PR workflow. This skill is **human-in-the-loop by design**: stop at
every checkpoint (✋) and wait for explicit approval before continuing. Never skip a checkpoint.

This is the `dev-workflow` plugin's orchestrator skill. It bundles and calls the other skills in
this same plugin (`plan-ticket`, `pr-cycle-<stack>`, `generate-agent-rules`,
`frontend-quality-rules`) plus `answer-to-copilot:respond` if that separate plugin happens to be
installed too. This skill does not review code itself and does not generate project rules on its
own — it orchestrates.

```
[1. PLAN]        /dev-workflow:plan-ticket <ID>   -> plan file
                 ✋ CP-1: plan approved
[2. IMPLEMENT]   code -> manual QA
                 ✋ CP-2: QA approved (loop on fixes: CP-2b)
[3. TEST]        unit/e2e if the project has them
                 ✋ CP-3: test results resolved
[4. COMMIT+PR]   ✋ CP-4: commit message approved
                 ✋ CP-5: PR description approved
[5. POST-PR]     Copilot triage (if available) -> CI
                 ✋ CP-6: CI / Copilot results resolved
[6. REVIEW]      /dev-workflow:pr-cycle-<stack> or manual review -> merge
                 ✋ CP-7: review feedback resolved
```

## Step 0: Detect Stack & Load Rules

Detect the project stack by checking files in the current working directory (same table used
by `/dev-workflow:plan-ticket`):

| Check (in priority order)                                                            | Stack     | pr-cycle skill in this plugin      |
| -------------------------------------------------------------------------------------| --------- | ------------------------------------ |
| `Gemfile` exists AND contains `rails`                                                | Rails     | `/dev-workflow:pr-cycle-backend-rails`     |
| `package.json` exists AND contains `next`                                           | Next.js   | `/dev-workflow:pr-cycle-frontend-nextjs`   |
| `composer.json` exists AND contains `yiisoft/yii2`                                  | PHP Yii2  | `/dev-workflow:pr-cycle-backend-yii2`      |
| `style.css` with `Theme Name:` header OR `functions.php` with WordPress hooks       | WordPress | `/dev-workflow:pr-cycle-backend-wordpress` |
| `config/settings_schema.json` OR `templates/*.json` + `sections/*.liquid`           | Shopify   | `/dev-workflow:pr-cycle-frontend-shopify`  |

If the stack cannot be detected, ask the user which stack applies before proceeding.

**Load project rules, in this order, and follow whichever exist:**

1. `CLAUDE.md` / `AGENTS.md` / `.cursorrules` / `.windsurfrules` at the project root — project
   conventions always take precedence over generic defaults. If the project has none of these
   yet, offer `/dev-workflow:generate-agent-rules` to set one up from this plugin's `pr-cycle`
   rules.
2. If the detected stack is a frontend JS stack (Next.js, or any React/JSX codebase), also apply
   the `/dev-workflow:frontend-quality-rules` skill's rules when writing or reviewing code.
3. Any stack-specific doc the project itself points to (e.g. `docs/conventions/`).

If none of these exist, say so explicitly rather than assuming conventions.

**Skills bundled in this plugin (all invoked with the `dev-workflow:` prefix):**

| Skill | Phase | Note |
|-------|-------|------|
| `/dev-workflow:plan-ticket <ID>` | 1 — Plan | Generates `.docs/plans/<ticket-id>/plan.md` |
| `/dev-workflow:frontend-quality-rules` | 2, 6 | Applied automatically for frontend JS stacks |
| `/dev-workflow:pr-cycle-<stack> <PR> [TICKET] [suite]` | 6 — Review | Full PR review + Jira AC coverage |
| `/dev-workflow:generate-agent-rules` | Setup | Not part of the phase flow; run standalone to set up `CLAUDE.md`/`AGENTS.md` |
| `/answer-to-copilot:respond <PR>` | 5 — Post-PR | External plugin, not bundled here — only if separately installed |

All of the above except `answer-to-copilot:respond` ship inside this plugin, so they're always
available once `dev-workflow` is installed. If one is missing anyway, do the equivalent step
manually and say so.

---

# Phase 1 — Plan

Run `/dev-workflow:plan-ticket <TICKET_ID>`. It reads the Jira ticket, explores the codebase,
and writes `.docs/plans/<ticket-id-lowercase>/plan.md`.

## ✋ CP-1 — Plan approval

Present:
1. Summary of what will be built (2-4 bullets)
2. Files that will change
3. Open questions / ambiguities found

Ask: "Do you want to proceed, or should we adjust anything first?"

Do not write implementation code until the plan is approved and open questions are answered.

---

# Phase 2 — Implement

Only start after CP-1 is approved.

## Find the dev/test commands

Do not assume ports or scripts. Detect them, in order:
1. `package.json` `scripts` block (`dev`, `start`, `test`, `lint`)
2. `Makefile` targets
3. `CLAUDE.md` / `AGENTS.md` / `README.md` — often documents the exact run command and port
4. If none of the above give a clear answer, ask the user for the dev/test commands before
   starting manual QA.

## Mid-implementation checkpoints (multi-part tickets)

For tickets spanning more than one screen/endpoint/component, build one piece at a time. After
each major piece, stop and present:
- What was just built (screenshot if it's UI, diff summary otherwise)
- What's next
- Ask: "Does this look right? Should I continue to [next piece]?"

## ✋ CP-2 — QA approval

After the full implementation is complete, do a self-QA pass before presenting to the developer:
1. Exercise every changed path (UI: navigate and screenshot each state; API: hit each endpoint)
2. Compare against the ticket's acceptance criteria and any design reference provided
3. Self-identify gaps or issues

Present:
- Evidence of what was verified (screenshots, command output)
- Any gaps or known issues found during self-QA
- Ask: "Does this look correct? Is anything missing or wrong?"

## ✋ CP-2b — Fix re-approval (loop)

If the developer reports issues: fix, re-verify, present before/after, ask again. Repeat until
explicitly approved — a fix for one issue does not imply approval of the whole set.

---

# Phase 3 — Test

Only start after CP-2 / CP-2b is fully approved.

## ✋ CP-3 — Test results

Ask if automated tests are wanted (skip if the project has no test setup, or if the ticket is
trivial and the user says so). If yes, run the project's existing test command(s) and present:

**All pass:** "X/X tests passed. Ready to commit?"

**Some fail:** for each failure, present which test failed, why (error + line), and whether it
looks like a flaky test, a real bug, or a test logic issue. Ask: "Fix, skip, or do you want to
review first?"

Do not commit until the test outcome is resolved.

---

# Phase 4 — Commit and PR

Only start after CP-3 is resolved (or testing was skipped).

Follow the git rules already defined in the global config (branch prefixes `feat/`, `fix/`,
`docs/`, `chore/`; confirm current branch and identity before committing; never commit to
main/master unless explicitly instructed).

## ✋ CP-4 — Commit message approval

Present staged files and the proposed commit message. Ask: "Does this commit message look
good?" Wait for approval before running `git commit`.

## ✋ CP-5 — PR description approval

Present the proposed PR title and body (summary + test plan). Ask: "Does this PR description
look good?" Confirm the target branch before creating the PR.

---

# Phase 5 — Post-PR

## Copilot review (if the plugin is available)

If `answer-to-copilot:respond` is installed in this setup, run it on the PR once it's open. If
it isn't installed, skip this — do not attempt to replicate it manually unless asked.

## CI

If the project has CI, trigger/wait for it using whatever mechanism the project documents
(`gh workflow run`, a status check, etc.).

## ✋ CP-6 — CI / Copilot results

Present results. If everything passed: "CI passed, Copilot threads resolved. Ready for review."
If something failed: present what failed and why, then ask whether to fix and re-trigger, treat
it as known-flaky, or wait for the developer to investigate.

---

# Phase 6 — Review & Merge

Run the matching `/dev-workflow:pr-cycle-<stack>` skill from Step 0's table, passing the PR
number and, if known, the Jira ticket ID. It reviews the diff against stack rules and the
ticket's acceptance criteria, leaves inline comments, and can move the ticket to QA on approval.

## ✋ CP-7 — Review feedback

If the review (bot or human) leaves comments: evaluate each against the live code — do not apply
suggestions blindly — implement valid fixes, note skipped ones with a reason, push, and reply to
each thread. Loop until resolved.

Never merge your own PR or approve your own review. Only merge after explicit approval, per the
global git rules.

## Move the ticket (after approval)

Once the review is resolved with no outstanding comments and a Jira ticket ID is known, ask:
"The PR is approved — should I move `<TICKET_ID>` to QA (or whichever column comes next) and
leave a comment?" Column names vary by project (`QA`, `Ready for QA`, `In QA`, `Deploy to STG`,
etc.) — ask for the exact target if it isn't already clear from the project's board, rather than
guessing one.

If `/dev-workflow:pr-cycle-<stack>` was used for the review, it already offers this move as its
own Step 7 — don't duplicate the prompt, just confirm the outcome. If the review was done
manually, run this step yourself: `jira issue move <TICKET_ID> "<TARGET_STATUS>"`, then draft a
comment with the PR link and show it for confirmation before posting.

---

# Complete Workflow Checklist

```
[ ] PHASE 1 — PLAN
      /dev-workflow:plan-ticket <ID>
      ✋ CP-1: plan + open questions approved

[ ] PHASE 2 — IMPLEMENT
      Detect dev/test commands (package.json / Makefile / CLAUDE.md / ask)
      Multi-part ticket: one piece at a time, checkpoint after each
      Self-QA pass with evidence
      ✋ CP-2: QA approved
      ✋ CP-2b: re-approval loop if issues found

[ ] PHASE 3 — TEST (optional)
      Run existing test command(s)
      ✋ CP-3: results resolved (fix/skip/wait)

[ ] PHASE 4 — COMMIT + PR
      ✋ CP-4: commit message approved
      ✋ CP-5: PR description + target branch approved

[ ] PHASE 5 — POST-PR
      /answer-to-copilot:respond <PR> (if installed)
      Trigger CI if applicable
      ✋ CP-6: CI / Copilot results resolved

[ ] PHASE 6 — REVIEW & MERGE
      /dev-workflow:pr-cycle-<stack> <PR> [TICKET]
      ✋ CP-7: review feedback resolved, loop until clean
      Ask to move the ticket to QA/next column (ask for exact column name) + post comment
      Merge only after explicit approval — never self-approve
```
