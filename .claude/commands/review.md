---
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git blame:*)
description: Full code review across Architecture, Style, and Swift Concurrency using parallel agents with confidence scoring
---

Perform a full code review for MEGA iOS. Use parallel agents and confidence scoring to produce a high signal-to-noise result.

**Target**: $ARGUMENTS

---

## Step 1 — Get the code

Determine what to review:
- If `$ARGUMENTS` looks like file path(s) → read those files
- If empty → run `git diff HEAD -- '*.swift'` for recent changes

If there is nothing to review, stop here.

---

## Step 2 — Triage (Haiku agent)

Launch a **Haiku agent** to decide if the review should proceed. Skip if any of:
- The diff is empty or trivially small (e.g. only comments, whitespace, or version bumps)
- It is an automated/generated change (e.g. `Strings+Generated.swift`, `.pbxproj` only)

Return: **proceed** or **skip** with reason.

---

## Step 3 — Parallel review (4 Sonnet agents)

If proceeding, launch **4 Sonnet agents in parallel**. Each agent must:
1. Read the code under review (pass the diff/file content to each agent)
2. Read its assigned rule file
3. Return a flat list of issues in the format: `[file:line] description`

**Agent 1 — Architecture**
Read `.claude/rules/architecture.md`.
Check: layer dependency violations, Domain Entity constraints (struct/no raw values/no handles in Use Case interfaces), ViewModel constraints (UIKit Action-Command / SwiftUI), Router rules, Model Mapping, Error Handling flow, deprecated API usage.

**Agent 2 — Code Style**
Read `.claude/rules/code-style.md`.
Check: naming conventions, formatting, access control, optionals safety, closure style, SwiftUI state management, no Tasks inside ViewModels, minimum scope of impact, `#Preview` over `PreviewProvider`.

**Agent 3 — Swift Concurrency**
Read `.claude/rules/swift-concurrency.md`.
Check: GCD/callback usage in new code, task cancellation, unbounded TaskGroup, Sendable fix approach (wrong-layer fix is a critical violation), `@MainActor` in Domain/Data layers, `@objc` + `@MainActor` without Task wrapper, Continuation call count, AsyncSequence memory leaks.

**Agent 4 — Bug scan**
No rules file. Do a focused scan for obvious bugs in the changed code only:
- Logic errors, off-by-one, nil crashes
- Race conditions or shared mutable state
- Misuse of Swift APIs
- Missing error propagation
Ignore pre-existing issues and things the compiler/linter would catch.

---

## Step 4 — Confidence scoring (parallel Haiku agents)

For each issue returned by Step 3, launch a **Haiku agent** in parallel to score it.

Give the agent: the issue description, the relevant code snippet, and the rule file path if applicable.

Score on this scale (give verbatim to each agent):
- **0** — False positive. Does not stand up to light scrutiny, or is a pre-existing issue not introduced by this change.
- **25** — Possibly real, but unverifiable. Stylistic issues not explicitly called out in the rules.
- **50** — Moderately real. Verified issue, but minor / rare in practice.
- **75** — Highly confident. Double-checked; very likely a real issue that will be hit in practice, or directly called out in the rules.
- **100** — Certain. Confirmed real issue that happens frequently; evidence directly confirms it.

**Filter: discard any issue with score < 75.**

---

## Step 5 — Output

If no issues survive filtering:

> ### Code Review
> No issues found. Checked architecture, code style, and Swift concurrency.
> 🤖 Generated with [Claude Code](https://claude.ai/code)

If issues were found, output in this format:

> ### Code Review
>
> Found N issues:
>
> **[Architecture / Style / Concurrency / Bug]** `file.swift:line` — Brief description.
> Rule: _"quoted rule text"_ from `.claude/rules/architecture.md` (or whichever applies)
>
> **[...]** ...
>
> 🤖 Generated with [Claude Code](https://claude.ai/code)

Guidelines for the final output:
- Keep descriptions brief and actionable
- Quote the specific rule that was violated when applicable
- Do not flag pre-existing issues, compiler-caught issues, or things outside the changed lines

> 💡 For focused review: `/review-arch`, `/review-style`, `/review-concurrency`
