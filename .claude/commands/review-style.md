---
allowed-tools: Bash(git diff:*)
description: Code style review against Swift Style Guide and SwiftUI Programming Guide with confidence scoring
---

Review the **code style** of the provided MEGA iOS code. Uses a reviewer agent and a scoring agent to filter false positives.

**Target**: $ARGUMENTS

---

## Step 1 — Get the code

- File path(s) → read those files
- Empty → `git diff HEAD -- '*.swift'`

If nothing to review, stop.

---

## Step 2 — Style review (Sonnet agent)

Launch a **Sonnet agent** with the code and `.claude/rules/code-style.md`.

Check every rule. Return a flat list of issues grouped by category:
- Formatting
- Naming
- Access Control
- Optionals
- Closures
- SwiftUI
- SOLID

Format: `[file:line] description | severity (Critical/Warning/Suggestion)`

---

## Step 3 — Confidence scoring (parallel Haiku agents)

For each issue, launch a **Haiku agent** in parallel to score it (0–100):

- **0** — False positive or pre-existing issue
- **25** — Possibly real but unverifiable
- **50** — Real but minor / rare
- **75** — Highly confident; directly mentioned in rules or clearly a real violation
- **100** — Certain; confirmed by direct evidence

**Discard issues with score < 75.**

---

## Step 4 — Output

If no issues survive:

> ### Style Review
> ✅ No style issues found.
> 🤖 Generated with [Claude Code](https://claude.ai/code)

If issues found, group by category:

> ### Style Review
>
> **Formatting / Naming / Optionals / SwiftUI / SOLID / ...**
>
> 🔴 Critical / 🟡 Warning / 🔵 Suggestion — `file.swift:line`
> Description. Rule: _"quoted rule"_ from [code-style.md](.claude/rules/code-style.md)
>
> 🤖 Generated with [Claude Code](https://claude.ai/code)
