# Camera Upload — Settings & Configuration Reference

## Preference Keys

All preferences use `@PreferenceWrapper` with `PreferenceKeyEntity` in use cases.
Never read `NSUserDefaults` directly in Swift domain or presentation code.

| Key | ObjC constant | Default | Meaning |
|---|---|---|---|
| `isCameraUploadsEnabled` | `kIsCameraUploadsEnabled` | `false` | Master on/off |
| `isVideoUploadEnabled` | `kIsVideoUploadsEnabled` | `false` | Include videos |
| `cameraUploadsCellularDataUsageAllowed` | `kCameraUploadsCellularDataUsageAllowed` | `false` | Use cellular for photos |
| `isVideoCellularUploadAllowed` | `IsCellularForVideosAllowedKey` = `"IsUseCellularConnectionForVideosEnabled"` | `false` | Use cellular for videos — **ObjC UI/session infrastructure already fully exists** in `CameraUploadManager+Settings.m`, `CameraUploadsTableViewController`, and `TransferSessionManager`; only the Swift `PreferenceKeyEntity` case is missing |
| `shouldConvertHEICPhoto` | — | — | Convert HEIC → JPG on upload |
| `isUploadVideosForLivePhotosEnabled` | — | — | Upload live photo video track |
| `isUploadForBurstPhotosEnabled` | — | — | Upload burst shots |
| `isUploadHiddenAlbumEnabled` | — | — | Upload hidden album |

**Important**: When adding a new Swift preference key that bridges to an existing ObjC key, the
`PreferenceKeyEntity` raw value must exactly match the ObjC `NSUserDefaults` key string.

---

## Feature Flags

| Flag | Key | Effect |
|---|---|---|
| `RemoteFeatureFlagEntity.iosCameraUploadBreakdown` | `"icub"` | **Gates the entire per-file progress tracking pipeline.** When off, `makeCameraUploadTransferProgressRepository()` returns `nil`, `CameraUploadTransferProgressOCRepository` is never wired, and all byte-level progress is a no-op. **Check this first when debugging stuck progress.** |
| `FeatureFlagKey.cameraUploadsRevamp` | — | Toggles new vs. legacy status logic in `MonitorCameraUploadStatusProvider`. Enables the async-sequence-based banner monitoring path. |

Flag guard locations for `iosCameraUploadBreakdown`:
- `iMEGA/Camera uploads/UploadUtils/UploadOperationFactory+Additions.swift` — creation path
- `iMEGA/Camera uploads/TransferSession/TransferSessionManager+Additions.swift` — restore path

---

## Upload Concurrency

| Queue | Concurrency | Notes |
|---|---|---|
| Photos | 7 concurrent | Drops to 1 on memory warning |
| Videos | 1 | Always sequential (heavy processing) |
| Background refresh | Every 3 hours | BGAppRefreshTask ID: `mega.iOS.cameraUpload.backgroundFetch` |

Concurrency management: `CameraUploadConcurrentCountCalculator` adapts counts to
battery state and memory pressure.

---

## File Naming

Format: `"YYYY-MM-DD HH.mm.ss"` prefix + media-specific extension.

Supported extensions: `JPG`, `HEIC`, `HEIF`, `PNG`, `DNG`, `GIF`, `WebP`,
`MP4`, `.live.mp4` (live photo video track).

HEIC→JPG conversion controlled by `shouldConvertHEICPhoto` preference.
