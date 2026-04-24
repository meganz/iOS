---
allowed-tools: Read, Grep, Glob, Edit, Bash(git diff:*), Bash(git log:*)
description: Add a new method to a Repository protocol and its implementation, following the project async/await + RequestDelegate pattern
---

Add the method **`$ARGUMENTS`** to the appropriate Repository protocol and implementation, following project conventions.

---

## Step 1 — Locate the Repository

Search the codebase for the repository that owns this method:
- Protocol: `*RepositoryProtocol.swift` — find the file by searching for the related domain area
- Implementation: the corresponding `*Repository.swift` file

Read both files in full before making any changes.

---

## Step 2 — Locate the ObjC SDK method

Find the corresponding ObjC SDK method in `Modules/DataSource/MEGASDK/Sources/MEGASDK/bindings/ios/include/MEGASdk.h`.

Identify:
- The exact Swift method name (ObjC bridging name)
- All parameters and their types
- Whether it has a `delegate:` parameter (async) or returns a value directly (synchronous)
- For async: what the successful `MEGARequest` response carries (e.g. `request.number`, `request.text`, `request.node`)

If the ObjC method does not exist yet, stop and tell the user to run `/sdk-binding` first.

**Determine whether the method is async or synchronous:**
- **Async**: ObjC method has a `delegate:(id<MEGARequestDelegate>)` parameter — result arrives via `RequestDelegate` callback
- **Synchronous**: ObjC method returns a value directly (no delegate parameter) — can be called inline

Follow the matching path below for all remaining steps.

---

## Step 3 — Determine the method signature and pattern

### Async path

Choose the right async wrapper based on the return value:

| Return | Wrapper | Completion |
|---|---|---|
| A value | `withAsyncThrowingValue(in:)` | `completion(.success(value))` |
| Void | `withAsyncThrowingVoidValue(in:)` | `completion(.success(()))` |

Failure always uses: `completion(.failure(GenericErrorEntity()))`

Protocol signature:
```swift
func methodName(param: ParamType) async throws -> ReturnType
```

Never use escaping closures or Combine `Future` in new Repository methods.

### Synchronous path

No async wrapper. The repository method calls the SDK inline and returns the result.

Protocol signature:
```swift
func methodName(param: ParamType) -> ReturnType
```

If the SDK can return `nil` (optional pointer), decide whether to:
- Return an `Optional` and let the caller handle it, or
- Throw (make the method `throws`) when `nil` represents a genuine failure

---

## Step 4 — Add to the protocol

Insert the new method declaration in the protocol, grouped with related methods.

**Async:**
```swift
/// <One-line description.>
/// - Throws: `GenericErrorEntity` if <failure condition>.
func methodName(param: ParamType) async throws -> ReturnType
```

**Synchronous:**
```swift
/// <One-line description.>
func methodName(param: ParamType) -> ReturnType
```

---

## Step 5 — Implement in the Repository

Follow the exact pattern used by existing methods in the same file.

**Async — value return:**
```swift
func methodName(param: ParamType) async throws -> ReturnType {
    try await withAsyncThrowingValue { completion in
        sdk.sdkMethodName(param, delegate: RequestDelegate { result in
            switch result {
            case .success(let request):
                completion(.success(<map request to value>))
            case .failure:
                completion(.failure(GenericErrorEntity()))
            }
        })
    }
}
```

**Async — void return:**
```swift
func methodName(param: ParamType) async throws {
    try await withAsyncThrowingVoidValue { completion in
        sdk.sdkMethodName(param, delegate: RequestDelegate { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure:
                completion(.failure(GenericErrorEntity()))
            }
        })
    }
}
```

**Synchronous:**
```swift
func methodName(param: ParamType) -> ReturnType {
    sdk.sdkMethodName(param)
}
```

Insert the implementation immediately after the last related method in the same logical group.

---

## Step 6 — Check for mock updates

Search for a Mock of this repository protocol (e.g. `Mock*Repository.swift`) in `MEGADomainMock` or the feature's test targets.

If found, read the existing stubs in the file and match their naming pattern exactly (e.g. `stubbedXxx`, `xxxError`, `xxx_calledTimes` — whatever the file already uses). Then add a stub for the new method following that same convention.

The shape of the stub depends on the method type:

**Async — can throw:**
```swift
// stored property named per the file's existing convention
func methodName(param: ParamType) async throws -> ReturnType {
    if let error = <errorProperty> { throw error }
    return <stubbedValue ?? default>
}
```

**Async — value result:**
```swift
// stored property named per the file's existing convention
func methodName(param: ParamType) async throws -> ReturnType {
    <stubbedValue>
}
```

**Synchronous:**
```swift
// stored property named per the file's existing convention
func methodName(param: ParamType) -> ReturnType {
    <stubbedValue>
}
```

---

## Step 7 — Output a summary

Report:
- Whether the method is async or synchronous
- Protocol method signature added (file + line)
- Implementation added (file + line)
- SDK method called
- For async: response mapping decision (what field of `MEGARequest` was used)
- Whether a mock was updated
