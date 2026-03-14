# Swift Concurrency Review Rules

Based on MEGA iOS Swift Concurrency Guide.

---

## General (Critical)

- Prefer `async/await` over `DispatchQueue`, `Semaphore`, `OperationQueue`, or escaping completion closures for ALL new async work
- Escaping completion closures (`@escaping (Result<...>) -> Void`) in new code are a warning — should be `async throws` instead
- `DispatchQueue.global().async` in new code is a warning — bridge to concurrency using `withCheckedContinuation` or `withAsyncThrowingValue`

---

## Tasks

- Prefer structured concurrency (`async let`, `TaskGroup`) over `Task { }` where possible
- Use `Task.detached` ONLY when a top-level execution context independent of the caller is truly required — must justify
- **Cancellation**: check `Task.isCancelled` at key code paths (before making requests, after receiving responses)
- After calling `task.cancel()`, set `task = nil` to allow immediate deallocation (cancelled tasks can accumulate in memory)
- No `weak self` needed inside `Task { }` closures (value lifetimes extend until task completes); use `weak` only to avoid extending object lifetime intentionally
- NO long-running synchronous code inside `Task` — use async alternative, or bridge with `withCheckedContinuation` + `Task.yield`

---

## TaskGroup

- Limit concurrent child tasks to a reasonable number (default: 3) — never spawn unbounded tasks on large collections (e.g., iterating all nodes in a folder)
- Check `Task.isCancelled` before each `taskGroup.addTask { }` call
- Do NOT add tasks to a `TaskGroup` after it has been cancelled

---

## Async/Await

- Reduce unnecessary suspension points — don't `await` sequentially what can run in parallel
- Use `async let` or `TaskGroup` for independent concurrent async work
- Don't make a function `async` if it doesn't need to suspend — simple synchronous functions should stay synchronous

---

## Sendable

**Preferred fix for Sendable warnings (in order):**
1. Mark ViewModel as `@MainActor` — correct approach for Presentation layer
2. Use `nonisolated` for VM functions that must run off main thread
3. If `@MainActor` on VM is too disruptive: mark Use Case as `Sendable` (unpreferred, requires filing a refactor ticket)

**Critical rule:** Do NOT fix Presentation layer Sendable warnings by modifying Domain layer code — this violates the dependency rule (Domain must not depend on Presentation).

**`@unchecked Sendable`** — last resort only. Valid uses:
- MEGA SDK binding objects (have own synchronization)
- Explicitly synchronized objects (e.g., `MEGAStore`)
- Un-audited, immutable objects (e.g., `ImageContainer`, SwiftUI `Image`)

**`@preconcurrency import`** — only for external frameworks, never for internal modules.

---

## Continuation

- `continuation.resume(...)` must be called **exactly once** on **every** code path — missing call = dead suspension, double call = crash
- Use project wrapper `withAsyncThrowingValue` (includes built-in task cancellation check) instead of bare `withCheckedThrowingContinuation`
- Build continuation bridges at a few critical points (e.g., in Repository) — do NOT scatter `withCheckedContinuation` throughout the codebase

---

## Actor / MainActor

**Placement rules:**
- NO `@MainActor` in Domain Layer or Data Layer — main thread awareness belongs only in Presentation and UI layers
- ViewModel should be marked `@MainActor` (it drives the View which is MainActor-bound)
- Functions in `@MainActor` ViewModel that must run off main thread: mark as `nonisolated`

**Global actor granularity:**
- Add global actor annotation to the protocol or superclass (single source of truth), not individual conformers/subclasses
- Do NOT explicitly annotate with global actor if it can be inferred from context (inheritance, protocol conformance, property wrapper)
- Minimize isolation scope — annotate specific properties/functions rather than the entire type when possible

**`@objc` + `@MainActor` — Critical:**
```swift
// ❌ WRONG — actor isolation is lost when called from ObjC; may crash on Swift 6
@MainActor
@objc func someFunction() {
    // main thread logic
}

// ✅ CORRECT — wrap in Task to enforce main actor isolation regardless of caller
@objc func someFunction() {
    Task { @MainActor in
        // main thread logic
    }
}
```

**Actor retention:**
- Avoid calling `async` functions inside an actor body unnecessarily — tasks should only run on the actor when they need exclusive access to actor-isolated data
- Non-actor-isolated work should run off the actor to allow concurrency

---

## AsyncSequence

**Type erasure:**
- Use `AnyAsyncSequence` or `AnyAsyncThrowingSequence` (project wrappers) when exposing `AsyncSequence` in public APIs — do NOT expose concrete `AsyncStream` types directly

**Memory leaks:**
- `AsyncSequence` in a `Task` must be cancelled when done — non-terminating sequences (e.g., `AsyncStream` that doesn't finish) will leak if the task is not cancelled
- Before assigning a new task to a stored property, cancel the existing one: `task?.cancel(); task = Task { ... }`
- Do NOT use `guard let self = self else { return }` inside `for await` loops on weak captures — use `self?.method()` directly

**Concurrent iteration:**
- Do NOT iterate `AsyncStream` from multiple concurrent contexts — neither `AsyncStream` nor its iterator is `@Sendable`; concurrent iteration is a programmer error

---

## Combine vs Concurrency

- Combine is NOT being replaced — use it for values over time (`combineLatest`, `debounce`, `throttle`, etc.)
- `async/await` is for one-shot async work
- Do NOT use Combine `Future` where `async throws` is more appropriate
- Both can coexist: Use Case exposes `async throws`, also exposes `Future` only if a Combine chain needs it
