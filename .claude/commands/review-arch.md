---
allowed-tools: Bash(git diff:*)
description: Architecture-only code review against Clean Architecture + MVVM rules
---

Review the **architecture** of the provided MEGA iOS code. Uses a reviewer agent and a scoring agent to filter false positives.

**Target**: $ARGUMENTS

---

## Step 1 — Get the code

- File path(s) → read those files
- Empty → `git diff HEAD -- '*.swift'`

If nothing to review, stop.

---

## Step 2 — Architecture review (Sonnet agent)

Launch a **Sonnet agent** with the code and `.claude/rules/architecture.md`.

The agent must identify the architecture layer from the file path:
- `iMEGA/` → legacy UIKit (UI/Presentation)
- `*ViewModel*` → Presentation
- `*View*.swift` → UI (SwiftUI)
- `Modules/Presentation/` → Presentation (focus especially on `Modules/Presentation/` feature subdirectories)
- `Modules/UI/` → UI (SwiftUI) — check coding style here, not architecture
- `Modules/Domain/MEGADomain/` → Domain
- `Modules/Repository/` → Data (Repository)
- `Modules/DataSource/` contains SDK source code — **skip architecture checks here**

Only review files that are part of the diff. Check every rule. Return a flat list of issues: `[file:line] description | severity (Critical/Warning/Suggestion)`

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

> ### Architecture Review
> ✅ No architecture issues found.
> 🤖 Generated with [Claude Code](https://claude.ai/code)

If issues found:

> ### Architecture Review
>
> **Layer**: UI / Presentation / Domain / Data
>
> 🔴 Critical / 🟡 Warning / 🔵 Suggestion — `file.swift:line`
> Description. Rule: _"quoted rule"_ from [architecture.md](.claude/rules/architecture.md)
>
> 🤖 Generated with [Claude Code](https://claude.ai/code)
