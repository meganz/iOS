# Camera Upload — Gotchas, Complexity & Debugging Reference

## Debugging Checklist: Stuck or Missing Progress

Work through in order:

1. **Check `iosCameraUploadBreakdown` flag first** (`"icub"`). If off, `makeCameraUploadTransferProgressRepository()` returns `nil` and the entire per-file progress system is a no-op. Verify in `UploadOperationFactory+Additions.swift`.

2. **Search `MEGALogDebug` for `[Camera Upload] register upload task`**. Missing logs = ObjC bridge not wired (nil repository or flag off).

3. **Check task description format**. Log `task.taskDescription` for an in-progress `NSURLSessionTask`. Must be `"localId|chunkIndex|totalChunks"` — a plain `localIdentifier` fails `parseTaskInfo()` silently, dropping all progress updates.

4. **Verify URLSession delegate callbacks firing**. Breakpoint `TransferSessionTaskDelegate.URLSession:task:didSendBodyData:`. If never hit, the upload transfer hasn't started — investigate the operation queue (check `isPhotoUploadQueueSuspended`/`isVideoUploadQueueSuspended` in `CameraUploadManager`).

5. **Confirm `monitorActiveUploads()` is actively awaiting**. The `.uploading` phase event is only emitted when first bytes are sent. If the progress view opened after uploads started, there is a timing gap.

6. **After a kill/relaunch**, confirm `restoreProgressReporting(for:)` in `TransferSessionManager+Additions.swift` ran and the flag guard was satisfied.

---

## Known Complexity Areas

### Task Description Encoding (Silent Failure)

`CameraUploadTaskDescriptionEntity` encodes `localId|chunkIndex|totalChunks` as a
string in `URLSessionTask.taskDescription`. If `parseTaskInfo()` returns `nil`
(missing separators, non-integer chunk values), every call to `registerTask`,
`updateProgress`, and `completeTask` in `CameraUploadTransferProgressOCRepository`
silently does nothing. No error is thrown.

### Chunked Upload Math & Speed Spikes

- Speed uses a 5-second rolling window of consecutive sample pairs
- Fewer than 2 samples → speed = 0 (normal on startup and after recovery)
- Speed always 0 immediately after session restore until first real delegate callback
- Spikes at chunk boundaries are expected

### Photo Library Limited Access

Never gate upload start on `.authorized` only. `.limited` access still allows
scanning; the user should be nudged to grant full access, not blocked.
Monitor permission changes via `PHPhotoLibraryChangeObserver`.

### `@objc` + `@MainActor` (Critical)

ObjC callbacks lose Swift actor isolation. Never rely on `@MainActor func` when
called from ObjC — the isolation annotation is ignored. Always wrap:

```swift
// ❌ WRONG — actor isolation lost when called from ObjC
@MainActor
@objc func someFunction() { /* main thread assumed but not guaranteed */ }

// ✅ CORRECT
@objc func someFunction() {
    Task { @MainActor in
        // main thread logic
    }
}
```

### Pagination at Scale

`CameraUploadPaginationManager` uses 30-item pages with 4-page look-ahead/behind.
The queue can have thousands of records — never load the full list. Always use
`QueuedCameraUploadsUseCase` with cursor pagination.

### `cameraUploadsRevamp` Flag

If banner state seems wrong or the new monitoring logic is not running, check
whether `FeatureFlagKey.cameraUploadsRevamp` is enabled. Old and new monitoring
paths coexist behind this flag.

---

## ObjC / Swift Bridge Rules

The upload core (`CameraUploadManager`, `CameraUploadOperation`,
`CameraUploadRecordManager`) is Objective-C. The Swift async world connects via:

| Bridge component | Role |
|---|---|
| `CameraUploadTransferProgressOCRepository` | ObjC-callable wrapper around the Swift actor; translates callbacks into async sequence emissions |
| `CameraUploadsStatsRepository` (MEGAData) | Converts `NSNotificationCenter` ObjC posts → Swift `AsyncStream` values |
| `MOAssetUploadRecord+Mapper.swift` | Maps CoreData entity → domain entity |

**Rule**: Keep ObjC types (`MOAssetUploadRecord`, `AssetUploadInfo`, any `MEGASdk`
type) **inside** the repository. Nothing above repository level should see them.

### Preference Bridge Rule

When adding a Swift `PreferenceKeyEntity` case that maps to an existing ObjC
`NSUserDefaults` key, the raw value string must exactly match the ObjC constant.
Example: `case isVideoCellularUploadAllowed = "IsUseCellularConnectionForVideosEnabled"`
must match `IsCellularForVideosAllowedKey` in `CameraUploadManager+Settings.m`.

---

## In-Progress Migrations

| Area | Legacy | New |
|---|---|---|
| Stats reporting | `CameraUploadManager.loadCurrentUploadStats()` (ObjC) | `CameraUploadTransferProgressRepository` actor tracking |
| Notification monitoring | Direct `NSNotificationCenter` listeners | Async sequence abstractions in `CameraUploadsStatsRepository` |
| Banner state | Inline logic | `MonitorCameraUploadStatusProvider` behind `cameraUploadsRevamp` flag |

Both old and new paths coexist. Feature flags control which path is active.
When debugging, always determine which path is live for a given build/environment.
