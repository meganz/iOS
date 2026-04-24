---
allowed-tools: Read, Grep, Glob, Edit, Bash(git diff:*), Bash(git log:*)
description: Add a missing C++ MegaApi function to the MEGASdk ObjC binding layer (header + implementation)
---

Add the function **`$ARGUMENTS`** to the MEGASdk ObjC binding layer, following the project conventions.

---

## Step 1 — Locate the C++ function

Search `Modules/DataSource/MEGASDK/Sources/MEGASDK/include/megaapi.h` for `$ARGUMENTS`.

Read its full doc comment and signature:
- Parameter types (e.g. `MegaTimeStamp`, `int`, `const char*`, `MegaRequestListener*`)
- Return type
- Associated request type (e.g. `MegaRequest::TYPE_SET_ATTR_USER`)
- Valid data in request callbacks (`getNumber`, `getParamType`, `getText`, etc.)

If not found, stop and tell the user.

**Determine whether the function is async or synchronous:**
- **Async**: has a `MegaRequestListener*` parameter (result arrives via callback)
- **Synchronous**: no listener parameter; returns a value directly (e.g. `int`, `bool`, `const char*`, `MegaNode*`)

Follow the matching path below for all remaining steps.

---

## Step 2 — Understand ObjC type mappings

Use these rules to map C++ types → ObjC types:

| C++ type | ObjC type |
|---|---|
| `MegaTimeStamp` / `int64_t` | `int64_t` |
| `MegaHandle` | `uint64_t` |
| `int` / `NSInteger` | `NSInteger` |
| `unsigned int` | `NSUInteger` |
| `bool` / `BOOL` | `BOOL` |
| `const char*` | `NSString *` |
| `MegaNode*` | `MEGANode *` |
| `MegaRequestListener*` | `id<MEGARequestDelegate>` |
| `void` return | `- (void)` |

Check how similar existing methods handle these types by reading `bindings/ios/include/MEGASdk.h` and `bindings/ios/MEGASdk.mm` for reference patterns near the area where the new method belongs.

---

## Step 3 — Name the ObjC method

Follow these naming conventions:
- Method name must be an ObjC verb phrase in lowerCamelCase
- Map parameter names clearly (e.g. `until:` for a timestamp cutoff, `delegate:` for the listener)
- **Async only**: The `MegaRequestListener*` parameter always becomes `delegate:(id<MEGARequestDelegate>)delegate` and is always the last parameter. If the C++ function has an optional listener (default `nullptr`), still require it in ObjC (no nullable overload unless one already exists).
- **Synchronous only**: No delegate parameter. The ObjC return type must match the C++ return type per the mapping table.

---

## Step 4 — Write the doc comment (header)

**Async** — use `///` style with request type and callback data:

```objc
/// <One-line description.>
///
/// <Longer description if needed.>
///
/// The associated request type with this request is <MEGARequestType...>
///
/// Valid data in the MEGARequest object received on callbacks:
///
/// - [MEGARequest <property>] - <what it returns>
///
/// @param <name> <description>
/// @param delegate MEGARequestDelegate to track this request
- (void)<methodName>:<params> delegate:(id<MEGARequestDelegate>)delegate;
```

**Synchronous** — use `///` style, omit request type and callbacks section:

```objc
/// <One-line description.>
///
/// <Longer description if needed.>
///
/// @param <name> <description>
/// @return <what is returned>
- (<ReturnType>)<methodName>:<params>;
```

---

## Step 5 — Write the implementation (.mm)

**Async** — delegate the call through a request listener:

```objc
- (void)<methodName>:<params> delegate:(id<MEGARequestDelegate>)delegate {
    if (self.megaApi != nil) {
        self.megaApi-><cppFunctionName>(<cast params>, [self createDelegateMEGARequestListener:delegate singleListener:YES]);
    }
}
```

**Synchronous** — call directly and return the result. Use a safe default when `megaApi` is nil:

```objc
- (<ReturnType>)<methodName>:<params> {
    if (self.megaApi == nil) return <safe default>;
    return self.megaApi-><cppFunctionName>(<cast params>);
}
```

Safe defaults by return type: `NSInteger`/`int64_t`/`uint64_t` → `0`, `BOOL` → `NO`, pointer → `nil`.

Cast each ObjC param to its C++ type explicitly (e.g. `(int)days`, `(MegaTimeStamp)until`, `(unsigned int)maxNodes`).

---

## Step 6 — Insert into the files

- **Header**: Insert the declaration immediately after the last related method in the same logical group. If no related group exists, insert immediately before the closing `@end` of the `@interface MEGASdk` block.
- **Implementation**: Insert the implementation immediately after the last related method in the same logical group in `MEGASdk.mm`. If no related group exists, insert immediately before the closing `@end` of the `@implementation MEGASdk` block.

Make both edits.

---

## Step 7 — Output a summary

Report:
- ObjC method signature added
- Whether the binding is async or synchronous
- File locations (header line, implementation line)
- Any type mapping decisions worth noting
