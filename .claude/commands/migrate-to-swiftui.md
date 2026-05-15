---
allowed-tools: Read, Grep, Glob, Edit, Write, Bash(git diff:*), Bash(git log:*)
description: Guided migration of a UIKit ViewController to SwiftUI, transforming Action/Command MVVM-R to ObservableObject pattern
---

Migrate the UIKit ViewController **`$ARGUMENTS`** to SwiftUI, following the project's architecture rules.

---

## Step 1 — Locate and read source files

Search for the ViewController by name. Read these files in full:

1. **ViewController** (`*ViewController.swift`) — the UIKit view
2. **ViewModel** (`*ViewModel.swift`) — look for `ViewModelType` conformance with `Action` and `Command` enums
3. **Router** (`*Router.swift`) — look for `build()` and `start()` methods, navigation logic

If any file is missing, inform the user (name which file(s) are missing) and proceed with what exists.

---

## Step 2 — Analyze the UIKit pattern

Extract and document:

### From the ViewModel:
- **Action enum cases** — list every `case` in `Action: ActionType`
- **Command enum cases** — list every `case` in `Command: CommandType`
- **Use Case dependencies** — all injected protocols (these stay the same)
- **State properties** — any stored properties that drive UI
- **Async work** — Tasks, subscriptions, monitors

### From the ViewController:
- **executeCommand() cases** — how each Command updates the UI
- **dispatch() calls** — which Actions are triggered and when (viewDidLoad, button taps, etc.)
- **UIKit-specific code** — table/collection views, navigation bar setup, alerts, HUDs

### From the Router:
- **Navigation destinations** — what screens it can navigate to
- **Dependencies it injects** — what it passes to child VCs/VMs
- **How it's triggered** — which ViewModel actions or VC events cause navigation

Present this analysis to the user before proceeding.

---

## Step 3 — Design the SwiftUI mapping

Map each UIKit pattern to its SwiftUI equivalent:

### ViewModel transformation

| UIKit (old) | SwiftUI (new) |
|---|---|
| `ViewModelType` conformance | `ObservableObject` conformance |
| `enum Action: ActionType` | Remove — replaced by direct method calls |
| `enum Command: CommandType` | Remove — replaced by `@Published` properties |
| `var invokeCommand: ((Command) -> Void)?` | Remove entirely |
| `func dispatch(_ action: Action)` | Extract each case into a named `func` |
| `invokeCommand?(.showData(data))` | `@Published private(set) var data: DataType` (set directly) |
| `invokeCommand?(.startLoading)` | `@Published private(set) var isLoading = false` |
| `invokeCommand?(.showError(msg))` | `@Published private(set) var errorMessage: String?` + `@Published var showError = false` (this one stays writable — `.alert(isPresented:)` needs a two-way `Binding`) |
| Private Use Case calls | Keep as-is, but expose results via `@Published private(set)` |

### View transformation

| UIKit (old) | SwiftUI (new) |
|---|---|
| `viewDidLoad` + `dispatch(.onViewReady)` | `.onLoad { await viewModel.fetchData() }` (from `MEGASwiftUI`) — runs the action exactly once on first appearance, mimicking `viewDidLoad`. Do NOT use `.task` here: `.task` re-runs every time the view re-appears, which is `viewWillAppear` semantics, not `viewDidLoad` |
| `viewWillAppear` + `dispatch(.onViewWillAppear)` | `.task { await viewModel.onAppear() }` — prioritize `.task` whenever possible (lifecycle-aware, auto-cancels, native `async` support). Use `.onAppear { }` only for synchronous fire-and-forget work (e.g. analytics ping, simple state flip) |
| `executeCommand(.showData(data))` | Automatic — view reads `viewModel.data` via binding |
| `SVProgressHUD.show()` | `if viewModel.isLoading { ProgressView() }` |
| Button → `dispatch(.buttonTapped)` | `Button { viewModel.buttonTapped() }` |
| `UITableView` / `UICollectionView` | `List` / `LazyVGrid` / `LazyVStack` |
| Alert via command | `.alert(isPresented: $viewModel.showAlert)` |

### Navigation transformation

| UIKit (old) | SwiftUI (new) |
|---|---|
| Router protocol | Closure-based navigation injected in ViewModel init |
| `router.showScreen(data)` | `navigateToScreen(data)` closure call |
| `router.build()` → present VC | Parent view handles `NavigationLink` or `.sheet` |

---

## Step 4 — Implement the new ViewModel

Create the new ViewModel following these rules:

