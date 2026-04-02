# Camera Upload — Core Flows Reference

## 1. Discovery (ObjC core)

```
PHPhotoLibraryChangeObserver (CameraScanner)
  → didObserveNewAssets()
  → UploadRecordsCollator  (matches PHAssets → MOAssetUploadRecord in CoreData)
  → CameraUploadManager    (enqueues CameraUploadOperation)
```

Photo library permissions: never assume `.authorized`. `.limited` access still
works for scanning but the user should be nudged to grant full access.

---

## 2. Upload Execution

```
CameraUploadOperation (ObjC)
  → creates URLSessionTask with encoded task description ("localId|chunkIndex|totalChunks")
  → CameraUploadTransferProgressOCRepository.registerTask()   [ObjC bridge → Swift actor]
  → URLSession background upload (chunked, 4 named sessions — see §5)
  → URLSession delegate callbacks → updateTaskProgress() per chunk
  → completeTask() on finish
  → CameraUploadTransferProgressRepository (actor) emits phase/progress events
```

Concurrency: photos 7 concurrent (drops to 1 on memory warning), videos always 1.

---

## 3. Progress → UI

```
CameraUploadProgressUseCase
  .cameraUploadPhaseEventUpdates (AsyncSequence of CameraUploadPhaseEventEntity)
  → CameraUploadProgressTableViewModel.monitorActiveUploads()
  → section updates: inProgressItemAdded / inQueueUpdated
  → CameraUploadInProgressRowViewModel reads uploadProgressUpdates(for:)
  → SwiftUI progress row (percentage, bytesPerSecond)
```

**Phase event sequence per asset:**
1. `.registered` — task registered, asset tracked
2. `.uploading` — first bytes sent (triggers row appearing in In Progress section)
3. `.completed` — upload done (success or failure)

Speed: 5-second rolling window of consecutive sample pairs. Fewer than 2 samples → speed = 0.

---

## 4. State Monitoring → Banner

```
CameraUploadsStatsRepository  (MEGAData)
  converts NSNotificationCenter ObjC posts → Swift async sequences
  (MEGACameraUploadStatsChanged, MEGACameraUploadPhotoConcurrentCountChanged, etc.)
  ↓
MonitorCameraUploadUseCase.cameraUploadState
  combines: upload stats + paused reason (network/battery/thermal)
  ↓
MonitorCameraUploadStatusProvider
  ↓
CameraUploadBannerStatusViewStates:
  uploadInProgress | uploadPaused | uploadCompleted | uploadPartialCompleted
```

---

## 5. Background Session Recovery (app restart)

### Named background sessions

```
nz.mega.photoTransfer.cellularAllowed
nz.mega.photoTransfer.cellularDisallowed
nz.mega.videoTransfer.cellularAllowed
nz.mega.videoTransfer.cellularDisallowed
```

iOS network daemon holds these sessions across app kills; actual byte transfers
may continue even when the app process is dead.

### Recovery flow (gated by `iosCameraUploadBreakdown` flag)

```
TransferSessionManager.restoreAllSessionsWithCompletion()
  → reconnects to each named session via .background(withIdentifier:)
  → getTasksWithCompletionHandler: on each session

UploadRecordsCollator.collateAllUploadingRecordsByUploadTasks()
  — CoreData records with no surviving OS task → reverted to notStarted, staged files deleted
  — CoreData records with surviving OS task → remain Uploading

restoreProgressReporting(for:uploadTasks:)  [TransferSessionManager+Additions.swift]
  — reads task.countOfBytesSent + task.countOfBytesExpectedToSend per chunk
  — parses taskDescription → localId + chunkIndex
  → CameraUploadTransferProgressOCRepository.restoreTasks()
  → re-populates taskMap + sentByFile + expectedByChunk in the Swift actor
```

### What survives vs. what is lost

| Data | Survives kill? | Notes |
|---|---|---|
| URLSessionTask network transfers | Yes (if iOS kept them) | Daemon holds them |
| `task.countOfBytesSent` per chunk | Mostly yes | OS maintains this |
| `sentByChunk` per-chunk deltas in actor | **No** | In-memory only |
| `sentByFile` accumulated total | Partially | Rebuilt from OS values — may be lower than last seen |
| Speed samples | **No** | Always 0 immediately after relaunch |
| AsyncStream continuations | **No** | Must re-subscribe |

### 0% after kill — expected vs. bug

| Scenario | Verdict |
|---|---|
| 0% briefly on relaunch, then updates | Expected — race between UI appearing and session restore completing |
| 0% permanently, `iosCameraUploadBreakdown` flag off | Expected by design — progress pipeline not active |
| 0% permanently, flag on | Bug — likely unparseable (old-format) task description |
| File re-uploads from 0 | Expected — task had no surviving OS task; CoreData record correctly reset |

---

## 6. App Relaunch Entry Points

**Normal relaunch:** `CameraUploadManager.setupCameraUploadWhenApplicationLaunches` → `restoreAllSessions...`

**System-triggered (background transfer completed):** `AppDelegate.application(_:handleEventsForBackgroundURLSession:completionHandler:)` → saves completion handler → triggers same restore path.
