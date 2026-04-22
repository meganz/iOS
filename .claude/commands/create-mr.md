---
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git log:*), Bash(git diff:*), Bash(git push:*), Read
description: Create a GitLab Merge Request for the current branch with auto-generated description
---

# Create MR

Push the current branch to GitLab and create a Merge Request with an auto-generated description.

## Usage

```
/create-mr                           # Auto-generate title and description
/create-mr --title "IOS-1234: My fix"  # Override MR title (must follow ticket convention)
/create-mr --draft                   # Create as draft MR
/create-mr --no-squash               # Disable squash on merge (squash is default)
/create-mr --target main             # Target a different branch (default: develop)
```

## Arguments

| Argument            | Description                                                   |
|---------------------|---------------------------------------------------------------|
| `--title <title>`   | Override MR title (format: `IOS-XXXX: ...` or `CC-XXXX: ...`) |
| `--draft`           | Create MR as draft                                            |
| `--no-squash`       | Disable squash on merge (squash is enabled by default)        |
| `--target <branch>` | Target branch (default: `develop`)                            |

**Target**: $ARGUMENTS

---

## Steps

### Step 1 — Check working tree

Run:
```bash
git status --porcelain
```

If there are uncommitted changes, **warn** the user (list the changed files) but continue — the user may have changes they don't intend to include in this MR.

### Step 2 — Determine target branch

Use `develop` as the target branch by default. If `--target <branch>` was passed, use that instead.

### Step 3 — Gather branch info

Run:
```bash
git branch --show-current
git log <target>..HEAD --oneline
```

- Current branch = push target
- **First** commit message of the branch (oldest in the list) = default MR title (if `--title` was not provided)
  - The first commit typically contains the Jira ticket number (e.g. `IOS-1234: Add feature`)

If `--title` was provided, validate it follows the convention: must start with `IOS-\d+:` or `CC-\d+:`. Warn if it doesn't.

### Step 4 — Generate MR description

Read the MR template:
```
.gitlab/merge_request_templates/merge_request_template.md
```

Run:
```bash
git log <target>..HEAD --oneline && git diff <target>...HEAD
```

Analyze the commits and diff, then fill in the template sections:
- **What does this implement/fix?** — 1-3 sentence overview based on commits and diff
- **Before/After screenshots** — leave placeholder images, the user will fill these in
- **Relevant logs** — include any TODOs found in added lines (`// TODO`, `// FIXME`, `HACK`), or write "N/A"
- **Other comments** — note any risks, trade-offs, or things reviewers should pay attention to, or write "N/A"
- **Where has this been tested?** — leave for user to fill in

Skip test-only files (`*Tests.swift`, `*Test.swift`, `*Spec.swift`) when summarizing key changes.

Writing guidelines:
- Present tense ("Add", "Fix", "Refactor")
- Be concise — reviewers skim
- Be honest about risks

### Step 5 — Push and create MR

Build the push command with GitLab push options.

**Important:** GitLab push options do not support literal newlines — use `\n` (backslash-n) in the description string.

```bash
DESCRIPTION='<single-line description with \n for newlines>'
git push --set-upstream origin "<current branch>" \
  -o merge_request.create \
  -o "merge_request.title=<title>" \
  -o "merge_request.description=${DESCRIPTION}" \
  -o "merge_request.target_branch=<target>"
```

Rules for `DESCRIPTION`:
- Write the entire value on **one line** inside single quotes
- Replace every newline with the two-character sequence `\n`
- Escape any single quotes in the text as `'"'"'`

If `--draft` was passed, append `-o merge_request.draft`.

Squash behavior:
- Default: append `-o merge_request.squash`
- If `--no-squash` was passed: do not append squash option

### Step 6 — Confirm

If the push succeeds:
- Display the generated MR description
- Extract and display the MR URL from the `git push` output

If the push fails:
- Print the generated description so the user can create the MR manually via GitLab UI
- Show the error for debugging
