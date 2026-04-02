# Camera Upload — Architecture Reference

## Module & File Map

| Layer | Path | Contents |
|---|---|---|
| **Entities** | `Modules/Domain/MEGADomain/Sources/MEGADomain/Entity/CameraUpload/` | 17 value-type entities |
| **Repo Protocols** | `Modules/Domain/MEGADomain/Sources/MEGADomain/RepositoryProtocol/CameraUploads/` | 3 protocols |
| **Node Protocol** | `Modules/Domain/MEGADomain/Sources/MEGADomain/RepositoryProtocol/Node/CameraUploadsRepositoryProtocol.swift` | SDK backup node |
| **Use Cases** | `Modules/Domain/MEGADomain/Sources/MEGADomain/UseCase/CameraUploads/` | 5 use cases |
| **Node Use Case** | `Modules/Domain/MEGADomain/Sources/MEGADomain/UseCase/Node/CameraUploadsUseCase.swift` | Folder & backup |
| **Repositories** | `Modules/Repository/MEGARepo/Sources/MEGARepo/Repository/CameraUpload/` | Swift repos |
| **Legacy Repos** | `MEGAData/Repository/CameraUploads/` + `MEGAData/Repository/Node/CameraUploadsRepository.swift` | ObjC-bridged repos |
| **ObjC Bridge** | `iMEGA/Camera uploads/TransferSession/CameraUploadTransferProgressOCRepository.swift` | Progress tracking bridge |
| **Upload Ops** | `iMEGA/Camera uploads/UploadOperations/` | ObjC upload operations |
| **Upload Manager** | `iMEGA/Camera uploads/UploadManagers/` | ObjC queue orchestration |
| **Progress UI** | `iMEGA/Camera uploads/Progress/` | Progress VM + views |
| **Banner / Status UI** | `iMEGA/Camera uploads/Banner/` + `Timeline/` + `Status/` | Status banner |
| **Settings UI** | `iMEGA/My Account/Settings/Camera Uploads/` | Settings VC + options |
| **CoreData** | `iMEGA/Utils/CoreData/ManagedObjects/CameraUploads/` | `MOAssetUploadRecord` |
| **BG Refresh** | `iMEGA/Camera uploads/UploadUtils/CameraUploadBGRefreshManager.swift` | BGAppRefreshTask |

---

## Key Types

### Entities (all structs/enums in `MEGADomain`)

| Type | Purpose |
|---|---|
| `CameraAssetUploadEntity` | One queued asset: localIdentifier, mediaType, status |
| `CameraAssetUploadStatusEntity` | Status enum: `unknown → notStarted → notReady → queuedUp → processing → uploading → done / cancelled / failed` |
| `CameraUploadProgressEntity` | Snapshot: percentComplete, totalBytes, bytesPerSecond |
| `CameraUploadStateEntity` | Combined state + `PausedReason` (network/battery/thermal) |
| `CameraUploadStatsEntity` | Overall progress float, pendingFilesCount, pendingVideosCount |
| `CameraUploadPhaseEventEntity` | assetIdentifier + phase (registered / uploading / completed) |
| `CameraUploadTaskDescriptionEntity` | Encodes `localId\|chunkIndex\|totalChunks` into URLSession task description |
| `QueuedCameraUploadPositionEntity` | Cursor-based pagination marker for queue UI |

### Repository Protocols (`MEGADomain`)

| Protocol | Key surface |
|---|---|
| `CameraUploadAssetRepositoryProtocol` | Paginated fetch of queued assets; file details |
| `CameraUploadTransferProgressRepositoryProtocol` | `activeUploads`, `cameraUploadPhaseEventUpdates` (AsyncSequence), register/update/complete tasks |
| `CameraUploadsStatsRepositoryProtocol` | `currentUploadStats()`, `monitorChangedUploadStats()`, paused reason async sequences |
| `CameraUploadsRepositoryProtocol` | SDK backup node CRUD |

### Use Cases (`MEGADomain`)

| Use Case | Does |
|---|---|
| `MonitorCameraUploadUseCase` | Combines stats + paused reason → `CameraUploadStateEntity` stream |
| `CameraUploadProgressUseCase` | Phase events, per-file progress with 5-second rolling speed window |
| `QueuedCameraUploadsUseCase` | Paginated queue fetch, filters by status & media type |
| `CameraUploadFileDetailsUseCase` | File names (date-prefixed), HEIC→JPG, live photo `.live.mp4` |
| `CameraUploadBackupReminderUseCase` | Schedules 28-day setup reminder notification |
| `CameraUploadsUseCase` | SDK node fetch, backup registration & state sync |

### Concrete Repositories

| Class | Notes |
|---|---|
| `CameraUploadTransferProgressRepository` | **`actor`**, singleton `.shared`; thread-safe chunk tracking via `taskMap` + speed samples |
| `CameraUploadAssetRepository` | Wraps `CameraUploadRecordStore` (CoreData data source) |
| `CameraUploadsRepository` (MEGAData) | ObjC bridge; wraps `MEGASdk` + `CameraUploadNodeAccess` |
| `CameraUploadsStatsRepository` (MEGAData) | Converts `NSNotificationCenter` ObjC notifications → async sequences |

---

## Layer Rules — Where to Make Changes

**Adding a new upload option/setting**
1. Add `PreferenceKeyEntity` case in `MEGADomain` (raw string must match ObjC `NSUserDefaults` key exactly)
2. Read it in the relevant use case via `@PreferenceWrapper` injected in `init`
3. Expose toggle in Settings UI (`iMEGA/My Account/Settings/Camera Uploads/`)
4. Never read `NSUserDefaults` directly in a repository or data source

**Adding a new entity field**
- Edit the struct in `Modules/Domain/MEGADomain/…/Entity/CameraUpload/`
- Update the mapper (`MOAssetUploadRecord+Mapper.swift` or equivalent) in the repository layer
- `MOAssetUploadRecord`, `AssetUploadInfo`, and SDK types must never escape the repository

**Modifying upload progress tracking**
- All state lives in `CameraUploadTransferProgressRepository` (actor)
- ObjC operations call through `CameraUploadTransferProgressOCRepository` (the bridge)
- Never add thread-unsafe state; the actor boundary is the thread-safety guarantee

**Adding a new use case**
- Place in `Modules/Domain/MEGADomain/Sources/MEGADomain/UseCase/CameraUploads/`
- Only depend on `RepositoryProtocol` types — no `MEGASdk`, no UIKit, no CoreData
- Expose `async throws` API; use `private` for closure bridges only
- Never mark `@MainActor` — that belongs in Presentation layer

**Adding async sequences**
- New sequences belong in `CameraUploadsStatsRepository` (ObjC notification bridge)
  or `CameraUploadTransferProgressRepository` (actor-based)
- Never expose raw `AsyncStream` in a public API — wrap in `AnyAsyncSequence`

**Progress tracking — two separate concepts**
- *Overall completion progress* (`CameraUploadStatsEntity.progress: Float`) — ratio of
  `finishedFilesCount / totalFilesCount`, computed from CoreData by `CameraUploadRecordManager`.
  Shown as the text label in `CameraUploadProgressViewModel.uploadStatus`.
- *Per-file byte progress* (`CameraUploadProgressEntity.percentage: Double`) — driven
  by `URLSession` delegate callbacks through `CameraUploadTransferProgressRepository`.
  Stays at 0.0 until `updateTaskProgress` is called with `totalBytesSent > 0`.
  This entire system is gated by the `iosCameraUploadBreakdown` feature flag.
