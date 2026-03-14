---
allowed-tools: Bash(git diff:*)
description: Swift Concurrency review against the Swift Concurrency Guide with confidence scoring
---

Review the **Swift Concurrency usage** of the provided MEGA iOS code. Uses a reviewer agent and a scoring agent to filter false positives.

**Target**: $ARGUMENTS

---

## Step 1 — Get the code

- File path(s) → read those files
- Empty → `git diff HEAD -- '*.swift'`

If nothing to review, stop.

---

## Step 2 — Concurrency review (Sonnet agent)

Launch a **Sonnet agent** with the code and `.claude/rules/swift-concurrency.md`.

Check every rule. Scan specifically for:
- `DispatchQueue` / `Semaphore` / `OperationQueue` usage in new code
- Escaping completion closures that should be `async throws`
- `Task.detached` — is it justified?
- Task cancellation checks (`Task.isCancelled`) at key paths
- `task = nil` after `task.cancel()`
- Long-running sync work inside `Task { }`
- Unbounded `TaskGroup` child tasks
- Sendable fix at the wrong layer
- `@unchecked Sendable` — is the use valid?
- `@MainActor` in Domain/Data layers (forbidden)
- `@objc` + `@MainActor` without `Task { @MainActor in }` wrapper
- Continuation called exactly once on all paths
- `AsyncSequence` task cancellation / memory leak
- `AsyncStream` concurrent iteration

Return a flat list of issues: `[file:line] description | severity (Critical/Warning/Suggestion)`

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

> ### Concurrency Review
> ✅ No concurrency issues found.
> 🤖 Generated with [Claude Code](https://claude.ai/code)

If issues found:

> ### Concurrency Review
>
> 🔴 Critical / 🟡 Warning / 🔵 Suggestion — `file.swift:line`
> Description. Risk: _data race / memory leak / crash / thread pool exhaustion_. Rule: _"quoted rule"_ from [swift-concurrency.md](.claude/rules/swift-concurrency.md)
>
> 🤖 Generated with [Claude Code](https://claude.ai/code)
