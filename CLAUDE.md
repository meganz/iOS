# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Tech Stack

- **Language**: Swift (primary), Objective-C++ (SDK bindings layer)
- **UI**: SwiftUI (preferred for new code) + UIKit (legacy, phasing out)
- **Pattern**: Clean Architecture + MVVM
- **Dependency management**: Swift Package Manager for all internal modules
- **Linting**: SwiftLint with custom rules (`.swiftlint.yml`)
- **Localization**: SwiftGen-generated strings via `MEGAL10n` module — never hand-edit `Strings+Generated.swift`

## Architecture: Clean + MVVM

Four strict layers. Dependencies only flow inward (Dependency Rule): UI → Presentation → Domain ← Data.

```
UI Layer  →  Presentation Layer  →  Domain Layer  ←  Data Layer
```

### Domain Layer (innermost, most stable)

| Component | Role | Rules |
|---|---|---|
| **Entity** | Business data model | Value types preferred; independent of UI and data models |
| **Use Case** | Business action/transaction | No MEGASdk, no UIKit/SwiftUI; only other Use Cases and Repository Protocols; small, single-responsibility |
| **Repository Protocol** | Abstracts data access for Use Cases | Inverts dependency between Domain and Data Layer |

### Data Layer

| Component | Role | Rules |
|---|---|---|
| **Repository** | Implements Repository Protocol; coordinates data sources | Maps DTO → Domain Entity; never calls other repositories; can contain multiple data sources |
| **Data Source** | Raw data access (MEGASdk, CoreData, API, Karere) | Wrapped inside Repository; does not need tests |

### Presentation Layer

| Component | Role | Rules |
|---|---|---|
| **ViewModel** | Presentation logic; owns Use Cases | No UIKit (SwiftUI VM) / no business logic; no MEGASdk or Repository — only Use Cases |
| **Model** | UI-specific data model | Only create if primitives (String, Int) are insufficient |

### UI Layer (outermost, most unstable)

| Component | Role | Rules |
|---|---|---|
| **SwiftUI View** | UI rendering | As dumb as possible; no business or presentation logic |
| **UIViewController** | UI rendering (legacy) | Treated as part of View; no MEGASdk, Repository, or Use Case — only VM |
| **Router** (UIKit only) | Navigation; wireframe builder | Only place to construct VCs; only calls other routers; no Use Case/Repository access |

## SwiftUI MVVM (Preferred)

New features use SwiftUI. ViewModel is `ObservableObject` with `@Published` properties. Data binding via Combine.

```swift
struct PhotoCell: View {
    @StateObject var viewModel: PhotoCellViewModel
}

final class PhotoCellViewModel: ObservableObject {
    @Published var thumbnailContainer: ImageContainer
    @Published var isSelected: Bool = false
}
```

## UIKit Action-Command Pattern (Phasing Out)

Legacy UIKit code uses a Redux-inspired **unidirectional** Action-Command pattern:
- **VC → VM**: VC dispatches `Action` (input boundary)
- **VM → VC**: VM invokes `Command` (output boundary)
- Direct VC↔VM calls are forbidden — preserves unidirectional flow

```swift
// VC dispatches action
viewModel.dispatch(.onViewReady)

// VM invokes command
invokeCommand?(.configView(verificationType))

// VC executes command
func executeCommand(_ command: ViewModel.Command) { ... }
```

VM conforms to `ViewModelType`, VC conforms to `ViewType`.

## Model Mapping

Each layer owns its own data models. Models never skip layers.

- **Data Layer**: maps SDK/API DTOs → Domain Entities
- **Presentation Layer**: maps Domain Entities → presentation models (use primitives when possible)
- **UI Layer**: displays primitives; no model transformation
- **Domain Layer**: no mapping — it's the core, depends on nothing

## Error Handling

Errors flow upward and are transformed at each boundary:

- **Data Layer**: spawns data errors, maps them → Domain error entities
- **Domain Layer**: propagates domain errors, never swallows them
- **Presentation Layer**: maps domain errors → display strings; can swallow if UI doesn't need them
- **UI Layer**: displays error strings only — no error objects reach UI

## Modularization

Each module is a standalone Swift Package (`Package.swift`) with explicit products and targets. Modules communicate only through published interfaces.

### Module structure (`Modules/`)

| Layer | Location |
|---|---|
| DataSource | `Modules/DataSource/MEGASDK`, `MEGAChatSDK` (git submodules) |
| Repository | `Modules/Repository/MEGARepo`, `MEGASDKRepo`, `ChatRepo`, etc. |
| Domain | `Modules/Domain/MEGADomain` |
| Presentation | `Modules/Presentation/MEGAPresentation`, `MEGAAppPresentation` |
| Features (16) | `Modules/Features/{Accounts,Chat,CloudDrive,…}` |
| UI | `Modules/UI/MEGASwiftUI`, `MEGAUIKit`, `MEGAUI` |
| Infrastructure | `Modules/Infrastructure/MEGAFoundation`, `MEGASwift`, `MEGAPermissions`, etc. |

`Modules/MEGASharedRepo/` is a git submodule with ~34 additional shared modules (authentication, analytics, connectivity, deep linking, etc.).

`iMEGA/` is the legacy UIKit layer being migrated. **New features go into `Modules/Features/`**, not `iMEGA/`.

## Key Conventions

- **No `MEGASdkManager`** — use `MEGASdk+SharedInstance` or `MEGASdk+SharedInstanceWrapper`
- **No `MEGAGenericRequestDelegate` / `MEGAResultRequestDelegate`** — use `RequestDelegate`
- **No `MEGAChatGenericRequestDelegate` / `MEGAChatResultRequestDelegate`** — use `ChatRequestDelegate`
- **No `URL(fileURLWithPath:).pathExtension`** — use `MEGASwift.String.pathExtension`
- Cyclomatic complexity limit: warning at 15, error at 30
- Commit format: `CC-XXXX: Short description` (Jira ticket prefix)
