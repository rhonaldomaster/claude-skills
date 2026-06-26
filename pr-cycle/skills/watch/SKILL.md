---
name: watch
description: |
  Watch a specific PR for new commits and trigger a pr-cycle review automatically.
  Designed to be used with /loop for polling during a session.

  Invoke with a PR number (required), optional stack, and optional Jira ticket ID.
  Examples:
  - `watch 42`
  - `watch 42 backend-yii2`
  - `watch 42 backend-yii2 MPP-221`

user-invocable: true
argument-hint: '<PR_NUMBER> [STACK?] [JIRA_TICKET_ID?]'
allowed-tools: Bash, Read
model: haiku
effort: low
---

# PR Cycle Watch

Parse `$ARGUMENTS` as follows:
- **First token** = PR number (required, e.g. `42`)
- **Second token** (optional) = stack name. Valid values: `backend-yii2`, `backend-rails`, `backend-wordpress`, `frontend-nextjs`, `frontend-shopify`. Detected by matching one of these exact strings.
- **Third token** (optional) = Jira ticket ID in `PROJECT-NNN` format (e.g. `MPP-221`). Detected by matching the pattern `[A-Z]+-[0-9]+`.

If no stack is provided, default to `backend-yii2`.

---

## Step 1: Collect PR metadata

```bash
REPO_OWNER=$(gh repo view --json owner --jq '.owner.login')
REPO_NAME=$(gh repo view --json name --jq '.name')
PR_STATE=$(gh pr view $PR_NUMBER --json state --jq '.state')
CURRENT_SHA=$(gh pr view $PR_NUMBER --json commits --jq '.commits[-1].oid')
```

If `PR_STATE` is `MERGED` or `CLOSED`:
- Remove the state entry from the state file (see Step 2) if it exists.
- Report: "PR #$PR_NUMBER is $PR_STATE. Stopping watch." and exit.

---

## Step 2: Check state file

State file path: `~/.claude/pr-watcher-state.json`

State key format: `{owner}/{repo}#{pr}` — e.g. `koombea/myapp#42`

Load the file if it exists, otherwise treat state as `{}`.

```bash
STATE_FILE="$HOME/.claude/pr-watcher-state.json"
STATE_KEY="$REPO_OWNER/$REPO_NAME#$PR_NUMBER"

if [[ -f "$STATE_FILE" ]]; then
  LAST_SHA=$(jq -r --arg key "$STATE_KEY" '.[$key] // ""' "$STATE_FILE")
else
  LAST_SHA=""
fi
```

---

## Step 3: First-run baseline

If `LAST_SHA` is empty (first time watching this PR):
- Save `CURRENT_SHA` to the state file:

```bash
jq --arg key "$STATE_KEY" --arg sha "$CURRENT_SHA" \
  '.[$key] = $sha' "$STATE_FILE" 2>/dev/null || \
  echo "{\"$STATE_KEY\": \"$CURRENT_SHA\"}" > "$STATE_FILE"
```

- Report: "Watching PR #$PR_NUMBER ($REPO_OWNER/$REPO_NAME). Baseline set at SHA ${CURRENT_SHA:0:8}. No review triggered — waiting for new commits."
- Exit (no review on first run).

---

## Step 4: Compare SHAs

If `LAST_SHA == CURRENT_SHA`:
- Report: "PR #$PR_NUMBER — no new commits since last review (SHA ${CURRENT_SHA:0:8})."
- Exit.

If `LAST_SHA != CURRENT_SHA`:
- Report: "PR #$PR_NUMBER — new commits detected (${LAST_SHA:0:8} → ${CURRENT_SHA:0:8}). Triggering review..."
- Run:
```bash
osascript -e "display notification \"New commits on PR #$PR_NUMBER — triggering review...\" with title \"PR Watcher\" sound name \"Glass\""
```

---

## Step 5: Trigger review

Invoke the matching pr-cycle skill using the Skill tool:

- `backend-yii2` → invoke `pr-cycle:backend-yii2` with args `"$PR_NUMBER $TICKET_ID"`
- `backend-rails` → invoke `pr-cycle:backend-rails` with args `"$PR_NUMBER $TICKET_ID"`
- `backend-wordpress` → invoke `pr-cycle:backend-wordpress` with args `"$PR_NUMBER $TICKET_ID"`
- `frontend-nextjs` → invoke `pr-cycle:frontend-nextjs` with args `"$PR_NUMBER $TICKET_ID"`
- `frontend-shopify` → invoke `pr-cycle:frontend-shopify` with args `"$PR_NUMBER $TICKET_ID"`

If no `TICKET_ID` was provided, pass only the PR number as args.

---

## Step 6: Update state

After the review skill completes, update the state file with the new SHA:

```bash
UPDATED=$(jq --arg key "$STATE_KEY" --arg sha "$CURRENT_SHA" \
  '.[$key] = $sha' "$STATE_FILE")
echo "$UPDATED" > "$STATE_FILE"
```

- Run:
```bash
osascript -e "display notification \"Review complete for PR #$PR_NUMBER (${CURRENT_SHA:0:8})\" with title \"PR Watcher\" sound name \"Glass\""
```
- Report: "Review complete for PR #$PR_NUMBER. State updated to SHA ${CURRENT_SHA:0:8}."
