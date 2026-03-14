# Architecture Review Rules

Based on MEGA iOS Clean Architecture + MVVM spec.

---

## Layer Dependency (Critical)

- UI layer (SwiftUI View / UIViewController — NOT ViewModel) must NOT directly import Domain or Data modules; all data arrives as primitives or presentation models from the ViewModel (Presentation layer)
- ViewController must NOT use MEGASdk, Repository, or Use Case — only ViewModel
- ViewModel (UIKit) must NOT use MEGASdk or Repository — only Use Cases
- ViewModel (SwiftUI) must NOT contain business logic — only presentation logic
- Use Case must NOT import MEGASdk, UIKit, or SwiftUI — only Repository Protocols and other Use Cases
- Repository must NOT call other Repositories
- DataSource must NOT be used outside its owning Repository

## Domain Layer (Critical)

**Entities:**
- Must be `struct` or `enum`, never `class` (unless forced by ObjC interop via `@objc`)
- `enum` entities must NOT have raw values (`enum XxxEntity: String/Int` is forbidden)
  - Exception: `@objc` enum required for ObjC interop
  - Exception: `OptionSet` (forced by `RawRepresentable`) — but add tests for the raw value mapping
- Raw value mapping logic belongs in Data Layer (e.g., `extension StatsEventEntity { func toMEGAEventCode() -> Int }`)

**Use Case interfaces:**
- Must NOT accept `HandleEntity`, `Base64HandleEntity`, `ChatId`, or any `XXXId` as parameters — use full entity objects (`NodeEntity`, `ChatRoomEntity`, etc.)
- Handles are internal to Data Layer only

**Use Case repository dependencies:**
- Default: `private let repo: any RepositoryProtocol` (existential) — correct for DI boundaries
- Use generic `struct UseCase<T: RepositoryProtocol>` only when:
  - Protocol has `associatedtype` you need to preserve in output type
  - High-frequency hot path where static dispatch matters (e.g., thumbnail loading)

**Use Case API surface:**
- MUST expose `async throws` API
- Closure API: `private` only, or when bridging legacy code (mark as deprecated)
- Combine `Future` API: optional, only when needed for chaining in data streams

## Presentation Layer — UIKit Action-Command (Phasing Out)

- VC must ONLY interact with VM via `viewModel.dispatch(action)` — no direct property access or method calls
- VM must ONLY interact with VC via `invokeCommand?(command)` — no direct VC reference
- All VM properties and functions must be `private` except `invokeCommand` and `dispatch(_:)`
- Router is the ONLY place to construct ViewControllers
- Router must NOT call Use Cases, Repositories, or DataSources directly
- Router only calls other Routers

## Presentation Layer — SwiftUI (Preferred)

- View must be a `struct` conforming to `View`
- View must be as "dumb" as possible — no business logic, no Use Cases
- ViewModel must be `ObservableObject`; data binding via `@Published` + Combine
- ViewModel must have no knowledge of view lifecycle or view types

## Model Mapping

- Models must NOT skip layers: a Data Layer DTO must never appear in Presentation or UI code
- DTO → Entity mapping: done in Repository (Data Layer)
- Entity → Presentation model mapping: done in ViewModel (Presentation Layer)
- UI Layer: prefer primitive types (`String`, `Int`, `Bool`); only create presentation `Model` types when primitives are insufficient

## Error Handling

- **Data Layer**: spawns raw errors, maps SDK/API errors → Domain error entities; propagates
- **Domain Layer**: propagates domain errors; never swallows them
- **Presentation Layer**: maps domain error entities → display strings; may swallow if UI doesn't need to react
- **UI Layer**: displays error strings only — no error objects reach UI

## Deprecated APIs (Critical — SwiftLint enforced)

- NO `MEGASdkManager` → use `MEGASdk+SharedInstance` or `MEGASdk+SharedInstanceWrapper`
- NO `MEGAGenericRequestDelegate` / `MEGAResultRequestDelegate` → use `RequestDelegate`
- NO `MEGAChatGenericRequestDelegate` / `MEGAChatResultRequestDelegate` → use `ChatRequestDelegate`
- NO `URL(fileURLWithPath: x).pathExtension` → use `MEGASwift.String.pathExtension`
- NO `URL(fileURLWithPath: x).lastPathComponent` → use `MEGASwift.String.lastPathComponent`

## SOLID Smell Reference

Key checks for this codebase:
- **SRP**: Use Case does one business action only; ViewModel handles one screen's presentation logic
- **DIP**: Domain layer never depends on Data or UI layers — only depends inward via protocols
- **ISP**: Repository Protocols are focused — don't bundle unrelated operations into one protocol
