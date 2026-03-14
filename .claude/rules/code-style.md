# Code Style Review Rules

Based on MEGA iOS Swift Style Guide and SwiftUI Programming Guide.

---

## General Principles

- Program towards protocols/interfaces, not concrete implementations (Protocol-Oriented Programming)
- Prefer `struct`/`enum` over `class` — use `class` only when inheritance or reference semantics are needed
- Prefer immutability: `let` over `var`, value types over reference types
- Functions > 20 lines: consider breaking down
- Types > 200 lines: consider SRP violation

---

## Formatting

- 4 spaces per indent (no tabs)
- Max 150 characters per line
- No semicolons
- Opening brace on same line as declaration (1TBS style) — never on new line
- No trailing whitespace
- No space before `(` in function/method/property calls
- Space after commas
- Space before and after binary operators (`+`, `==`, `->`)
- Space before and after parentheses
- No space before `:` (except ternary `a ? b : c`)
- No space before or after range operators (`...`, `..<`)

---

## Sections & Organization

- Use `// MARK: - Section title` to group code within a type
- Each protocol conformance in its own `extension` with a `// MARK: -` header
- `// TODO:` and `// FIXME:` are allowed during development, NOT in production code
- Group properties and functions by access level

---

## Naming

- `PascalCase` for types and protocols; `lowerCamelCase` for everything else
- No abbreviations unless well-known (HTML, URL, SSL)
- Classes/structs: noun or noun phrase (`FileAggregator`)
- Functions/methods: verb or verb phrase (`loadThumbnail`, `calculateCount`)
- Event/notification handlers: past-tense (`didTapButton`, `didReceiveNotification`) — NOT `handleButtonTapped` or `modelChanged`
- Include type hint when ambiguous: `nameLabel`, `popupController`, `personImageView`
- NO Objective-C-style prefixes: no `MEGAHelloViewController`, no `kMyConstantString`
- NO `*Controller` suffix for classes that aren't view controllers
- Avoid `IfNeeded` suffix (implies complex, verbose method violating SRP)

**File naming:**
- Single type `MyType` → `MyType.swift`
- Extension conforming to protocol → `MyType+MyProtocol.swift`
- Extension adding feature → `MyType+MyFeature.swift`
- Multiple general extensions → `MyType+Additions.swift`

**Protocol naming:**
- Capability protocol (`-ing`, `-able`) → remove suffix in conforming type name
- Role protocol (`-Delegate`, `-Collection`) → keep suffix in conforming type name

**Methods:**
- No prefix/suffix in general
- Extensions on external frameworks: `mnz_` prefix
- Factory methods: begin with `make` (e.g., `makeIterator()`)

---

## Style

**General:**
- Always use `let` unless mutation is required
- `first(where:)` over `filter().first`
- `isEmpty` over `count > 0`
- No `self.` unless the compiler requires it
- Don't annotate types where they can be inferred
- Prefer higher-order functions (`map`, `filter`, `reduce`) over manual iteration

**Access Control:**
- Apply the strictest access level possible — never `public` unless required
- `private` for anything not exposed outside the type
- Don't write `internal` explicitly (it's the default)
- Write access modifier first: `private let`, `private func`

**Optionals:**
- NO force unwrap (`!`) in general
  - Exceptions: `@IBOutlet`, dequeued `UITableViewCell`, storyboard-instantiated VCs, injected VC properties
- NO `if let _ = optional { }` — use `if optional != nil` instead
- NO `unowned` — use `weak` (exceptions: closure property where `weak` creates excessive boilerplate, or non-nil is a `preconditionFailure`)
- Prefer short unwrap syntax: `guard let myValue else { return }` (not `guard let myValue = myValue`)

**Functions:**
- Omit `-> Void` return type
- Omit argument labels when purpose is clear
- Avoid global functions

**Properties:**
- Omit `get {}` for read-only computed properties
- `static` over `class` for type properties (unless subclass override needed)

**Closures:**
- Trailing closure syntax (unless multiple closures make intent ambiguous)
- Omit unnecessary parentheses
- Use shorthand argument names (`$0`, `$1`) unless disambiguation is needed
- `Void` over `()` in closure type declarations
- Unused parameters: `_`
- Single-line closures: space inside braces `{ $0 > 0 }`

**Protocols:**
- Each protocol conformance in a separate `extension` with `// MARK: -`
- Do NOT list multiple protocols in the class declaration

**Extensions:**
- Prefer extension functions over methods on concrete types — consider if the logic can be generalized

**Control Flow:**
- `guard` over `if` for early exits
- Use optionals only when they have genuine semantic meaning

**Error Handling:**
- NO empty `catch {}` — use `try?` or rethrow
- `catch {}` with no body is forbidden

**Constants:**
- Prefer literals directly in code unless the value is repetitive or configurable

**Generics vs Existentials:**
- Default to generics (`<T: Protocol>`) for compile-time safety and performance
- Use `any Protocol` / `Any` / `AnyObject` only when genuinely heterogeneous types are needed at runtime

---

## SwiftUI-Specific

**State Management:**
- Minimize `@State` and `@EnvironmentObject` in views — manage state in ViewModel
- Use `@State` + `@Environment` only when passing state down a view tree where ViewModel is impractical
- Install ViewModels with `@StateObject` (owning view) or `@ObservedObject` (child view)
- **No Tasks inside ViewModels** — expose `async` methods instead; let the View layer create and own Tasks
  - ✅ `Button("Refresh") { Task { await viewModel.loadData() } }`
  - ❌ `func loadData() { Task { self.data = await useCase.fetch() } }`

**View Building:**
- Views must be dumb — no business logic, no use case calls
- Extract small, focused subviews (SwiftUI views are cheap structs, no overhead)
- Avoid `if`/`switch`/`guard` for conditional view identity — prefer `.opacity()`, `.padding()` modifiers to keep structural identity stable
- Avoid `AnyView` — it erases type information and degrades performance
- Avoid heavy work in view initializers

**View Refresh Performance:**
- Minimum Scope of Impact: design view tree so state changes refresh only the smallest necessary subtree
- Group views by their state dependencies — don't let unrelated state changes trigger parent re-renders
- For high-frequency updates (large scrolling lists): consider `EquatableView` to take over diffing

**Previews:**
- Use `#Preview` macro instead of `PreviewProvider` conformance (`PreviewProvider` inflates unit test coverage)