```swift
@MainActor
public final class <Name>ViewModel: ObservableObject {
    // MARK: - Published State (replaces Command enum)
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var showError = false // writable: backs `.alert(isPresented:)` two-way binding
    @Published private(set) var <dataProperty>: <Type>
    
    // MARK: - Dependencies (same Use Cases as before)
    private let <useCase>: any <UseCaseProtocol>
    
    // MARK: - Navigation (replaces Router)
    private let navigateToX: (<Params>) -> Void
    
    init(
        <useCase>: some <UseCaseProtocol>,
        navigateToX: @escaping (<Params>) -> Void
    ) {
        self.<useCase> = <useCase>
        self.navigateToX = navigateToX
    }
    
    // MARK: - Actions (each former Action case becomes a method)
    
    func fetchData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            <dataProperty> = try await <useCase>.fetch()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func buttonTapped() {
        // Former dispatch(.buttonTapped) logic
    }
}
```

**Rules:**
- No `Task { }` inside the ViewModel — expose `async` methods, let the View create Tasks via `.task` / `.onLoad` or `Button { Task { await ... } }`
- No UIKit imports
- No `invokeCommand` or `dispatch`
- Use `@Published private(set)` for state the View only reads. Leave it writable only when it backs a two-way `Binding` (alert `isPresented:`, text fields, toggles, sheet/`item:` bindings)
- Navigation via closures, not Router references

---

## Step 5 — Implement the SwiftUI View

```swift
public struct <Name>View: View {
    @StateObject private var viewModel: <Name>ViewModel
    
    public init(viewModel: @autoclosure @escaping () -> <Name>ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else {
                content
            }
        }
        .onLoad {
            await viewModel.fetchData()
        }
        .alert(Strings.Localizable.error, isPresented: $viewModel.showError) {
            Button(Strings.Localizable.ok) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private var content: some View {
        // Decomposed subviews
    }
}
```

**Rules:**
- Keep the view dumb — no business logic, no Use Cases
- Extract subviews for readability (SwiftUI views are cheap structs)
- Use `.onLoad` for once-per-screen initial work (`viewDidLoad` equivalent); use `.task` for work that should re-run on every appearance and auto-cancel on disappear (`viewWillAppear` equivalent)
- Use `#Preview` macro for previews, not `PreviewProvider`
- Prefer `.opacity()` / `.padding()` over `if`/`switch` for conditional layout (preserves structural identity)

**Localization, design token, and layout rules:**
- All user-facing strings must use `Strings.Localizable.<key>` from `MEGAL10n` — never hardcode English text in `Text`, `Button`, `.alert`, `.navigationTitle`, accessibility labels, etc. If the UIKit code used a localized key, reuse it; if it used a hardcoded literal (legacy bug), surface this in the migration summary so the team can add a key
- Use `TokenSpacing` for all spacing/padding values and `TokenRadius` for corner radii — never hardcode magic numbers when a design token exists (e.g. `TokenSpacing._5` instead of `16`, `TokenRadius.medium` instead of `8`)
- Match UIKit image sizing behavior: if the UIKit `UIImageView` has no explicit width/height constraints, use `Image(uiImage:)` at intrinsic size — do NOT add `.resizable().scaledToFit()` unless the UIKit version had explicit size constraints or `contentMode` that stretched the image
- Match UIKit layout semantics precisely: `readableContentGuide` + `layoutMargins` → equivalent cumulative SwiftUI `.padding()`; left-aligned containers inside a centered parent need `.frame(maxWidth: .infinity, alignment: .leading)` to stretch and stay left-aligned
- Only override text color when the UIKit code explicitly sets a non-default color — SwiftUI's default `Text` color matches `UIColor.label`, so don't add `foregroundStyle` unless the UIKit code used something other than `.label`

---

## Step 6 — Handle the Router migration

If a Router exists:
1. Extract each navigation destination as a closure parameter on the ViewModel
2. The parent/coordinator that creates the View injects these closures
3. Delete the Router file (or mark as deprecated if still used elsewhere)

Example:
```swift
// Old: Router
router.showDetail(for: node)

// New: ViewModel init receives closure
let viewModel = FeatureViewModel(
    useCase: FeatureUseCase(...),
    navigateToDetail: { node in
        // Parent handles navigation
    }
)
```

---

## Step 7 — Place files correctly

- New SwiftUI View + ViewModel → `Modules/Features/<FeatureName>/Sources/...`
- NOT in `iMEGA/` (that's legacy UIKit only)
- Follow feature-based organization, not type-based (no `Views/`, `ViewModels/` folders)
- Keep related code together in the same directory
- **Reusability check**: when creating helper extensions or utilities during migration (e.g., string parsing, attributed string builders, formatters), evaluate whether they are feature-specific or general-purpose. General-purpose utilities must go in a shared module matching their dependency level: `MEGASwift` for pure Swift/Foundation extensions, `MEGASwiftUI` for SwiftUI-specific helpers, `MEGAUI` for UIKit helpers — not in the feature module where they were first needed

---

## Step 8 — Output summary

Report:
- Files created (View, ViewModel) with paths
- Files that can be deprecated/removed (old VC, old VM, Router)
- Action → method mapping table
- Command → @Published property mapping table
- Navigation changes
- Any Use Case or domain changes needed (should be none — domain layer doesn't change)
- TODO items: anything that couldn't be migrated automatically (e.g., complex UIKit custom views)
