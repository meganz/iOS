# Offline Test – Question 1: Crash Analysis & Fix

## Overview
- **Crash ID:** `fcd0b77c8d5c9ee7547f01a34b419e40`
- **App version:** 16.17 (2506191128)
- **Primary thread:** `mega::MegaApiImpl::fireOnRequestStart`
- **Context:** User opened a public MEGA link (`mega://#!bGAyAB5D!...`) from Safari, returning to the app. UI breadcrumbs show the Cloud Drive main tab, the ads wrapper view, and media viewers appearing moments before the crash.

## Evidence & Reasoning

1. **Stack trace inspection**
   - Crash occurs on the Mega SDK worker thread when invoking `MegaApiImpl::fireOnRequestStart`.
   - Immediate caller is `MegaApiImpl::sendPendingRequests`, which dequeues a `MegaRequestPrivate` and notifies attached listeners just before the actual network work begins.
   - Failing frame indicates a listener vtable call, consistent with a use-after-free on the `MegaRequestListener` pointer.

2. **Runtime breadcrumbs**
   - Crashlytics logs show `AdsSlotView` being presented immediately before the crash, along with the media viewer.
   - Ads flow uses `MEGASdk.queryAds` via Swift async wrappers. These paths create single-shot `MEGARequestDelegate` instances to bridge back into Swift.

3. **Code audit**
   - `MEGASdk::createDelegateMEGARequestListener` stores each bridge listener inside `_activeRequestListeners` and passes the raw pointer into the native SDK request machinery.
   - For single-shot delegates, `DelegateMEGARequestListener::onRequestFinish` tears down the bridge by calling `[megaSDK freeRequestListener:this]`.
   - `freeRequestListener` used to *only* erase the pointer from `_activeRequestListeners` and delete it, without notifying `MegaApiImpl`.
   - If the delegate is freed while a queued request has not yet started (for example, when `MEGASdk` proactively cleans up because the Swift async `Task` was cancelled or the view disappeared), `MegaApiImpl::fireOnRequestStart` later dereferences a dangling pointer.
   - `MegaApiImpl::removeRequestListener` already nulls out listeners in all pending requests, but it was never called in this path.

4. **Most likely crash scenario**
   - Ads flow starts an async request and the hosting view is torn down (e.g. fast navigation or Task cancellation).
   - The Swift bridge frees the single-use listener before the Mega worker thread gets to `fireOnRequestStart`.
   - When the worker thread finally starts the request, it uses the stale listener pointer, triggering the observed `EXC_BAD_ACCESS`.

## Fix

**File:** `Modules/DataSource/MEGASDK/Sources/MEGASDK/bindings/ios/MEGASdk.mm`

```diff
@@ -3839,6 +3839,11 @@ - (void)freeRequestListener:(DelegateMEGARequestListener *)delegate {
     pthread_mutex_lock(&listenerMutex);
     _activeRequestListeners.erase(delegate);
     pthread_mutex_unlock(&listenerMutex);
+ 
+    if (self.megaApi) {
+        self.megaApi->removeRequestListener(delegate);
+    }
+
     delete delegate;
 }
```

### Rationale
- Ensures the native SDK is told to drop and null out the listener in any pending requests before deleting the bridge object.
- Prevents `fireOnRequestStart` from ever seeing the freed pointer; at worst, no callbacks are delivered, which is the safe fallback when the Swift side has already given up the listener.
- Change is idempotent: if the listener was never registered globally, `removeRequestListener` simply returns without effect.

## Verification
- Static analysis confirms every code path that frees a single-shot request delegate now notifies the Mega SDK first.
- The change is local to the Objective-C++ bridge and does not alter public APIs.
- Full end-to-end testing of the Mega SDK was out of scope in this environment; recommend running the existing Ads deep link UI flow to confirm no regressions.

## Follow-up Considerations
1. Audit other `free*Listener` helpers (transfer, global, scheduled copy) to ensure they mirror this safety pattern.
2. Add unit or integration coverage in the SDK bindings that mimics cancellation before request start to guard against regressions.
3. Consider capturing the request type when dispatching Ads-related requests for easier telemetry next time.

